<?php

namespace App\Services;

use App\Models\Notification;
use App\Models\Order;
use App\Models\Product;
use App\Models\Review;
use App\Models\Setting;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class OrderEventNotificationService
{
    private const GROUP = 'notification';

    public function notify(string $event, Order $order): void
    {
        if (! Setting::get(self::GROUP, "event_{$event}", true)) {
            return;
        }

        [$title, $message, $type] = $this->resolveContent($event, $order);

        $admins = User::whereIn('role', ['admin', 'super_admin'])->get();

        foreach ($admins as $admin) {
            Notification::create([
                'user_id' => $admin->id,
                'title' => $title,
                'message' => $message,
                'type' => $type,
                'notifiable_type' => Order::class,
                'notifiable_id' => $order->id,
                'is_read' => false,
            ]);
        }

        $this->logExternalChannel('email_primary', $event, $order, $title);
        $this->logExternalChannel('email_backup', $event, $order, $title);
        $this->logExternalChannel('whatsapp_primary', $event, $order, $title);
        $this->logExternalChannel('whatsapp_backup', $event, $order, $title);

        $this->notifyCustomer($event, $order);
    }

    public function notifyStockLow(Product $product): void
    {
        if (! Setting::get(self::GROUP, 'event_stock_low', false)) {
            return;
        }

        $admins = User::whereIn('role', ['admin', 'super_admin'])->get();

        foreach ($admins as $admin) {
            Notification::create([
                'user_id' => $admin->id,
                'title' => 'Stok Produk Menipis',
                'message' => "Produk {$product->name} tinggal {$product->stock} unit.",
                'type' => 'warning',
                'notifiable_type' => Product::class,
                'notifiable_id' => $product->id,
                'is_read' => false,
            ]);
        }
    }

    public function notifyNewReview(Review $review): void
    {
        if (! Setting::get(self::GROUP, 'event_new_review', false)) {
            return;
        }

        $review->loadMissing(['product', 'user']);
        $productName = $review->product?->name ?? 'Produk';
        $customerName = $review->reviewer_name ?: ($review->user?->name ?? 'Customer');
        $admins = User::whereIn('role', ['admin', 'super_admin'])->get();

        foreach ($admins as $admin) {
            Notification::create([
                'user_id' => $admin->id,
                'title' => 'Review Baru dari Customer',
                'message' => "{$customerName} memberikan ulasan {$review->rating} bintang untuk {$productName}.",
                'type' => 'info',
                'notifiable_type' => Review::class,
                'notifiable_id' => $review->id,
                'is_read' => false,
            ]);
        }
    }

    private function notifyCustomer(string $event, Order $order): void
    {
        $customer = $order->user;
        if (! $customer || empty($customer->fcm_token)) {
            return;
        }

        [$title, $message, $type] = $this->resolveCustomerContent($event, $order);

        $this->sendFcmPush($customer->fcm_token, $title, $message, $order->id, $event);
    }

    private function resolveCustomerContent(string $event, Order $order): array
    {
        $orderNumber = '#' . str_pad((string) $order->id, 5, '0', STR_PAD_LEFT);

        return match ($event) {
            'order_created' => [
                'Pesanan Dibuat',
                "Pesanan {$orderNumber} berhasil dibuat. Silakan selesaikan pembayaran.",
                'info',
            ],
            'payment_proof_uploaded' => [
                'Bukti Pembayaran Diunggah',
                "Bukti pembayaran {$orderNumber} sedang menunggu konfirmasi admin.",
                'info',
            ],
            'payment_confirmed' => [
                'Pembayaran Terkonfirmasi',
                "Pembayaran {$orderNumber} telah dikonfirmasi! Pesanan akan segera diproses.",
                'success',
            ],
            'order_processing' => [
                'Pesanan Sedang Diproses',
                "Pesanan {$orderNumber} sedang diproses dan dikemas.",
                'info',
            ],
            'order_shipped' => [
                'Pesanan Dikirim',
                "Yey! Pesanan {$orderNumber} sedang dalam perjalanan ke alamatmu.",
                'info',
            ],
            'order_completed' => [
                'Pesanan Selesai',
                "Pesanan {$orderNumber} telah selesai. Jangan lupa berikan ulasan!",
                'success',
            ],
            'order_cancelled' => [
                'Pesanan Dibatalkan',
                "Pesanan {$orderNumber} telah dibatalkan. Dana akan dikembalikan.",
                'warning',
            ],
            default => [
                'Update Pesanan',
                "Ada pembaruan untuk pesanan {$orderNumber}.",
                'info',
            ],
        };
    }

    private function sendFcmPush(string $token, string $title, string $body, int $orderId, string $event = ''): void
    {
        $serverKey = trim((string) Setting::get(self::GROUP, 'fcm_server_key', ''));

        if ($serverKey === '') {
            return;
        }

        try {
            Http::withHeaders([
                'Authorization' => 'key=' . $serverKey,
                'Content-Type' => 'application/json',
            ])->post('https://fcm.googleapis.com/fcm/send', [
                'to' => $token,
                'notification' => [
                    'title' => '🌿 Bharata Herbal — ' . $title,
                    'body' => $body,
                    'sound' => 'default',
                ],
                'data' => [
                    'order_id' => (string) $orderId,
                    'order_number' => '#' . str_pad((string) $orderId, 5, '0', STR_PAD_LEFT),
                    'status' => $event ?: 'order_status',
                    'type' => 'order_status',
                ],
            ]);
        } catch (\Exception $e) {
            Log::error('FCM_PUSH_FAILED', [
                'order_id' => $orderId,
                'error' => $e->getMessage(),
            ]);
        }
    }

    private function resolveContent(string $event, Order $order): array
    {
        $orderNumber = '#' . str_pad((string) $order->id, 5, '0', STR_PAD_LEFT);
        $customerName = $order->user?->name ?? 'Pelanggan';

        return match ($event) {
            'order_created' => [
                'Pesanan Baru Masuk',
                "{$orderNumber} dibuat oleh {$customerName} dengan total Rp " . number_format((float) $order->total_price, 0, ',', '.'),
                'info',
            ],
            'payment_proof_uploaded' => [
                'Bukti Pembayaran Diunggah',
                "{$customerName} mengunggah bukti pembayaran untuk pesanan {$orderNumber}. Silakan verifikasi.",
                'warning',
            ],
            'payment_confirmed' => [
                'Pembayaran Terkonfirmasi',
                "Pembayaran {$orderNumber} telah dikonfirmasi dan siap diproses.",
                'success',
            ],
            'order_processing' => [
                'Pesanan Diproses',
                "Pesanan {$orderNumber} sedang diproses dan dikemas.",
                'info',
            ],
            'order_shipped' => [
                'Pesanan Dikirim',
                "{$orderNumber} telah dikirim melalui " . ($order->courier_label ?? 'kurir') . '.',
                'info',
            ],
            'order_completed' => [
                'Pesanan Selesai',
                "{$orderNumber} untuk {$customerName} telah selesai.",
                'success',
            ],
            'order_cancelled' => [
                'Pesanan Dibatalkan',
                "{$orderNumber} untuk {$customerName} telah dibatalkan." .
                    ($order->cancel_reason ? " Alasan: {$order->cancel_reason}" : ''),
                'warning',
            ],
            'stock_low' => [
                'Stok Produk Menipis',
                "Perhatian: ada produk yang stoknya menipis. Segera restok.",
                'warning',
            ],
            'new_review' => [
                'Review Baru dari Customer',
                "{$customerName} memberikan ulasan untuk pesanan {$orderNumber}.",
                'info',
            ],
            default => [
                'Update Pesanan',
                "Ada pembaruan untuk pesanan {$orderNumber}.",
                'info',
            ],
        };
    }

    private function logExternalChannel(string $key, string $event, Order $order, string $title): void
    {
        $destination = trim((string) Setting::get(self::GROUP, $key, ''));

        if ($destination === '') {
            return;
        }

        Log::info('ORDER_EVENT_NOTIFICATION', [
            'event' => $event,
            'destination_key' => $key,
            'destination' => $destination,
            'order_id' => $order->id,
            'title' => $title,
        ]);
    }
}
