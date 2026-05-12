<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Payment extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id', 'method', 'status', 'proof', 'proof_image',
        'account_name', 'account_number', 'amount', 'paid_at', 'payment_deadline',
    ];

    protected $casts = [
        'paid_at'          => 'datetime',
        'payment_deadline' => 'datetime',
    ];

    public function order()
    {
        return $this->belongsTo(Order::class);
    }

    public function getMethodLabelAttribute(): string
    {
        $labels = [
            'cod'          => 'Bayar di Tempat (COD)',
            'cash_on_delivery' => 'Bayar di Tempat (COD)',
            'dana'         => 'Dana',
            'gopay'        => 'GoPay',
            'qris'         => 'QRIS',
            'bank_transfer'=> 'Transfer Bank',
            'ewallet'      => 'E-Wallet',
        ];
        return $labels[$this->method] ?? ucfirst($this->method);
    }

    public function getStatusLabelAttribute(): string
    {
        if ($this->status === 'pending' && $this->method === 'cod') {
            return $this->order?->status === 'completed'
                ? 'Dibayar'
                : 'Bayar Saat Diterima (COD)';
        }

        $labels = [
            'pending'  => 'Menunggu Pembayaran',
            'pending_confirmation' => 'Menunggu Konfirmasi Admin',
            'paid'     => 'Dibayar',
            'verified' => 'Pembayaran Terkonfirmasi',
            'failed'   => 'Gagal',
        ];
        return $labels[$this->status] ?? ucfirst($this->status);
    }
}
