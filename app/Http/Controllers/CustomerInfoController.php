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
        $storeName = \App\Models\Setting::get('store', 'store_name', 'Bharata Herbal');
        $storePhone = \App\Models\Setting::get('store', 'whatsapp_number', '');
        $storeEmail = \App\Models\Setting::get('store', 'business_email', '');

        return view('customer-info', compact('storeName', 'storePhone', 'storeEmail'));
    }
}
