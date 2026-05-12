<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\BankAccount;
use App\Models\Setting;
use Illuminate\Http\Request;

class PaymentSettingController extends Controller
{
    private const GROUP = 'payment';

    private const METHODS = ['cod', 'bank_transfer', 'dana', 'gopay', 'qris'];

    public function index()
    {
        $settings     = Setting::getGroup(self::GROUP);
        $bankAccounts = BankAccount::orderBy('bank_name')->get();
        $methods      = self::METHODS;

        return view('admin.settings.payment', compact('settings', 'bankAccounts', 'methods'));
    }

    public function update(Request $request)
    {
        $request->validate([
            'cod_fee' => 'required|integer|min:0',
        ]);

        foreach (self::METHODS as $method) {
            Setting::set(self::GROUP, "method_{$method}", $request->boolean("method_{$method}") ? '1' : '0', 'boolean');
        }

        Setting::set(self::GROUP, 'cod_fee', (int) $request->cod_fee, 'integer');

        foreach (['dana', 'gopay', 'qris'] as $ew) {
            if ($request->filled("{$ew}_merchant")) {
                Setting::set(self::GROUP, "{$ew}_merchant", $request->input("{$ew}_merchant"), 'string');
            }
            if ($request->filled("{$ew}_qr")) {
                Setting::set(self::GROUP, "{$ew}_qr", $request->input("{$ew}_qr"), 'string');
            }
            if ($request->filled("{$ew}_instructions")) {
                Setting::set(self::GROUP, "{$ew}_instructions", $request->input("{$ew}_instructions"), 'string');
            }
        }

        // Hapus format lama (JSON methods) jika masih ada
        Setting::where('group', self::GROUP)->where('key', 'methods')->delete();

        return back()->with('success', 'Pengaturan pembayaran berhasil disimpan.');
    }

    public function storeBankAccount(Request $request)
    {
        $request->validate([
            'bank_name'      => 'required|string|max:100',
            'account_number' => 'required|numeric',
            'account_holder' => 'required|string|max:100',
        ]);

        BankAccount::create($request->only('bank_name', 'account_number', 'account_holder'));

        return back()->with('success', 'Rekening bank berhasil ditambahkan.');
    }

    public function updateBankAccount(Request $request, BankAccount $bankAccount)
    {
        $request->validate([
            'bank_name'      => 'required|string|max:100',
            'account_number' => 'required|numeric',
            'account_holder' => 'required|string|max:100',
        ]);

        $bankAccount->update($request->only('bank_name', 'account_number', 'account_holder'));

        return back()->with('success', 'Rekening bank berhasil diperbarui.');
    }

    public function destroyBankAccount(BankAccount $bankAccount)
    {
        $bankAccount->delete();
        return back()->with('success', 'Rekening bank berhasil dihapus.');
    }
}
