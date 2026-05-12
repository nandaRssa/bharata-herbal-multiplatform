<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CartResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $minimumOrderAmount = (int) \App\Models\Setting::get('shipping', 'minimum_order_amount', 0);
        $flatRateCost       = (int) \App\Models\Setting::get('shipping', 'flat_rate_cost', 0);
        $freeShippingMin    = (int) \App\Models\Setting::get('shipping', 'free_shipping_minimum', 0);

        $selectedTotal = $this->items
            ->where('is_selected', true)
            ->sum(function ($item) {
                return $item->quantity * $item->product->effective_price;
            });

        // Apply free shipping logic
        $shippingCost = ($freeShippingMin > 0 && $selectedTotal >= $freeShippingMin)
            ? 0
            : $flatRateCost;

        return [
            'id'                      => $this->id,
            'items'                   => CartItemResource::collection($this->items),
            'total'                   => (int) $selectedTotal,
            'selected_count'          => $this->items->where('is_selected', true)->count(),
            'total_items'             => $this->items->where('is_selected', true)->sum('quantity'),
            'shipping_cost'           => $shippingCost,
            'free_shipping_min'       => $freeShippingMin,
            'is_free_shipping'        => $shippingCost === 0 && $freeShippingMin > 0,
            'minimum_order_amount'    => $minimumOrderAmount,
            'is_minimum_met'          => $selectedTotal >= $minimumOrderAmount,
            'created_at'              => $this->created_at->toISOString(),
        ];
    }
}
