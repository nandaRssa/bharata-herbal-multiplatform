<?php
// Quick test script — jalankan dari browser XAMPP
define('LARAVEL_ROOT', 'C:/xampp/htdocs/BharataHerbal_PABP/bhrata-herbal-mobile');
chdir(LARAVEL_ROOT);
require LARAVEL_ROOT . '/vendor/autoload.php';
$app = require LARAVEL_ROOT . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

// Test: ambil products
$products = \App\Models\Product::take(3)->get(['id', 'name', 'stock', 'status']);
echo "=== PRODUCTS ===\n";
foreach ($products as $p) {
    echo "ID={$p->id} | {$p->name} | stock={$p->stock} | status={$p->status}\n";
}

// Test: ambil user dan cart
$user = \App\Models\User::where('role', 'customer')->first();
echo "\n=== USER ===\n";
echo "ID={$user->id} | {$user->email}\n";

$cart = $user->cart()->with('items.product')->first();
echo "\n=== CART ===\n";
if (!$cart) {
    echo "Cart: KOSONG (belum ada record)\n";
    // Coba buat cart
    $cart = $user->cart()->firstOrCreate(['user_id' => $user->id]);
    echo "Cart dibuat: ID={$cart->id}\n";
} else {
    echo "Cart ID={$cart->id}, items=" . $cart->items->count() . "\n";
}

// Tambahkan item ke cart
$product = $products->first();
echo "\n=== ADD TO CART ===\n";
echo "Menambahkan produk ID={$product->id} ({$product->name})\n";
$existing = $cart->items()->where('product_id', $product->id)->first();
if ($existing) {
    $existing->update(['quantity' => $existing->quantity + 1]);
    echo "Qty dinaikkan jadi: " . ($existing->quantity + 1) . "\n";
} else {
    $item = $cart->items()->create([
        'product_id' => $product->id,
        'quantity' => 1,
        'is_selected' => true,
    ]);
    echo "Item baru dibuat: ID={$item->id}\n";
}

// Test checkout summary
echo "\n=== CHECKOUT SUMMARY ===\n";
$selectedItems = $cart->items()->where('is_selected', true)->with('product')->get();
echo "Selected items: " . $selectedItems->count() . "\n";
$subtotal = $selectedItems->sum(fn($i) => $i->quantity * $i->product->effective_price);
$shippingCost = (int) \App\Models\Setting::get('shipping', 'cost', 0);
echo "Subtotal: Rp " . number_format($subtotal) . "\n";
echo "Shipping: Rp " . number_format($shippingCost) . "\n";
echo "Total: Rp " . number_format($subtotal + $shippingCost) . "\n";

echo "\n=== PAYMENT METHODS FROM SETTINGS ===\n";
$methods = \App\Models\Setting::get('payment', 'methods', []);
echo "Methods: " . json_encode($methods) . "\n";

echo "\n=== ADDRESSES FOR USER ===\n";
$addresses = $user->addresses()->get();
echo "Count: " . $addresses->count() . "\n";
foreach ($addresses as $a) {
    echo "ID={$a->id} | {$a->label} | {$a->recipient_name}\n";
}

echo "\n=== DONE ===\n";
