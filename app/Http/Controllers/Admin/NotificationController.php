<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\Product;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    /**
     * Check for new orders (last 5 minutes)
     */
    public function checkNewOrders(Request $request)
    {
        $lastCheckTime = $request->query('last_check');
        $query = Order::latest();

        if ($lastCheckTime) {
            $query->where('created_at', '>', date('Y-m-d H:i:s', strtotime($lastCheckTime)));
        } else {
            // Get orders from last 5 minutes
            $query->where('created_at', '>', now()->subMinutes(5));
        }

        $newOrders = $query->take(5)->with('user')->get();

        return response()->json([
            'success' => true,
            'data' => $newOrders->map(function ($order) {
                return [
                    'id' => $order->id,
                    'order_number' => $order->order_number,
                    'customer_name' => $order->user->name ?? 'Unknown',
                    'total_price' => $order->total_price,
                    'created_at' => $order->created_at->toDateTimeString(),
                ];
            }),
        ]);
    }

    /**
     * Check for low stock products (< 10)
     */
    public function checkLowStock(Request $request)
    {
        $lastCheckTime = $request->query('last_check');
        $query = Product::where('stock', '<', 10)
            ->where('stock', '>', 0)  // Exclude out of stock
            ->latest('updated_at');

        if ($lastCheckTime) {
            $query->where('updated_at', '>', date('Y-m-d H:i:s', strtotime($lastCheckTime)));
        } else {
            // Get products updated in last 5 minutes
            $query->where('updated_at', '>', now()->subMinutes(5));
        }

        $lowStockProducts = $query->take(5)->get();

        return response()->json([
            'success' => true,
            'data' => $lowStockProducts->map(function ($product) {
                return [
                    'id' => $product->id,
                    'name' => $product->name,
                    'stock' => $product->stock,
                    'updated_at' => $product->updated_at->toDateTimeString(),
                ];
            }),
        ]);
    }

    /**
     * Get all low stock products
     */
    public function getAllLowStock()
    {
        $lowStockProducts = Product::where('stock', '<', 10)
            ->where('stock', '>', 0)
            ->orderBy('stock', 'asc')
            ->take(10)
            ->get(['id', 'name', 'stock']);

        return response()->json([
            'success' => true,
            'data' => $lowStockProducts,
        ]);
    }

    /**
     * Get summary - new orders & low stock count
     */
    public function getSummary()
    {
        $newOrdersCount = Order::where('status', 'pending')
            ->orWhere('status', 'paid')
            ->count();

        $lowStockCount = Product::where('stock', '<', 10)
            ->where('stock', '>', 0)
            ->count();

        $outOfStockCount = Product::where('stock', 0)->count();

        return response()->json([
            'success' => true,
            'data' => [
                'new_orders_count' => $newOrdersCount,
                'low_stock_count' => $lowStockCount,
                'out_of_stock_count' => $outOfStockCount,
            ],
        ]);
    }
}
