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
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{

    public static array $statuses = [
        'pending'    => ['label' => 'Menunggu',      'color' => 'yellow'],
        'paid'       => ['label' => 'Sudah Bayar',   'color' => 'blue'],
        'processing' => ['label' => 'Diproses',      'color' => 'indigo'],
        'shipped'    => ['label' => 'Dikirim',       'color' => 'orange'],
        'completed'  => ['label' => 'Selesai',       'color' => 'green'],
        'cancelled'  => ['label' => 'Dibatalkan',    'color' => 'red'],
    ];

    public static array $tabLabels = [
        ''           => 'Semua',
        'pending'    => 'Menunggu',
        'paid'       => 'Sudah Bayar',
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
        $order->autoAdvanceStatus();
        $order->load('user', 'items.product', 'payment', 'address', 'trackingUpdates');
        $statuses = self::$statuses;
        $statusOptions = $this->buildStatusOptions($order);

        return view('admin.orders.show', compact('order', 'statuses', 'statusOptions'));
    }

    public function updateStatus(Request $request, Order $order)
    {
        $order->loadMissing('payment', 'trackingUpdates', 'user', 'address');
        $previousStatus = $order->status;

        $request->validate([
            'status'          => 'required|in:pending,paid,processing,shipped,completed,cancelled',
            'tracking_number' => 'nullable|required_if:status,shipped|string|max:100',
            'courier_name'    => 'nullable|required_if:status,shipped|string|max:100',
            'estimated_delivery_at' => 'nullable|date',
        ]);

        if (! $order->canTransitionTo($request->status)) {
            return back()->with('error', 'Perubahan status tidak valid untuk tahap pesanan saat ini.');
        }

        if ($request->status === 'paid' && $order->isCodOrder()) {
            return back()->with('error', 'Pesanan COD tidak perlu status Dibayar sebelum selesai.');
        }

        DB::transaction(function () use ($request, $order) {
            $order->update([
                'status'                => $request->status,
                'tracking_number'       => $request->filled('tracking_number') ? $request->tracking_number : $order->tracking_number,
                'courier_name'          => $request->filled('courier_name') ? $request->courier_name : $order->courier_name,
                'estimated_delivery_at' => $request->filled('estimated_delivery_at')
                    ? $request->date('estimated_delivery_at')
                    : $order->estimated_delivery_at,
            ]);

            $this->syncPaymentStatus($order, $request->status);

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
        });

        $order->refresh()->load('user', 'payment', 'trackingUpdates');
        $this->dispatchStatusNotification($order, $previousStatus, $request->status);

        ActivityLogger::logOrderStatusUpdate($order, $previousStatus, $request->status);

        return back()->with('success', 'Status pesanan berhasil diperbarui.');
    }

    /**
     * Admin confirms customer's uploaded payment proof → marks order as paid.
     */
    public function confirmPaymentProof(Request $request, Order $order)
    {
        $order->loadMissing('payment', 'user');

        if (!$order->payment?->proof_image) {
            return back()->with('error', 'Customer belum mengunggah bukti pembayaran.');
        }

        if (! $order->canTransitionTo('paid')) {
            return back()->with('error', 'Pesanan ini tidak berada pada tahap yang bisa dikonfirmasi pembayarannya.');
        }

        $previousStatus = $order->status;

        DB::transaction(function () use ($order) {
            $order->update(['status' => 'paid']);
            $this->syncPaymentStatus($order, 'paid');
        });

        if ($previousStatus !== 'paid') {
            app(OrderEventNotificationService::class)->notify('payment_confirmed', $order->load('user'));
        }

        ActivityLogger::logOrderStatusUpdate($order, $previousStatus, 'paid');

        return back()->with('success', 'Pembayaran berhasil dikonfirmasi. Status pesanan diubah ke Dibayar.');
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

        if (in_array($newStatus, ['paid', 'shipped', 'completed'], true)) {
            return back()->with('error', 'Status tersebut harus diperbarui per pesanan agar alurnya tetap valid.');
        }

        $orders = Order::with('payment', 'trackingUpdates', 'user')
            ->whereIn('id', $orderIds)
            ->get();

        $invalidOrders = $orders
            ->filter(fn (Order $order) => ! $order->canTransitionTo($newStatus))
            ->pluck('order_number')
            ->all();

        if ($invalidOrders !== []) {
            return back()->with('error', 'Ada pesanan yang tidak bisa dipindahkan ke status tersebut: ' . implode(', ', $invalidOrders));
        }

        foreach ($orders as $order) {
            $previousStatus = $order->status;

            DB::transaction(function () use ($order, $newStatus) {
                $order->update(['status' => $newStatus]);
                $this->syncPaymentStatus($order, $newStatus);
            });

            $this->dispatchStatusNotification($order->refresh()->load('user', 'payment'), $previousStatus, $newStatus);
            ActivityLogger::logOrderStatusUpdate($order, $previousStatus, $newStatus);
        }

        $count = count($orders);
        return back()->with('success', "Status {$count} pesanan berhasil diperbarui ke '{$this->getStatusLabel($newStatus)}'.");
    }

    private function getStatusLabel($status)
    {
        return match($status) {
            'pending' => 'Menunggu',
            'paid' => 'Sudah Bayar',
            'processing' => 'Diproses',
            'shipped' => 'Dikirim',
            'completed' => 'Selesai',
            'cancelled' => 'Dibatalkan',
            default => $status,
        };
    }

    private function buildStatusOptions(Order $order): array
    {
        $options = [$order->status];

        foreach ($order->allowedNextStatuses() as $status) {
            $options[] = $status;
        }

        return collect($options)
            ->unique()
            ->mapWithKeys(function (string $status) use ($order) {
                $label = $status === $order->status
                    ? $order->status_label
                    : $this->getStatusLabel($status);

                return [$status => $label];
            })
            ->all();
    }

    private function syncPaymentStatus(Order $order, string $newStatus): void
    {
        if (! $order->payment) {
            return;
        }

        if ($newStatus === 'cancelled') {
            $order->payment->update(['status' => 'failed']);
            return;
        }

        if ($order->payment->method === 'cod') {
            if ($newStatus === 'completed') {
                $order->payment->update([
                    'status' => 'verified',
                    'paid_at' => $order->payment->paid_at ?? now(),
                ]);
            }

            return;
        }

        if (in_array($newStatus, ['paid', 'processing', 'shipped', 'completed'], true)) {
            $order->payment->update([
                'status' => 'verified',
                'paid_at' => $order->payment->paid_at ?? now(),
            ]);
        }
    }

    private function dispatchStatusNotification(Order $order, string $previousStatus, string $newStatus): void
    {
        if ($newStatus === 'paid' && $previousStatus !== 'paid') {
            app(OrderEventNotificationService::class)->notify('payment_confirmed', $order);
        }

        if ($newStatus === 'processing' && $previousStatus !== 'processing') {
            app(OrderEventNotificationService::class)->notify('order_processing', $order);
        }

        if ($newStatus === 'shipped' && $previousStatus !== 'shipped') {
            app(OrderEventNotificationService::class)->notify('order_shipped', $order);
        }

        if ($newStatus === 'completed' && $previousStatus !== 'completed') {
            app(OrderEventNotificationService::class)->notify('order_completed', $order);
        }

        if ($newStatus === 'cancelled' && $previousStatus !== 'cancelled') {
            app(OrderEventNotificationService::class)->notify('order_cancelled', $order);
        }
    }

    private function generateTrackingTimeline(Order $order): void
    {
        $sellerCity = $this->resolveSellerCity();
        $buyerCity = $order->address?->city ?: 'Kota Pembeli';
        $transitCity = $this->resolveTransitCity($sellerCity, $buyerCity);
        $baseTime = $order->created_at instanceof Carbon ? $order->created_at->copy() : Carbon::parse($order->created_at);

        $checkpoints = [
            ['seconds' => 1, 'keterangan' => 'Pesanan diproses oleh penjual', 'lokasi' => $sellerCity],
            ['seconds' => 2, 'keterangan' => 'Pesanan sedang dikemas', 'lokasi' => $sellerCity],
            ['seconds' => 3, 'keterangan' => 'Pesanan diserahkan ke kurir', 'lokasi' => $sellerCity],
            ['seconds' => 4, 'keterangan' => 'Pesanan dalam perjalanan', 'lokasi' => $transitCity],
            ['seconds' => 5, 'keterangan' => 'Pesanan sampai di kota tujuan', 'lokasi' => $buyerCity],
            ['seconds' => 6, 'keterangan' => 'Pesanan sedang diantar ke alamat tujuan', 'lokasi' => $buyerCity],
            ['seconds' => 7, 'keterangan' => 'Pesanan telah diterima', 'lokasi' => $buyerCity],
        ];

        foreach ($checkpoints as $checkpoint) {
            $order->trackingUpdates()->create([
                'keterangan' => $checkpoint['keterangan'],
                'lokasi' => $checkpoint['lokasi'],
                'created_at' => now()->subSeconds(10 - $checkpoint['seconds']),
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
                         ->get(['id', 'user_id', 'total_price', 'created_at'])
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
