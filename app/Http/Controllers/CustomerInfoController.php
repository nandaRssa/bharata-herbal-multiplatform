<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class CustomerInfoController extends Controller
{
    /**
     * Tampilkan halaman info untuk customer yang mencoba akses web
     * Arahkan mereka untuk menggunakan mobile app
     */
    public function index()
    {
        $storeSettings = \App\Models\Setting::getGroup('store') ?? [];
        
        return view('customer-info', [
            'storeName' => $storeSettings['name'] ?? 'Bharata Herbal',
            'storePhone' => $storeSettings['phone'] ?? '',
            'storeEmail' => $storeSettings['email'] ?? '',
        ]);
    }
}
