<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Voucher;
use Illuminate\Http\Request;

class VoucherController extends Controller
{
    public function index()
    {
        $vouchers = Voucher::orderByDesc('created_at')->paginate(15);
        return view('admin.vouchers.index', compact('vouchers'));
    }

    public function create()
    {
        return view('admin.vouchers.create');
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'code'         => 'required|string|max:50|unique:vouchers,code',
            'name'         => 'required|string|max:150',
            'description'  => 'nullable|string|max:500',
            'type'         => 'required|in:flat,percent',
            'value'        => 'required|numeric|min:1',
            'min_purchase' => 'nullable|numeric|min:0',
            'max_discount' => 'nullable|numeric|min:0',
            'usage_limit'  => 'nullable|integer|min:0',
            'starts_at'    => 'nullable|date',
            'expires_at'   => 'nullable|date|after_or_equal:starts_at',
            'is_active'    => 'nullable|boolean',
        ]);

        $data['code']        = strtoupper(trim($data['code']));
        $data['min_purchase']= $data['min_purchase'] ?? 0;
        $data['usage_limit'] = $data['usage_limit']  ?? 0;
        $data['is_active']   = $request->boolean('is_active', true);

        Voucher::create($data);

        return redirect()->route('admin.vouchers.index')
            ->with('success', 'Voucher berhasil dibuat.');
    }

    public function edit(Voucher $voucher)
    {
        return view('admin.vouchers.create', compact('voucher'));
    }

    public function update(Request $request, Voucher $voucher)
    {
        $data = $request->validate([
            'code'         => 'required|string|max:50|unique:vouchers,code,' . $voucher->id,
            'name'         => 'required|string|max:150',
            'description'  => 'nullable|string|max:500',
            'type'         => 'required|in:flat,percent',
            'value'        => 'required|numeric|min:1',
            'min_purchase' => 'nullable|numeric|min:0',
            'max_discount' => 'nullable|numeric|min:0',
            'usage_limit'  => 'nullable|integer|min:0',
            'starts_at'    => 'nullable|date',
            'expires_at'   => 'nullable|date',
            'is_active'    => 'nullable|boolean',
        ]);

        $data['code']        = strtoupper(trim($data['code']));
        $data['min_purchase']= $data['min_purchase'] ?? 0;
        $data['usage_limit'] = $data['usage_limit']  ?? 0;
        $data['is_active']   = $request->boolean('is_active', true);

        $voucher->update($data);

        return redirect()->route('admin.vouchers.index')
            ->with('success', 'Voucher berhasil diperbarui.');
    }

    public function destroy(Voucher $voucher)
    {
        $voucher->delete();
        return back()->with('success', 'Voucher berhasil dihapus.');
    }

    public function toggleStatus(Voucher $voucher)
    {
        $voucher->update(['is_active' => !$voucher->is_active]);
        $label = $voucher->is_active ? 'diaktifkan' : 'dinonaktifkan';
        return back()->with('success', "Voucher berhasil {$label}.");
    }
}
