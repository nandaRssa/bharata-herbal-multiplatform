<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderTracking;
use App\Models\Setting;
use App\Services\ActivityLogger;
use App\Services\OrderEventNotificationService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class OrderController extends Controller
{

    public static array $statuses = [
        'pending'    => ['label' => 'Belum Dibayar', 'color' => 'yellow'],
        'paid'       => ['label' => 'Dibayar',       'color' => 'blue'],
        'processing' => ['label' => 'Diproses',      'color' => 'indigo'],
        'shipped'    => ['label' => 'Dikirim',        'color' => 'orange'],
        'completed'  => ['label' => 'Selesai',        'color' => 'green'],
        'cancelled'  => ['label' => 'Dibatalkan',     'color' => 'red'],
    ];

    public static array $tabLabels = [
        ''           => 'Semua',
        'pending'    => 'Belum Dibayar',
        'processing' => 'Diproses',
        'shipped'    => 'Dikirim',
        'completed'  => 'Selesai',
        'cancelled'  => 'Dibatalkan',
    ];

    public function index(Request $request)
    {
        $search = $request->input('search');
        $status = $request->input('status');

        $query = Order::with('user', 'items.product', 'payment')
            ->latest();

        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('id', 'like', "%{$search}%")
                    ->orWhere('tracking_number', 'like', "%{$search}%")
                    ->orWhereHas('user', fn($u) => $u->where('name', 'like', "%{$search}%"));
            });
        }

        if ($status) {
            $query->where('status', $status);
        }

        $statusCounts = Order::selectRaw('status, COUNT(*) as total')
            ->groupBy('status')
            ->pluck('total', 'status')
            ->toArray();

        $totalAll = array_sum($statusCounts);

        $orders = $query->paginate(10)->withQueryString();

        return view('admin.orders.index', compact(
            'orders',
            'statusCounts',
            'totalAll',
            'search',
            'status',
        ));
    }

    public function show(Order $order)
    {
        $order->load('user', 'items.product', 'payment', 'address', 'trackingUpdates');
        $statuses = self::$statuses;
        return view('admin.orders.show', compact('order', 'statuses'));
    }

    public function updateStatus(Request $request, Order $order)
    {
        $previousStatus = $order->status;

        $request->validate([
            'status'          => 'required|in:pending,paid,processing,shipped,completed,cancelled',
            'tracking_number' => 'nullable|required_if:status,shipped|string|max:100',
            'courier_name'    => 'nullable|required_if:status,shipped|string|max:100',
            'estimated_delivery_at' => 'nullable|date',
        ]);

        $order->update([
            'status'                => $request->status,
            'tracking_number'       => $request->tracking_number ?? $order->tracking_number,
            'courier_name'          => $request->filled('courier_name') ? $request->courier_name : $order->courier_name,
            'estimated_delivery_at' => $request->filled('estimated_delivery_at')
                ? $request->date('estimated_delivery_at')
                : $order->estimated_delivery_at,
        ]);

        if ($request->status === 'paid' && $order->payment) {
            $order->payment->update(['status' => 'verified', 'paid_at' => now()]);
        }

        if ($request->status === 'shipped') {
            if ($order->trackingUpdates()->doesntExist()) {
                $this->generateTrackingTimeline($order);
            }

            if (! $request->filled('estimated_delivery_at')) {
                $order->update([
                    'estimated_delivery_at' => $this->resolveEstimatedDelivery($order, $request->courier_name ?: $order->courier_name),
                ]);
            }
        }

        $order->load('user');

        if ($request->status === 'paid' && $previousStatus !== 'paid') {
            app(OrderEventNotificationService::class)->notify('payment_confirmed', $order);
        }

        if ($request->status === 'shipped' && $previousStatus !== 'shipped') {
            app(OrderEventNotificationService::class)->notify('order_shipped', $order);
        }

        if ($request->status === 'completed' && $previousStatus !== 'completed') {
            app(OrderEventNotificationService::class)->notify('order_completed', $order);
        }

        // Log activity
        ActivityLogger::logOrderStatusUpdate($order, $previousStatus, $request->status);

        return back()->with('success', 'Status pesanan berhasil diperbarui.');
    }

    public function export(Request $request)
    {
        $query = Order::with('user', 'items.product', 'payment')->latest();

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        if ($request->filled('search')) {
            $s = $request->search;
            $query->where(function ($q) use ($s) {
                $q->where('id', 'like', "%{$s}%")
                    ->orWhere('tracking_number', 'like', "%{$s}%")
                    ->orWhereHas('user', fn($u) => $u->where('name', 'like', "%{$s}%"));
            });
        }

        $orders   = $query->get();
        $filename = 'pesanan_' . now()->format('Ymd_His') . '.csv';
        $headers  = ['Content-Type' => 'text/csv; charset=UTF-8'];

        $callback = function () use ($orders) {
            $handle = fopen('php://output', 'w');

            fprintf($handle, chr(0xEF) . chr(0xBB) . chr(0xBF));

            fputcsv($handle, [
                'ID Pesanan',
                'Tanggal',
                'Nama Customer',
                'Produk',
                'Jumlah Item',
                'Total (Rp)',
                'Status',
                'Metode Bayar',
                'Nomor Resi',
            ]);

            foreach ($orders as $o) {
                $products  = $o->items->pluck('product.name')->implode(', ');
                $itemCount = $o->items->sum('quantity');

                fputcsv($handle, [
                    '#' . str_pad($o->id, 5, '0', STR_PAD_LEFT),
                    $o->created_at->format('d/m/Y H:i'),
                    $o->user->name ?? '-',
                    $products ?: '-',
                    $itemCount,
                    number_format($o->total_price, 0, ',', '.'),
                    $o->status_label,
                    $o->payment?->method_label ?? '-',
                    $o->tracking_number ?? '-',
                ]);
            }

            fclose($handle);
        };

        return response()->streamDownload($callback, $filename, $headers);
    }

    public function bulkUpdateStatus(Request $request)
    {
        $request->validate([
            'order_ids' => 'required|array|min:1',
            'order_ids.*' => 'exists:orders,id',
            'status' => 'required|in:pending,paid,processing,shipped,completed,cancelled',
        ]);

        $orderIds = $request->order_ids;
        $newStatus = $request->status;

        $orders = Order::whereIn('id', $orderIds)->get();

        foreach ($orders as $order) {
            $previousStatus = $order->status;

            $order->update(['status' => $newStatus]);

            if ($newStatus === 'paid' && $order->payment && $previousStatus !== 'paid') {
                $order->payment->update(['status' => 'verified', 'paid_at' => now()]);
                app(OrderEventNotificationService::class)->notify('payment_confirmed', $order);
            }

            if ($newStatus === 'shipped' && $previousStatus !== 'shipped') {
                if ($order->trackingUpdates()->doesntExist()) {
                    $this->generateTrackingTimeline($order);
                }
                app(OrderEventNotificationService::class)->notify('order_shipped', $order);
            }

            if ($newStatus === 'completed' && $previousStatus !== 'completed') {
                app(OrderEventNotificationService::class)->notify('order_completed', $order);
            }

            // Log activity
            ActivityLogger::logOrderStatusUpdate($order, $previousStatus, $newStatus);
        }

        $count = count($orders);
        return back()->with('success', "Status {$count} pesanan berhasil diperbarui ke '{$this->getStatusLabel($newStatus)}'.");
    }

    private function getStatusLabel($status)
    {
        return match($status) {
            'pending' => 'Belum Dibayar',
            'paid' => 'Dibayar',
            'processing' => 'Diproses',
            'shipped' => 'Dikirim',
            'completed' => 'Selesai',
            'cancelled' => 'Dibatalkan',
            default => $status,
        };
    }

    private function generateTrackingTimeline(Order $order): void
    {
        $sellerCity = $this->resolveSellerCity();
        $buyerCity = $order->address?->city ?: 'Kota Pembeli';
        $transitCity = $this->resolveTransitCity($sellerCity, $buyerCity);
        $baseTime = $order->created_at instanceof Carbon ? $order->created_at->copy() : Carbon::parse($order->created_at);

        $checkpoints = [
            ['minutes' => 0, 'keterangan' => 'Paket di-pickup kurir', 'lokasi' => $sellerCity],
            ['minutes' => 120, 'keterangan' => 'Tiba di gudang asal', 'lokasi' => $sellerCity],
            ['minutes' => 480, 'keterangan' => 'Dalam perjalanan ke kota tujuan', 'lokasi' => $transitCity],
            ['minutes' => 1200, 'keterangan' => 'Paket tiba di gudang tujuan', 'lokasi' => $buyerCity],
        ];

        foreach ($checkpoints as $checkpoint) {
            $order->trackingUpdates()->create([
                'keterangan' => $checkpoint['keterangan'],
                'lokasi' => $checkpoint['lokasi'],
                'created_at' => $baseTime->copy()->addMinutes($checkpoint['minutes']),
            ]);
        }
    }

    private function resolveSellerCity(): string
    {
        $storeAddress = trim((string) Setting::get('store', 'store_address', ''));

        if ($storeAddress === '') {
            return 'Kota Penjual';
        }

        $parts = array_values(array_filter(array_map('trim', explode(',', $storeAddress))));

        return count($parts) >= 2 ? $parts[count($parts) - 2] : $parts[0];
    }

    private function resolveTransitCity(string $sellerCity, string $buyerCity): string
    {
        if (strcasecmp($sellerCity, $buyerCity) === 0) {
            return 'Hub Transit ' . $buyerCity;
        }

        return 'Transit ' . $buyerCity;
    }

    private function resolveEstimatedDelivery(Order $order, ?string $courierName): Carbon
    {
        $fallbackDays = max((int) Setting::get('shipping', 'fallback_estimated_days', 3), 1);
        $code = match (strtolower((string) $courierName)) {
            'jne' => 'jne',
            'j&t express', 'jnt', 'j&t' => 'jnt',
            'sicepat' => 'sicepat',
            default => null,
        };
        return now()->addDays($fallbackDays);
    }

    /**
     * API untuk polling pesanan baru
     * GET /admin/api/new-orders-count
     */
    public function checkNewOrders(Request $request)
    {
        $lastCheck = $request->query('last_check', now()->subMinutes(30)->timestamp);
        $lastCheckTime = \Carbon\Carbon::createFromTimestamp($lastCheck);

        // Count pesanan baru sejak last check
        $newOrdersCount = Order::where('created_at', '>', $lastCheckTime)
                              ->where('status', 'pending')
                              ->count();

        // Ambil data pesanan baru untuk ditampilkan di toast
        $newOrders = Order::where('created_at', '>', $lastCheckTime)
                         ->where('status', 'pending')
                         ->latest()
                         ->limit(3)
                         ->get(['id', 'user_id', 'total', 'created_at'])
                         ->load('user:id,name');

        // Simpan last check ke session
        session(['admin_last_check_orders' => now()->timestamp]);

        return response()->json([
            'success' => true,
            'count' => $newOrdersCount,
            'orders' => $newOrders,
            'message' => $newOrdersCount > 0 
                ? "🛒 Ada {$newOrdersCount} pesanan baru!" 
                : null,
        ]);
    }
}

