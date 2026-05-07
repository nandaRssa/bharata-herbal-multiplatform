<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\User;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function index()
    {
        // ════════════════════════════════════════════════════════════════════════
        // 📊 SUMMARY STATISTICS
        // ════════════════════════════════════════════════════════════════════════
        
        // Total counts
        $totalProducts  = Product::count();
        $totalCustomers = User::where('role', 'customer')->count();
        $totalOrders    = Order::count();
        $totalSales     = Order::revenueRelevant()->sum('total_price');

        // Today's statistics
        $todaySales = Order::revenueRelevant()
            ->whereDate('created_at', today())
            ->sum('total_price');
        
        $todayOrders = Order::whereDate('created_at', today())->count();
        
        // Active products (not inactive, with stock > 0)
        $activeProducts = Product::where('status', '!=', 'inactive')
            ->where('stock', '>', 0)
            ->count();

        // Low stock products (less than 10 units)
        $lowStockProducts = Product::where('stock', '>', 0)
            ->where('stock', '<', 10)
            ->where('status', '!=', 'inactive')
            ->orderBy('stock', 'asc')
            ->take(5)
            ->get();

        // Out of stock products
        $outOfStockCount = Product::where('stock', '<=', 0)
            ->where('status', '!=', 'inactive')
            ->count();

        // Monthly statistics
        $newProducts  = Product::whereMonth('created_at', now()->month)->count();
        $newCustomers = User::where('role', 'customer')->whereMonth('created_at', now()->month)->count();
        $newOrders    = Order::whereDate('created_at', today())->count();

        // ════════════════════════════════════════════════════════════════════════
        // 📈 RECENT ORDERS (latest 10)
        // ════════════════════════════════════════════════════════════════════════
        $recentOrders = Order::with('user')
            ->latest()
            ->take(10)
            ->get();

        // ════════════════════════════════════════════════════════════════════════
        // 📊 SALES CHART (Last 7 Days)
        // ════════════════════════════════════════════════════════════════════════
        $salesRaw = Order::select(
                DB::raw('DATE(created_at) as date'),
                DB::raw('SUM(total_price) as total')
            )
            ->revenueRelevant()
            ->whereBetween('created_at', [now()->subDays(6)->startOfDay(), now()->endOfDay()])
            ->groupBy('date')
            ->orderBy('date')
            ->pluck('total', 'date')
            ->toArray();

        $dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
        $salesLabels = [];
        $salesData   = [];

        for ($i = 6; $i >= 0; $i--) {
            $date = now()->subDays($i)->toDateString();
            $salesLabels[] = $dayNames[now()->subDays($i)->dayOfWeek];
            $salesData[]   = (float) ($salesRaw[$date] ?? 0);
        }

        // ════════════════════════════════════════════════════════════════════════
        // 📊 CATEGORY SALES DISTRIBUTION
        // ════════════════════════════════════════════════════════════════════════
        $categorySales = OrderItem::join('product_category', 'order_items.product_id', '=', 'product_category.product_id')
            ->join('orders', 'order_items.order_id', '=', 'orders.id')
            ->join('categories', 'product_category.category_id', '=', 'categories.id')
            ->select('categories.name', DB::raw('COUNT(*) as total'))
            ->whereIn('orders.status', Order::revenueStatuses())
            ->groupBy('categories.id', 'categories.name')
            ->orderByDesc('total')
            ->limit(6)
            ->get();

        $categoryData = $categorySales->isNotEmpty()
            ? $categorySales->map(fn($c) => ['name' => $c->name, 'value' => (int) $c->total])->toArray()
            : [
                ['name' => 'Imunitas',    'value' => 30],
                ['name' => 'Diabetes',    'value' => 25],
                ['name' => 'Asam Urat',   'value' => 20],
                ['name' => 'Stroke',      'value' => 12],
                ['name' => 'Pencernaan',  'value' => 8],
                ['name' => 'Pelangsing',  'value' => 5],
            ];

        // ════════════════════════════════════════════════════════════════════════
        // ⭐ TOP PERFORMING PRODUCTS
        // ════════════════════════════════════════════════════════════════════════
        $topProducts = Product::with('reviews')
            ->orderByDesc('sales_count')
            ->orderByDesc('rating')
            ->take(8)
            ->get();

        // ════════════════════════════════════════════════════════════════════════
        // 📦 ORDER STATUS BREAKDOWN (Today)
        // ════════════════════════════════════════════════════════════════════════
        $orderStatusBreakdown = Order::whereDate('created_at', today())
            ->select('status', DB::raw('COUNT(*) as count'))
            ->groupBy('status')
            ->pluck('count', 'status')
            ->toArray();

        // ════════════════════════════════════════════════════════════════════════
        // 💰 REVENUE BREAKDOWN (Today)
        // ════════════════════════════════════════════════════════════════════════
        $revenueByStatus = Order::revenueRelevant()
            ->whereDate('created_at', today())
            ->select('status', DB::raw('SUM(total_price) as revenue'))
            ->groupBy('status')
            ->pluck('revenue', 'status')
            ->toArray();

        return view('admin.dashboard', compact(
            'totalProducts', 'totalCustomers', 'totalOrders', 'totalSales',
            'activeProducts', 'lowStockProducts', 'outOfStockCount',
            'todaySales', 'todayOrders',
            'newProducts', 'newCustomers', 'newOrders',
            'recentOrders', 'salesLabels', 'salesData', 'categoryData', 'topProducts',
            'orderStatusBreakdown', 'revenueByStatus'
        ));
    }
}
