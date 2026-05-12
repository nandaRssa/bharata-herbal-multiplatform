<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Setting;
use Illuminate\Http\Request;

class ShippingSettingController extends Controller
{
    private const GROUP = 'shipping';

    private const COURIERS = ['jne', 'jnt', 'sicepat'];

    public function index()
    {
        $settings = Setting::getGroup(self::GROUP);
        $couriers = self::COURIERS;

        return view('admin.settings.shipping', compact('settings', 'couriers'));
    }

    public function update(Request $request)
    {
        $request->validate([
            'shipping_method'        => 'required|in:flat_rate,automatic',
            'flat_rate_cost'         => 'required|integer|min:0',
            'free_shipping_minimum'  => 'required|integer|min:0',
            'minimum_order_amount'   => 'required|integer|min:0',
            'fallback_estimated_days' => 'required|integer|min:1|max:30',
            'courier_jne_cost'      => 'nullable|integer|min:0',
            'courier_jnt_cost'      => 'nullable|integer|min:0',
            'courier_sicepat_cost'  => 'nullable|integer|min:0',
        ]);

        foreach (self::COURIERS as $courier) {
            Setting::set(
                self::GROUP,
                "courier_{$courier}_active",
                $request->boolean("courier_{$courier}_active") ? '1' : '0',
                'boolean'
            );

            $days = (int) $request->input("courier_{$courier}_days", 3);
            $cost = (int) $request->input("courier_{$courier}_cost", $request->input('flat_rate_cost', 0));
            Setting::set(self::GROUP, "courier_{$courier}_days", max(1, $days), 'integer');
            Setting::set(self::GROUP, "courier_{$courier}_cost", max(0, $cost), 'integer');
        }

        Setting::set(self::GROUP, 'shipping_method',        $request->shipping_method,               'string');
        Setting::set(self::GROUP, 'flat_rate_cost',         (int) $request->flat_rate_cost,           'integer');
        Setting::set(self::GROUP, 'free_shipping_minimum',  (int) $request->free_shipping_minimum,    'integer');
        Setting::set(self::GROUP, 'minimum_order_amount',   (int) $request->minimum_order_amount,     'integer');
        Setting::set(self::GROUP, 'fallback_estimated_days', (int) $request->fallback_estimated_days,  'integer');

        return back()->with('success', 'Pengaturan pengiriman berhasil disimpan.');
    }
}
