<?php
require_once __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
$order = App\Models\Order::latest()->first();
$customer = $order->user;
echo "Customer: " . ($customer ? $customer->name : "NULL") . "\n";
echo "FCM Token: " . ($customer ? ($customer->fcm_token ?? "NULL") : "NULL") . "\n";

if ($customer && $customer->fcm_token) {
    $token = $customer->fcm_token;
    $serverKey = 'W1KIqjmI2UNK9vdHABNqxxRwGrSkfq_WzpNnnnd9qOM';
    
    $response = Illuminate\Support\Facades\Http::withHeaders([
        'Authorization' => 'key=' . $serverKey,
        'Content-Type' => 'application/json',
    ])->post('https://fcm.googleapis.com/fcm/send', [
        'to' => $token,
        'notification' => [
            'title' => 'Test Update Status',
            'body' => 'Pesanan #' . str_pad((string)$order->id, 5, '0', STR_PAD_LEFT) . ' sedang diproses!',
        ],
        'data' => ['order_id' => (string)$order->id],
    ]);
    
    echo "FCM Response: " . $response->body() . "\n";
} else {
    echo "No FCM token for customer\n";
}