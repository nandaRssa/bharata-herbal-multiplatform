<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\OrderResource;
use App\Http\Traits\ApiResponseTrait;
use App\Models\BankAccount;
use App\Models\Order;
use App\Models\Setting;
use App\Services\OrderEventNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    use ApiResponseTrait;

    public function index(Request $request)
    {
        $query = auth()->user()->orders()->with('items.product', 'address', 'payment');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $orders = $query->orderByDesc('created_at')->paginate($request->get('per_page', 10));

        return $this->success([
            'data' => OrderResource::collection($orders),
            'pagination' => [
                'current_page' => $orders->currentPage(),
                'last_page' => $orders->lastPage(),
                'per_page' => $orders->perPage(),
                'total' => $orders->total(),
                'from' => $orders->firstItem(),
                'to' => $orders->lastItem(),
            ],
        ]);
    }

    public function show(Order $order)
    {
        if ($order->user_id !== auth()->id()) {
            return $this->error('Unauthorized', 403);
        }

        $order->autoAdvanceStatus();

        $order->load('items.product', 'address', 'payment', 'reviews', 'trackingUpdates');

        return $this->success(new OrderResource($order));
    }

    public function cancel(Request $request, Order $order)
    {
        if ($order->user_id !== auth()->id()) {
            return $this->error('Unauthorized', 403);
        }

        if (!$order->canBeCancelled()) {
            return $this->error('Pesanan ini tidak dapat dibatalkan.', 400);
        }

        $request->validate([
            'cancel_reason' => 'nullable|string|max:255',
        ]);

        DB::transaction(function () use ($order, $request) {
            foreach ($order->items as $item) {
                if ($item->product) {
                    $item->product->increment('stock', $item->quantity);
                }
            }

            $order->update([
                'status' => 'cancelled',
                'cancel_reason' => $request->cancel_reason,
            ]);

            if ($order->payment) {
                $order->payment->update(['status' => 'failed']);
            }
        });

        app(OrderEventNotificationService::class)->notify('order_cancelled', $order->load('user'));

        return $this->success(new OrderResource($order->refresh()), 'Pesanan berhasil dibatalkan.');
    }

    public function payNow(Request $request, Order $order)
    {
        if ($order->user_id !== auth()->id()) {
            return $this->error('Unauthorized', 403);
        }

        if (! $order->canPayNow()) {
            return $this->error('Pesanan ini tidak perlu pembayaran.', 400);
        }

        $order->load('payment');
        if (!$order->payment) {
            return $this->error('Data pembayaran tidak ditemukan.', 404);
        }

        $method = $order->payment->method;
        $ewallet = in_array($method, ['dana', 'gopay', 'qris'], true) ? [
            'merchant'     => Setting::get('payment', "{$method}_merchant", ''),
            'qr_code'      => Setting::get('payment', "{$method}_qr", ''),
            'instructions' => Setting::get('payment', "{$method}_instructions", ''),
        ] : null;

        return $this->success([
            'payment' => [
                'id' => $order->payment->id,
                'method' => $method,
                'method_label' => $order->payment->method_label,
                'amount' => (int) $order->payment->amount,
                'status' => $order->payment->status,
                'bank_accounts' => $method === 'bank_transfer'
                    ? BankAccount::where('is_active', true)
                        ->get(['id', 'bank_name', 'account_number', 'account_holder'])
                        ->toArray()
                    : [],
                'ewallet' => $ewallet,
            ],
        ]);
    }

    public function buyAgain(Request $request, Order $order)
    {
        if ($order->user_id !== auth()->id()) {
            return $this->error('Unauthorized', 403);
        }

        $cart = auth()->user()->cart()->firstOrCreate(['user_id' => auth()->id()]);

        foreach ($order->items as $item) {
            $product = $item->product;

            if ($product->status === 'inactive' || $product->stock <= 0) {
                continue;
            }

            $existingItem = $cart->items()->where('product_id', $product->id)->first();

            if ($existingItem) {
                $newQty = $existingItem->quantity + $item->quantity;
                if ($newQty <= $product->stock) {
                    $existingItem->update(['quantity' => $newQty]);
                }
            } else {
                $cart->items()->create([
                    'product_id'  => $product->id,
                    'quantity'    => min($item->quantity, $product->stock),
                    'is_selected' => true,
                ]);
            }
        }

        $cart->load('items.product.categories');

        return $this->success([
            'cart' => new \App\Http\Resources\CartResource($cart),
            'message' => 'Produk dari pesanan berhasil ditambahkan ke keranjang.',
        ]);
    }

    /**
     * Customer confirms they received the order.
     * POST /api/orders/{order}/confirm-received
     */
    public function confirmReceived(Order $order)
    {
        if ($order->user_id !== auth()->id()) {
            return $this->error('Unauthorized', 403);
        }

        if ($order->status !== 'shipped') {
            return $this->error('Pesanan belum berstatus dikirim, tidak bisa dikonfirmasi.', 422);
        }

        if (!$order->canConfirmReceived()) {
            return $this->error('Pesanan masih dalam proses pengiriman. Silakan tunggu hingga paket sampai.', 422);
        }

        DB::transaction(function () use ($order) {
            $order->update(['status' => 'completed']);

            if ($order->payment && $order->payment->method === 'cod') {
                $order->payment->update([
                    'status' => 'verified',
                    'paid_at' => $order->payment->paid_at ?? now(),
                ]);
            }
        });

        app(OrderEventNotificationService::class)->notify('order_completed', $order->load('user'));

        return $this->success(null, 'Pesanan berhasil dikonfirmasi sebagai diterima! Terima kasih sudah berbelanja. 🎉');
    }

    /**
     * Customer uploads payment proof image.
     * POST /api/orders/{order}/upload-proof
     */
    public function uploadProof(Request $request, Order $order)
    {
        if ($order->user_id !== auth()->id()) {
            return $this->error('Unauthorized', 403);
        }

        if (! $order->canUploadPaymentProof()) {
            return $this->error('Bukti pembayaran tidak diperlukan untuk pesanan ini.', 422);
        }

        $request->validate([
            'proof_image' => 'required|image|mimes:jpg,jpeg,png,webp|max:5120',
        ]);

        $path = $request->file('proof_image')->store('payment_proofs', 'public');

        $payment = $order->payment;
        if (!$payment) {
            $payment = $order->payment()->create([
                'method' => 'bank_transfer',
                'status' => 'pending_confirmation',
                'amount' => $order->total_price,
            ]);
        }

        $payment->update([
            'proof_image' => $path,
            'status' => 'pending_confirmation',
        ]);

        // Notify admin about uploaded proof
        app(OrderEventNotificationService::class)->notify('payment_proof_uploaded', $order->load('user'));

        return $this->success([
            'proof_url' => asset('storage/' . $path),
        ], 'Bukti pembayaran berhasil diunggah. Admin akan mengkonfirmasi segera.');
    }
}
