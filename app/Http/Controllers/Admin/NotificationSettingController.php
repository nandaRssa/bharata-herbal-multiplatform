<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Mail;

class NotificationSettingController extends Controller
{
    private const GROUP = 'notification';

    private const EVENTS = [
        'order_created',
        'payment_proof_uploaded',
        'payment_confirmed',
        'order_processing',
        'order_shipped',
        'order_completed',
        'order_cancelled',
        'stock_low',
        'new_review',
    ];

    private const EVENT_LABELS = [
        'order_created'           => 'Pesanan Baru',
        'payment_proof_uploaded'  => 'Bukti Pembayaran Diunggah',
        'payment_confirmed'       => 'Pembayaran Dikonfirmasi',
        'order_processing'        => 'Pesanan Diproses',
        'order_shipped'           => 'Pesanan Dikirim',
        'order_completed'         => 'Pesanan Selesai',
        'order_cancelled'         => 'Pesanan Dibatalkan',
        'stock_low'               => 'Stok Produk Menipis',
        'new_review'              => 'Review Baru dari Customer',
    ];

    public function index()
    {
        $settings    = Setting::getGroup(self::GROUP);
        $events      = self::EVENTS;
        $eventLabels = self::EVENT_LABELS;

        return view('admin.settings.notification', compact('settings', 'events', 'eventLabels'));
    }

    public function update(Request $request)
    {
        $request->validate([
            'email_primary'  => 'nullable|email|max:100',
            'email_backup'   => 'nullable|email|max:100',
            'whatsapp_primary'=> ['nullable', 'regex:/^(\+62|08)[0-9]{7,13}$/'],
            'whatsapp_backup' => ['nullable', 'regex:/^(\+62|08)[0-9]{7,13}$/'],
            'fcm_server_key' => 'nullable|string|max:500',
        ]);

        foreach (self::EVENTS as $event) {
            Setting::set(self::GROUP, "event_{$event}",
                $request->boolean("event_{$event}") ? '1' : '0', 'boolean');
        }

        Setting::set(self::GROUP, 'email_primary',   $request->input('email_primary', ''),    'string');
        Setting::set(self::GROUP, 'email_backup',    $request->input('email_backup', ''),     'string');
        Setting::set(self::GROUP, 'whatsapp_primary',$request->input('whatsapp_primary', ''), 'string');
        Setting::set(self::GROUP, 'whatsapp_backup', $request->input('whatsapp_backup', ''),  'string');

        if ($request->filled('fcm_server_key')) {
            Setting::set(self::GROUP, 'fcm_server_key', $request->input('fcm_server_key'), 'string');
        }

        return back()->with('success', 'Pengaturan notifikasi berhasil disimpan.');
    }

    public function testEmail(Request $request)
    {
        $email = Setting::get(self::GROUP, 'email_primary', '');

        if (!$email) {
            return response()->json(['success' => false, 'message' => 'Email utama belum dikonfigurasi.']);
        }

        try {
            Mail::raw(
                "Ini adalah email uji coba dari sistem Bharata Herbal.\n\n" .
                "Dikirim pada: " . now()->format('d M Y, H:i') . " WIB\n" .
                "Konfigurasi email berfungsi dengan baik.",
                function ($message) use ($email) {
                    $message->to($email)
                            ->subject('[Bharata Herbal] Uji Coba Notifikasi Email');
                }
            );

            return response()->json(['success' => true, 'message' => "Email uji coba berhasil dikirim ke {$email}."]);
        } catch (\Throwable $e) {
            return response()->json(['success' => false, 'message' => 'Gagal mengirim email: ' . $e->getMessage()]);
        }
    }

    public function testWhatsapp(Request $request)
    {
        $phone = Setting::get(self::GROUP, 'whatsapp_primary', '');

        if (!$phone) {
            return response()->json(['success' => false, 'message' => 'Nomor WhatsApp utama belum dikonfigurasi.']);
        }

        return response()->json(['success' => false, 'message' => 'WhatsApp notification belum terintegrasi. Gunakan layanan pihak ketiga seperti Fonnte atau Wablas.']);
    }
}
