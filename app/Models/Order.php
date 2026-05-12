<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Order extends Model
{
    use HasFactory;

    public const REVENUE_STATUSES = ['paid', 'processing', 'shipped', 'completed'];
    public const STATUS_FLOW = ['pending', 'paid', 'processing', 'shipped', 'completed', 'cancelled'];

    protected $fillable = [
        'user_id',
        'address_id',
        'voucher_id',
        'discount_amount',
        'subtotal',
        'shipping_cost',
        'total_price',
        'status',
        'tracking_number',
        'courier_name',
        'notes',
        'cancel_reason',
        'payment_deadline',
        'estimated_delivery_at',
    ];

    protected $casts = [
        'subtotal'              => 'decimal:2',
        'shipping_cost'         => 'decimal:2',
        'discount_amount'       => 'decimal:2',
        'total_price'           => 'decimal:2',
        'payment_deadline'      => 'datetime',
        'estimated_delivery_at' => 'datetime',
    ];

    public function voucher()
    {
        return $this->belongsTo(Voucher::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function address()
    {
        return $this->belongsTo(Address::class);
    }

    public function items()
    {
        return $this->hasMany(OrderItem::class);
    }

    public function payment()
    {
        return $this->hasOne(Payment::class);
    }

    public function reviews()
    {
        return $this->hasMany(Review::class);
    }

    public function trackingUpdates()
    {
        return $this->hasMany(OrderTracking::class, 'order_id')->orderBy('created_at');
    }

    public function scopeRevenueRelevant($query)
    {
        return $query->whereIn('status', self::REVENUE_STATUSES);
    }

    public static function revenueStatuses(): array
    {
        return self::REVENUE_STATUSES;
    }

    public function canBeCancelled(): bool
    {
        if (in_array($this->status, ['processing', 'shipped', 'completed', 'cancelled'])) {
            return false;
        }

        // Can cancel if admin hasn't confirmed payment yet
        if ($this->status === 'pending') {
            return true;
        }

        return $this->created_at->diffInMinutes(now()) <= 120;
    }

    public function isCodOrder(): bool
    {
        return $this->payment?->method === 'cod';
    }

    public function requiresCustomerPayment(): bool
    {
        return ! $this->isCodOrder();
    }

    public function isPaymentConfirmed(): bool
    {
        return in_array($this->payment?->status, ['paid', 'verified'], true);
    }

    public function needsCustomerPayment(): bool
    {
        return $this->status === 'pending'
            && $this->requiresCustomerPayment()
            && ! $this->isPaymentConfirmed()
            && ! $this->hasUploadedProof();
    }

    public function hasUploadedProof(): bool
    {
        return $this->payment
            && $this->payment->proof_image
            && $this->payment->status === 'pending_confirmation';
    }

    public function canUploadPaymentProof(): bool
    {
        return $this->needsCustomerPayment();
    }

    public function canPayNow(): bool
    {
        return $this->needsCustomerPayment() && in_array($this->payment?->method, ['bank_transfer', 'dana', 'gopay', 'qris'], true);
    }

    public function allowedNextStatuses(): array
    {
        return match ($this->status) {
            'pending' => $this->needsCustomerPayment()
                ? ['paid', 'cancelled']
                : ['processing', 'cancelled'],
            'paid' => ['processing', 'cancelled'],
            'processing' => ['shipped', 'cancelled'],
            'shipped' => ['completed'],
            default => [],
        };
    }

    public function canTransitionTo(string $status): bool
    {
        if ($status === $this->status) {
            return true;
        }

        return in_array($status, $this->allowedNextStatuses(), true);
    }

    public function isPaymentExpired(): bool
    {
        return $this->payment_deadline && now()->greaterThan($this->payment_deadline);
    }

    public function getStatusLabelAttribute(): string
    {
        $labels = [
            'paid'       => 'Pembayaran Terkonfirmasi',
            'processing' => 'Sedang Diproses',
            'shipped'    => 'Dikirim',
            'completed'  => 'Selesai',
            'cancelled'  => 'Dibatalkan',
        ];

        if ($this->status === 'pending') {
            if ($this->hasUploadedProof()) {
                return 'Menunggu Konfirmasi Admin';
            }
            return $this->requiresCustomerPayment() && ! $this->isPaymentConfirmed()
                ? 'Menunggu Pembayaran'
                : 'Menunggu Konfirmasi';
        }

        return $labels[$this->status] ?? ucfirst($this->status);
    }

    public function getOrderNumberAttribute(): string
    {
        $date = ($this->created_at ?? now())->format('Ymd');
        return 'BHT-' . $date . '-' . str_pad($this->id, 5, '0', STR_PAD_LEFT);
    }

    public function getStatusColorAttribute(): string
    {
        $colors = [
            'pending'    => 'yellow',
            'paid'       => 'blue',
            'processing' => 'indigo',
            'shipped'    => 'orange',
            'completed'  => 'green',
            'cancelled'  => 'red',
        ];
        return $colors[$this->status] ?? 'gray';
    }

    public function canConfirmReceived(): bool
    {
        return $this->status === 'shipped';
    }

    public function autoAdvanceStatus(): void
    {
        // Disabling auto-complete to allow manual customer confirmation as requested
        /*
        if ($this->status === 'shipped') {
            $this->loadMissing('trackingUpdates');
            $lastUpdate = $this->trackingUpdates->sortByDesc('created_at')->first();
            if ($lastUpdate && now()->greaterThanOrEqualTo($lastUpdate->created_at)) {
                $this->update(['status' => 'completed']);
                if ($this->payment && $this->payment->method === 'cod') {
                    $this->payment->update([
                        'status' => 'verified',
                        'paid_at' => $this->payment->paid_at ?? now(),
                    ]);
                }
            }
        }
        */
    }

    public function getCourierLabelAttribute(): ?string
    {
        if ($this->courier_name) {
            return match (strtolower((string) $this->courier_name)) {
                'jne' => 'JNE',
                'jnt', 'j&t', 'j&t express' => 'J&T Express',
                'sicepat' => 'SiCepat',
                default => $this->courier_name,
            };
        }

        $tracking = strtoupper((string) $this->tracking_number);

        return match (true) {
            str_starts_with($tracking, 'JNE') => 'JNE',
            str_starts_with($tracking, 'JNT') => 'J&T Express',
            str_starts_with($tracking, 'SIL') => 'SiCepat',

            !empty($tracking) => 'Kurir Internal',
            default => null,
        };
    }

    public function isArrived(): bool
    {
        return $this->trackingUpdates()
            ->where('keterangan', 'LIKE', '%sampai tujuan%')
            ->exists();
    }

    public function getIsArrivedAttribute(): bool
    {
        return $this->isArrived();
    }
}
