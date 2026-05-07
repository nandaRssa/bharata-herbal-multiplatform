<?php
define('LARAVEL_ROOT', 'C:/xampp/htdocs/BharataHerbal_PABP/bhrata-herbal-mobile');
chdir(LARAVEL_ROOT);
require LARAVEL_ROOT . '/vendor/autoload.php';
$app = require LARAVEL_ROOT . '/bootstrap/app.php';
$app->make(\Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;
use App\Models\User;
use App\Models\Setting;

echo "=== SEEDING SETTINGS & DATA ===\n";

// 1. Payment methods
DB::table('settings')->updateOrInsert(
    ['group' => 'payment', 'key' => 'methods'],
    ['value' => json_encode(['transfer', 'cash_on_delivery']), 'updated_at' => now()]
);
echo "[OK] Payment methods: transfer, cash_on_delivery\n";

// 2. Shipping cost
DB::table('settings')->updateOrInsert(
    ['group' => 'shipping', 'key' => 'cost'],
    ['value' => '15000', 'updated_at' => now()]
);
echo "[OK] Shipping cost: Rp 15.000\n";

// 3. Minimum order
DB::table('settings')->updateOrInsert(
    ['group' => 'shipping', 'key' => 'minimum_order_amount'],
    ['value' => '0', 'updated_at' => now()]
);
echo "[OK] Minimum order: Rp 0 (disabled)\n";

// 4. Bank accounts
if (!DB::table('bank_accounts')->where('bank_name', 'BCA')->exists()) {
    DB::table('bank_accounts')->insert([
        'bank_name'      => 'BCA',
        'account_number' => '8001234567',
        'account_holder' => 'Bharata Herbal',
        'is_active'      => true,
        'created_at'     => now(),
        'updated_at'     => now(),
    ]);
    echo "[OK] Bank BCA: seeded\n";
} else {
    DB::table('bank_accounts')->where('bank_name', 'BCA')->update(['is_active' => true]);
    echo "[OK] Bank BCA: already exists\n";
}

if (!DB::table('bank_accounts')->where('bank_name', 'Mandiri')->exists()) {
    DB::table('bank_accounts')->insert([
        'bank_name'      => 'Mandiri',
        'account_number' => '1400098765432',
        'account_holder' => 'Bharata Herbal',
        'is_active'      => true,
        'created_at'     => now(),
        'updated_at'     => now(),
    ]);
    echo "[OK] Bank Mandiri: seeded\n";
}

// 5. Address untuk semua customer yang belum punya
$customers = User::where('role', 'customer')->get();
foreach ($customers as $user) {
    if ($user->addresses()->count() === 0) {
        $user->addresses()->create([
            'label'          => 'Rumah',
            'recipient_name' => $user->name,
            'phone'          => $user->phone ?? '08123456789',
            'street'         => 'Jl. Contoh No. 1, RT 01/RW 01',
            'city'           => 'Semarang',
            'province'       => 'Jawa Tengah',
            'postal_code'    => '50241',
            'is_default'     => true,
        ]);
        echo "[OK] Address seeded untuk: {$user->email}\n";
    } else {
        echo "[--] {$user->email} sudah punya " . $user->addresses()->count() . " alamat\n";
    }
}

echo "\n=== VERIFY ===\n";
$methods = Setting::get('payment', 'methods', []);
echo "Payment methods: " . implode(', ', $methods) . "\n";
echo "Shipping cost: Rp " . number_format((int)Setting::get('shipping', 'cost', 0)) . "\n";
$banks = DB::table('bank_accounts')->where('is_active', true)->get();
echo "Active banks: " . $banks->count() . "\n";
foreach ($banks as $b) {
    echo "  - {$b->bank_name} {$b->account_number} a.n. {$b->account_holder}\n";
}
echo "\nDONE - Sekarang coba checkout dari app!\n";
