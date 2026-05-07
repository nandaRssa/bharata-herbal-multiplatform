<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'order_id'        => $this->order_id,
            'product_id'      => $this->product_id,
            'product_name'    => $this->product?->name,
            'product_image'   => $this->product?->image ? asset('storage/' . $this->product->image) : null,
            'quantity'        => $this->quantity,
            'unit_price'      => (int) $this->price,          // DB kolom: price
            'subtotal'        => (int) ($this->quantity * $this->price),
            'created_at'      => $this->created_at->toISOString(),
        ];
    }
}
