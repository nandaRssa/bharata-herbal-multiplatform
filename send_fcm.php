<?php
define('LARAVEL_START', microtime(true));
require __DIR__.'/vendor/autoload.php';
$app = require_once __DIR__.'/bootstrap/app.php';
$kernel = $app->make(Illuminate\Contracts\Console\Kernel::class);
$kernel->bootstrap();

$token = 'e1KbaHpMRCuCyaXTG5qGrD:APA91bFHDKNL3DvMz8ELu4eXhLKnueZqtJaKj4nw1HeRPhOv9w-Ej0POMNjMaIAFXbcroSjw2geDlRfdDvElLRJOEvdo7Sx7l0MVwuGAZ51FnWgF3UfQ-Rs';
$serverKey = 'W1KIqjmI2UNK9vdHABNqxxRwGrSkfq_WzpNnnnd9qOM';

$response = Illuminate\Support\Facades\Http::withHeaders([
    'Authorization' => 'key=' . $serverKey,
    'Content-Type' => 'application/json',
])->post('https://fcm.googleapis.com/fcm/send', [
    'to' => $token,
    'notification' => [
        'title' => 'Test Notifikasi',
        'body' => 'Pesanan sedang diproses!',
    ],
]);

echo "Status: " . $response->status() . "\n";
echo "Response: " . $response->body() . "\n";