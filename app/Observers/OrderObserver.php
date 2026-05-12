<?php

namespace App\Observers;

use App\Models\Order;

class OrderObserver
{
    public function created(Order $order): void
    {
        if (in_array($order->status, Order::REVENUE_STATUSES, true)) {
            $this->updateProductSales($order);
        }
    }

    public function updated(Order $order): void
    {
        if ($order->isDirty('status')) {
            $this->updateProductSales($order);
        }
    }

    /**
     * Update sales count for all products in the order.
     */
    private function updateProductSales(Order $order): void
    {
        $order->loadMissing('items.product');
        
        foreach ($order->items as $item) {
            if ($item->product) {
                $item->product->updateSalesCount();
            }
        }
    }
}
