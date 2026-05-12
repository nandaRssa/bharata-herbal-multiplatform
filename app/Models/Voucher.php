<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Voucher extends Model
{
    protected $fillable = [
        'code', 'name', 'description', 'type', 'value',
        'min_purchase', 'max_discount', 'usage_limit',
        'used_count', 'starts_at', 'expires_at', 'is_active',
    ];

    protected $casts = [
        'value'         => 'decimal:2',
        'min_purchase'  => 'decimal:2',
        'max_discount'  => 'decimal:2',
        'is_active'     => 'boolean',
        'starts_at'     => 'datetime',
        'expires_at'    => 'datetime',
    ];

    // ─── Validation ───────────────────────────────────────────────────

    public function isValid(float $subtotal): bool
    {
        if (!$this->is_active)                                         return false;
        if ($this->starts_at  && now()->isBefore($this->starts_at))   return false;
        if ($this->expires_at && now()->isAfter($this->expires_at))    return false;
        if ($this->usage_limit > 0 && $this->used_count >= $this->usage_limit) return false;
        if ($subtotal < (float) $this->min_purchase)                   return false;
        return true;
    }

    public function calculateDiscount(float $subtotal): float
    {
        if ($this->type === 'flat') {
            return min((float) $this->value, $subtotal);
        }

        // percent
        $discount = $subtotal * ((float) $this->value / 100);
        if ($this->max_discount) {
            $discount = min($discount, (float) $this->max_discount);
        }
        return $discount;
    }

    // ─── Accessors ────────────────────────────────────────────────────

    public function getIsExpiredAttribute(): bool
    {
        return $this->expires_at && now()->isAfter($this->expires_at);
    }

    public function getDiscountLabelAttribute(): string
    {
        if ($this->type === 'flat') {
            return 'Rp ' . number_format($this->value, 0, ',', '.');
        }
        $label = $this->value . '%';
        if ($this->max_discount) {
            $label .= ' (maks Rp ' . number_format($this->max_discount, 0, ',', '.') . ')';
        }
        return $label;
    }
}
