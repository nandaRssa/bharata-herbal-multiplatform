<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ActivityLog;
use Illuminate\Http\Request;

class ActivityLogController extends Controller
{
    /**
     * Daftar label aksi yang didukung
     */
    public static array $actionLabels = [
        'admin_login'         => ['label' => 'Login',              'color' => 'blue'],
        'admin_logout'        => ['label' => 'Logout',             'color' => 'gray'],
        'create_product'      => ['label' => 'Tambah Produk',      'color' => 'green'],
        'update_product'      => ['label' => 'Edit Produk',        'color' => 'yellow'],
        'archive_product'     => ['label' => 'Arsip Produk',       'color' => 'orange'],
        'restore_product'     => ['label' => 'Pulihkan Produk',    'color' => 'teal'],
        'delete_product'      => ['label' => 'Hapus Produk',       'color' => 'red'],
        'update_order_status' => ['label' => 'Update Status Pesanan', 'color' => 'purple'],
        'update_settings'     => ['label' => 'Update Pengaturan', 'color' => 'indigo'],
    ];

    public function index(Request $request)
    {
        $query = ActivityLog::with('admin')->latest();

        // Filter by action
        if ($request->filled('action')) {
            $query->where('action', $request->action);
        }

        // Filter by date_from
        if ($request->filled('date_from')) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }

        // Filter by date_to
        if ($request->filled('date_to')) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }

        // Filter by admin (search)
        if ($request->filled('search')) {
            $search = $request->search;
            $query->whereHas('admin', fn($q) => $q->where('name', 'like', "%{$search}%"));
        }

        $logs       = $query->paginate(20)->withQueryString();
        $actions    = self::$actionLabels;

        return view('admin.activity-logs.index', compact('logs', 'actions'));
    }
}
