<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\AddressResource;
use App\Http\Resources\CartResource;
use App\Http\Traits\ApiResponseTrait;
use App\Models\BankAccount;
use App\Models\Setting;
use App\Models\Voucher;
use App\Services\OrderEventNotificationService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class CheckoutController extends Controller
{
    use ApiResponseTrait;

    private const PAYMENT_METHODS = ['cod', 'bank_transfer', 'dana', 'gopay', 'qris'];
    private const COURIERS = [
        'jne' => 'JNE',
        'jnt' => 'J&T Express',
        'sicepat' => 'SiCepat',
    ];

    public function index(Request $request)
    {
        $cart = auth()->user()->cart()->with('items.product')->first();

        if (!$cart || $cart->items()->where('is_selected', true)->count() === 0) {
            return $this->error('Keranjang kosong atau tidak ada item yang dipilih.', 400);
        }

        $addresses = auth()->user()->addresses()->get();
        $defaultAddress = auth()->user()->defaultAddress()->first();
        $minimumOrderAmount  = (int) Setting::get('shipping', 'minimum_order_amount', 0);
        $shippingMethod      = (string) Setting::get('shipping', 'shipping_method', 'flat_rate');
        $freeShippingMin     = (int) Setting::get('shipping', 'free_shipping_minimum', 0);
        $couriers            = $this->activeCouriers();
        $defaultCourier      = $this->resolveSelectedCourier($couriers, null);

        $selectedTotal = $cart->items
            ->where('is_selected', true)
            ->sum(function ($item) {
                return $item->quantity * $item->product->effective_price;
            });

        $shippingCost = $this->resolveShippingCost($selectedTotal, $defaultCourier, $shippingMethod);

        // Build active payment methods from individual boolean settings
        $paymentMethods = $this->activePaymentMethods();

        $codFee       = (int) Setting::get('payment', 'cod_fee', 0);
        $bankAccounts = BankAccount::where('is_active', true)
            ->get(['id', 'bank_name', 'account_number', 'account_holder']);

        return $this->success([
            'cart' => new CartResource($cart),
            'selected_items' => $cart->items()->where('is_selected', true)->with('product')->get()->map(fn($item) => [
                'product_id'   => $item->product_id,
                'product_name' => $item->product->name,
                'product_image'=> $item->product->image ? asset('storage/' . $item->product->image) : '',
                'quantity'     => $item->quantity,
                'unit_price'   => (int) $item->product->effective_price,
                'subtotal'     => (int) ($item->quantity * $item->product->effective_price),
            ]),
            'addresses'            => AddressResource::collection($addresses),
            'default_address'      => $defaultAddress ? new AddressResource($defaultAddress) : null,
            'payment_methods'      => $paymentMethods,
            'shipping_method'      => $shippingMethod,
            'couriers'             => $couriers,
            'default_courier_code' => $defaultCourier['code'] ?? null,
            'bank_accounts'        => $bankAccounts,
            'subtotal'             => (int) $selectedTotal,
            'shipping_cost'        => $shippingCost,
            'free_shipping_min'    => $freeShippingMin,
            'is_free_shipping'     => $shippingCost === 0 && $freeShippingMin > 0,
            'cod_fee'              => $codFee,
            'total'                => (int) ($selectedTotal + $shippingCost),
            'minimum_order_amount' => $minimumOrderAmount,
            'is_minimum_met'       => $selectedTotal >= $minimumOrderAmount,
        ]);
    }

    public function store(Request $request)
    {
        $activePaymentMethods = $this->activePaymentMethods();
        $shippingMethod = (string) Setting::get('shipping', 'shipping_method', 'flat_rate');
        $activeCouriers = $this->activeCouriers();

        $request->validate([
            'address_id'      => 'required|exists:addresses,id',
            'payment_method'  => ['required', Rule::in($activePaymentMethods)],
            'courier_code'    => [
                $shippingMethod === 'automatic' && $activeCouriers !== [] ? 'required' : 'nullable',
                Rule::in(array_column($activeCouriers, 'code')),
            ],
            'notes'           => 'nullable|string|max:255',
            'voucher_code'    => 'nullable|string|max:50',
        ]);

        $user = auth()->user();
        $cart = $user->cart()->with('items.product')->first();

        if (!$cart || $cart->items()->where('is_selected', true)->count() === 0) {
            return $this->error('Keranjang kosong atau tidak ada item yang dipilih.', 400);
        }

        // Verify address belongs to user
        $address = $user->addresses()->findOrFail($request->address_id);

        $selectedItems = $cart->items->where('is_selected', true)->values();
        $subtotal = $selectedItems->sum(function ($item) {
            return $item->quantity * $item->product->effective_price;
        });

        $minimumOrderAmount = (int) Setting::get('shipping', 'minimum_order_amount', 0);

        if ($subtotal < $minimumOrderAmount) {
            return $this->error("Minimum pembelian Rp " . number_format($minimumOrderAmount, 0, ',', '.') . " belum tercapai.", 400);
        }

        $selectedCourier = $this->resolveSelectedCourier($activeCouriers, $request->input('courier_code'));
        $shippingCost = $this->resolveShippingCost($subtotal, $selectedCourier, $shippingMethod);
        $estimatedDeliveryAt = $this->resolveEstimatedDeliveryAt($selectedCourier, $shippingMethod);

        foreach ($selectedItems as $item) {
            if ($item->product->stock < $item->quantity) {
                return $this->error("Stok produk {$item->product->name} tidak mencukupi.", 400);
            }

            if ($item->product->status === 'inactive') {
                return $this->error("Produk {$item->product->name} sedang tidak tersedia.", 400);
            }
        }

        // Apply COD fee if applicable
        $codFee = 0;
        if ($request->payment_method === 'cod') {
            $codFee = (int) Setting::get('payment', 'cod_fee', 0);
        }

        // Apply voucher discount
        $voucherId      = null;
        $discountAmount = 0;
        $voucher        = null;
        if ($request->filled('voucher_code')) {
            $voucher = Voucher::where('code', strtoupper(trim($request->voucher_code)))->first();
            if ($voucher && $voucher->isValid($subtotal)) {
                $discountAmount = (int) $voucher->calculateDiscount($subtotal);
                $voucherId      = $voucher->id;
            }
        }

        $total = max(0, $subtotal + $shippingCost + $codFee - $discountAmount);

        $paymentDeadline = $request->payment_method === 'cod' ? null : now()->addDay();

        $order = DB::transaction(function () use (
            $user,
            $address,
            $voucherId,
            $discountAmount,
            $voucher,
            $subtotal,
            $shippingCost,
            $total,
            $request,
            $paymentDeadline,
            $selectedCourier,
            $estimatedDeliveryAt,
            $selectedItems,
            $cart
        ) {
            if ($voucher) {
                $voucher->increment('used_count');
            }

            $order = $user->orders()->create([
                'address_id'      => $address->id,
                'voucher_id'      => $voucherId,
                'discount_amount' => $discountAmount,
                'subtotal'        => $subtotal,
                'shipping_cost'   => $shippingCost,
                'total_price'     => $total,
                'status'          => 'pending',
                'notes'           => $request->notes,
                'courier_name'    => $selectedCourier['code'] ?? null,
                'payment_deadline' => $paymentDeadline,
                'estimated_delivery_at' => $estimatedDeliveryAt,
            ]);

            foreach ($selectedItems as $item) {
                $order->items()->create([
                    'product_id' => $item->product_id,
                    'quantity'   => $item->quantity,
                    'price'      => $item->product->effective_price,
                ]);

                $item->product->decrement('stock', $item->quantity);
            }

            $order->payment()->create([
                'method'           => $request->payment_method,
                'status'           => 'pending',
                'amount'           => $total,
                'payment_deadline' => $paymentDeadline,
            ]);

            $cart->items()->whereIn('id', $selectedItems->pluck('id'))->delete();

            return $order;
        });

        app(OrderEventNotificationService::class)->notify('order_created', $order->load('user'));

        return $this->success([
            'order_id'        => $order->id,
            'order_number'    => 'ORD-' . str_pad($order->id, 6, '0', STR_PAD_LEFT),
            'subtotal'        => (int) $subtotal,
            'shipping_cost'   => (int) $shippingCost,
            'discount_amount' => (int) $discountAmount,
            'cod_fee'         => (int) $codFee,
            'total_price'     => (int) $total,
            'status'          => $order->status,
            'courier_code'    => $selectedCourier['code'] ?? null,
            'courier_label'   => $selectedCourier['label'] ?? null,
        ], 'Pesanan berhasil dibuat.', 201);
    }

    private function activePaymentMethods(): array
    {
        $activePaymentMethods = array_values(array_filter(
            self::PAYMENT_METHODS,
            function (string $method) {
                if (! Setting::get('payment', "method_{$method}", true)) {
                    return false;
                }

                if ($method === 'bank_transfer') {
                    return BankAccount::where('is_active', true)->exists();
                }

                return true;
            }
        ));

        return $activePaymentMethods !== [] ? $activePaymentMethods : ['cod'];
    }

    private function activeCouriers(): array
    {
        return collect(self::COURIERS)
            ->map(function (string $label, string $code) {
                if (! Setting::get('shipping', "courier_{$code}_active", true)) {
                    return null;
                }

                return [
                    'code' => $code,
                    'label' => $label,
                    'cost' => max((int) Setting::get('shipping', "courier_{$code}_cost", Setting::get('shipping', 'flat_rate_cost', 0)), 0),
                    'estimated_days' => max((int) Setting::get('shipping', "courier_{$code}_days", Setting::get('shipping', 'fallback_estimated_days', 3)), 1),
                ];
            })
            ->filter()
            ->values()
            ->all();
    }

    private function resolveSelectedCourier(array $couriers, ?string $courierCode): ?array
    {
        if ($courierCode) {
            foreach ($couriers as $courier) {
                if ($courier['code'] === $courierCode) {
                    return $courier;
                }
            }
        }

        if ($couriers === []) {
            return null;
        }

        usort($couriers, fn (array $a, array $b) => $a['cost'] <=> $b['cost']);

        return $couriers[0];
    }

    private function resolveShippingCost(int $subtotal, ?array $courier, string $shippingMethod): int
    {
        $freeShippingMin = (int) Setting::get('shipping', 'free_shipping_minimum', 0);
        if ($freeShippingMin > 0 && $subtotal >= $freeShippingMin) {
            return 0;
        }

        if ($shippingMethod === 'automatic' && $courier) {
            return (int) $courier['cost'];
        }

        return (int) Setting::get('shipping', 'flat_rate_cost', 0);
    }

    private function resolveEstimatedDeliveryAt(?array $courier, string $shippingMethod): ?\Carbon\Carbon
    {
        $days = $shippingMethod === 'automatic' && $courier
            ? (int) $courier['estimated_days']
            : max((int) Setting::get('shipping', 'fallback_estimated_days', 3), 1);

        return now()->addDays($days)->setTime(18, 0);
    }
}
