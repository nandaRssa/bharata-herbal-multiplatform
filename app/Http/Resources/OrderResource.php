<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $reviewedProductIds = $this->reviews()
            ->where('order_id', $this->id)
            ->pluck('product_id')
            ->toArray();

        $canReview = $this->status === 'completed'
            && $this->reviews()->count() === 0;

        return [
            'id'                    => $this->id,
            'order_number'          => $this->order_number,
            'status'                => $this->status,
            'status_label'          => $this->status_label,
            'subtotal'              => (int) $this->subtotal,
            'shipping_cost'         => (int) $this->shipping_cost,
            'discount_amount'       => (int) $this->discount_amount,
            'total_price'           => (int) $this->total_price,
            'voucher_code'          => $this->voucher?->code,
            'notes'                 => $this->notes,
            'tracking_number'       => $this->tracking_number,
            'courier_name'          => $this->courier_name,
            'courier_label'         => $this->courier_label,
            'cancel_reason'         => $this->cancel_reason,
            'payment_deadline'      => $this->payment_deadline?->toISOString(),
            'estimated_delivery_at' => $this->estimated_delivery_at?->toISOString(),
            'is_cod'                => $this->isCodOrder(),
            'can_cancel'            => $this->canBeCancelled(),
            'needs_payment'         => $this->needsCustomerPayment(),
            'can_pay_now'           => $this->canPayNow(),
            'can_upload_payment_proof' => $this->canUploadPaymentProof(),
            'can_confirm_received'  => $this->canConfirmReceived(),
            'items'                 => OrderItemResource::collection($this->whenLoaded('items')),
            'address'               => new AddressResource($this->whenLoaded('address')),
            'payment'               => $this->whenLoaded('payment', function () {
                $p = $this->payment;
                return $p ? [
                    'id'             => $p->id,
                    'method'         => $p->method,
                    'method_label'   => $p->method_label,
                    'status'         => $p->status,
                    'status_label'   => $p->status_label,
                    'amount'         => (int) ($p->amount ?? $this->total_price),
                    'proof_image_url'=> $p->proof_image ? asset('storage/' . $p->proof_image) : null,
                    'paid_at'        => $p->paid_at?->toISOString(),
                ] : null;
            }),
            'can_review'            => $canReview,
            'reviewed_product_ids'  => $reviewedProductIds,
            'tracking_updates'      => $this->whenLoaded('trackingUpdates', function () {
                return $this->trackingUpdates->map(fn ($t) => [
                    'id'          => $t->id,
                    'keterangan'  => $t->keterangan,
                    'lokasi'      => $t->lokasi,
                    'created_at'  => $t->created_at?->toISOString(),
                ]);
            }),
            'created_at'            => $this->created_at->toISOString(),
            'updated_at'            => $this->updated_at->toISOString(),
        ];
    }
}
