<?php

namespace App\Observers;

use App\Models\Order;
use App\Models\OrderItem;

class OrderItemObserver
{
    public function created(OrderItem $orderItem): void
    {
        $this->updateProductStats($orderItem);
    }

    public function updated(OrderItem $orderItem)
    {
        if ($orderItem->isDirty('status')) {
            $this->updateProductStats($orderItem);
        }
    }

    private function updateProductStats(OrderItem $orderItem): void
    {
        if (in_array((string) $orderItem->order?->status, Order::REVENUE_STATUSES, true)) {
            $product = $orderItem->product;
            if ($product) {
                $product->updateSalesCount();
            }
        }
    }
}
