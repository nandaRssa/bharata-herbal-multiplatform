<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Traits\ApiResponseTrait;
use App\Models\Voucher;
use Illuminate\Http\Request;

class VoucherController extends Controller
{
    use ApiResponseTrait;

    /**
     * Validate a voucher code against the current cart subtotal.
     * POST /api/vouchers/validate
     */
    public function validate(Request $request)
    {
        $request->validate([
            'code'     => 'required|string|max:50',
            'subtotal' => 'required|numeric|min:0',
        ]);

        $voucher = Voucher::where('code', strtoupper(trim($request->code)))->first();

        if (!$voucher) {
            return $this->error('Kode voucher tidak ditemukan.', 404);
        }

        if (!$voucher->isValid((float) $request->subtotal)) {
            $reason = $this->invalidReason($voucher, (float) $request->subtotal);
            return $this->error($reason, 422);
        }

        $discount = $voucher->calculateDiscount((float) $request->subtotal);

        return $this->success([
            'voucher_id'      => $voucher->id,
            'code'            => $voucher->code,
            'name'            => $voucher->name,
            'type'            => $voucher->type,
            'value'           => (float) $voucher->value,
            'discount_label'  => $voucher->discount_label,
            'discount_amount' => (int) $discount,
            'min_purchase'    => (int) $voucher->min_purchase,
        ], 'Voucher berhasil diterapkan!');
    }

    private function invalidReason(Voucher $voucher, float $subtotal): string
    {
        if (!$voucher->is_active)           return 'Voucher ini sudah tidak aktif.';
        if ($voucher->is_expired)           return 'Voucher ini sudah kadaluarsa.';
        if ($voucher->starts_at && now()->isBefore($voucher->starts_at))
                                            return 'Voucher belum dapat digunakan.';
        if ($voucher->usage_limit > 0 && $voucher->used_count >= $voucher->usage_limit)
                                            return 'Kuota voucher sudah habis.';
        if ($subtotal < (float) $voucher->min_purchase)
                                            return 'Minimum pembelian Rp ' . number_format($voucher->min_purchase, 0, ',', '.') . ' untuk menggunakan voucher ini.';
        return 'Voucher tidak dapat digunakan saat ini.';
    }
}
