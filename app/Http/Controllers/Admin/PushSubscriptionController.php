<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use App\Models\PushSubscription;
use Illuminate\Http\Request;

class PushSubscriptionController extends Controller
{
    public function subscribe(Request $request)
    {
        $request->validate([
            'endpoint' => 'required|string',
            'keys'     => 'required|array',
            'keys.p256dh' => 'required|string',
            'keys.auth'   => 'required|string',
        ]);

        PushSubscription::updateOrCreate(
            ['endpoint' => $request->endpoint],
            [
                'user_id' => auth()->id(),
                'p256dh'  => $request->keys['p256dh'],
                'auth'    => $request->keys['auth'],
            ]
        );

        return response()->json(['success' => true]);
    }

    public function unsubscribe(Request $request)
    {
        $request->validate(['endpoint' => 'required|string']);

        PushSubscription::where('endpoint', $request->endpoint)
            ->where('user_id', auth()->id())
            ->delete();

        return response()->json(['success' => true]);
    }

    public function test(Request $request)
    {
        $type = $request->input('type', 'order');

        if ($type === 'order') {
            $title = 'Pesanan Baru (Test)';
            $message = 'Test notifikasi: Ada pesanan baru dari pelanggan.';
            $notifType = 'info';
        } else {
            $title = 'Peringatan Stok (Test)';
            $message = 'Test notifikasi: Stok produk menipis, segera lakukan restock.';
            $notifType = 'warning';
        }

        Notification::create([
            'user_id' => auth()->id(),
            'title' => $title,
            'message' => $message,
            'type' => $notifType,
            'notifiable_type' => 'App\\Models\\User',
            'notifiable_id' => auth()->id(),
            'is_read' => false,
        ]);

        return response()->json(['success' => true, 'message' => 'Notifikasi test terkirim']);
    }
}
