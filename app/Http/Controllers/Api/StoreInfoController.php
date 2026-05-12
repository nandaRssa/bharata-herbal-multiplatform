<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Traits\ApiResponseTrait;
use App\Models\Setting;

class StoreInfoController extends Controller
{
    use ApiResponseTrait;

    /**
     * Public endpoint — returns store info from admin settings.
     * Used by mobile app to display dynamic store name, contact, etc.
     */
    public function index()
    {
        $store    = Setting::getGroup('store')    ?? [];
        $shipping = Setting::getGroup('shipping') ?? [];
        $payment  = Setting::getGroup('payment')  ?? [];

        // Active payment methods
        $allMethods = ['cod', 'bank_transfer', 'dana', 'gopay', 'qris'];
        $activeMethods = collect($allMethods)
            ->filter(fn($m) => (bool) Setting::get('payment', "method_{$m}", true))
            ->values()
            ->toArray();

        // Bank accounts
        $bankAccounts = \App\Models\BankAccount::where('is_active', true)
            ->get(['id', 'bank_name', 'account_number', 'account_holder'])
            ->toArray();

        return $this->success([
            'store' => [
                'name'        => $store['store_name']        ?? 'Bharata Herbal',
                'description' => $store['store_description'] ?? '',
                'address'     => $store['store_address']     ?? '',
                'whatsapp'    => $store['whatsapp_number']   ?? '',
                'email'       => $store['business_email']    ?? '',
                'instagram'   => $store['instagram']         ?? '',
            ],
            'shipping' => [
                'method'              => $shipping['shipping_method']       ?? 'flat_rate',
                'flat_rate_cost'      => (int) ($shipping['flat_rate_cost']       ?? 0),
                'free_shipping_min'   => (int) ($shipping['free_shipping_minimum'] ?? 0),
                'minimum_order'       => (int) ($shipping['minimum_order_amount']  ?? 0),
                'estimated_days'      => (int) ($shipping['fallback_estimated_days'] ?? 3),
                'couriers'            => [
                    'jne'     => ['active' => (bool)($shipping['courier_jne_active']     ?? false), 'days' => (int)($shipping['courier_jne_days']     ?? 3), 'cost' => (int)($shipping['courier_jne_cost'] ?? ($shipping['flat_rate_cost'] ?? 0))],
                    'jnt'     => ['active' => (bool)($shipping['courier_jnt_active']     ?? false), 'days' => (int)($shipping['courier_jnt_days']     ?? 3), 'cost' => (int)($shipping['courier_jnt_cost'] ?? ($shipping['flat_rate_cost'] ?? 0))],
                    'sicepat' => ['active' => (bool)($shipping['courier_sicepat_active'] ?? false), 'days' => (int)($shipping['courier_sicepat_days'] ?? 3), 'cost' => (int)($shipping['courier_sicepat_cost'] ?? ($shipping['flat_rate_cost'] ?? 0))],
                ],
            ],
            'payment' => [
                'active_methods' => $activeMethods,
                'cod_fee'        => (int) ($payment['cod_fee'] ?? 0),
                'bank_accounts'  => $bankAccounts,
            ],
        ]);
    }
}
