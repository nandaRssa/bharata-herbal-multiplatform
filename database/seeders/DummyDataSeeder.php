<?php

namespace Database\Seeders;

use App\Models\Address;
use App\Models\Category;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\Payment;
use App\Models\Product;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DummyDataSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        echo "\n🟢 [DUMMY DATA SEEDER] Memulai import data dummy...\n";

        $customers = $this->createDummyCustomers();
        echo "✅ {$customers->count()} pelanggan berhasil dibuat/diperbarui\n";

        $products = $this->createDummyProducts();
        echo "✅ {$products->count()} produk berhasil dibuat/diperbarui\n";

        $addresses = $this->createDummyAddresses($customers);
        echo "✅ {$addresses->count()} alamat pengiriman berhasil dibuat\n";

        $this->createDummyOrders($customers, $products, $addresses);
        echo "✅ 15 pesanan berhasil dibuat\n";

        echo "\n🟢 [DUMMY DATA SEEDER] Selesai! Data dummy siap untuk testing admin panel.\n";
    }

    /**
     * Create 10 dummy customer accounts
     */
    private function createDummyCustomers()
    {
        $customers = collect([
            ['name' => 'Agus Pratama', 'email' => 'agus.pratama@test.com', 'phone' => '081234567890'],
            ['name' => 'Siti Nurhaliza', 'email' => 'siti.nurhaliza@test.com', 'phone' => '082345678901'],
            ['name' => 'Budi Santoso', 'email' => 'budi.santoso@test.com', 'phone' => '083456789012'],
            ['name' => 'Dewi Kusuma', 'email' => 'dewi.kusuma@test.com', 'phone' => '084567890123'],
            ['name' => 'Rini Rahmawati', 'email' => 'rini.rahmawati@test.com', 'phone' => '085678901234'],
            ['name' => 'Hendra Wijaya', 'email' => 'hendra.wijaya@test.com', 'phone' => '086789012345'],
            ['name' => 'Ayu Lestari', 'email' => 'ayu.lestari@test.com', 'phone' => '087890123456'],
            ['name' => 'Joko Widodo', 'email' => 'joko.widodo@test.com', 'phone' => '088901234567'],
            ['name' => 'Maya Putri', 'email' => 'maya.putri@test.com', 'phone' => '089012345678'],
            ['name' => 'Andi Gunawan', 'email' => 'andi.gunawan@test.com', 'phone' => '080123456789'],
        ]);

        return $customers->map(function ($data) {
            $randomDate = Carbon::now()->subDays(rand(0, 90));

            return User::firstOrCreate(
                ['email' => $data['email']],
                [
                    'name' => $data['name'],
                    'phone' => $data['phone'],
                    'password' => Hash::make('password123'),
                    'role' => 'customer',
                    'created_at' => $randomDate,
                ]
            );
        });
    }

    /**
     * Create 10 dummy herbal products
     */
    private function createDummyProducts()
    {
        $categories = Category::pluck('id', 'name');

        $products = collect([
            ['name' => 'Jamu Kunyit Asam', 'category' => 'Jamu', 'price' => 25000, 'discount' => 0, 'stock' => 50],
            ['name' => 'Teh Jahe Merah Premium', 'category' => 'Teh Herbal', 'price' => 35000, 'discount' => 5000, 'stock' => 8],
            ['name' => 'Suplemen Minyak Ikan', 'category' => 'Suplemen', 'price' => 75000, 'discount' => 0, 'stock' => 120],
            ['name' => 'Daun Sirsak Kering', 'category' => 'Teh Herbal', 'price' => 30000, 'discount' => 0, 'stock' => 0],
            ['name' => 'Empon-empon Mix Organik', 'category' => 'Jamu', 'price' => 40000, 'discount' => 10000, 'stock' => 35],
            ['name' => 'Pil Stamina Kuat', 'category' => 'Suplemen', 'price' => 150000, 'discount' => 0, 'stock' => 3],
            ['name' => 'Madu Murni Hutan', 'category' => 'Produk Lebah', 'price' => 125000, 'discount' => 15000, 'stock' => 12],
            ['name' => 'Propolis Extract Premium', 'category' => 'Produk Lebah', 'price' => 200000, 'discount' => 0, 'stock' => 6],
            ['name' => 'Paste Kunyit Kasmaran', 'category' => 'Jamu', 'price' => 45000, 'discount' => 7000, 'stock' => 25],
            ['name' => 'Ramuan Ampuh Pegal Linu', 'category' => 'Jamu', 'price' => 50000, 'discount' => 0, 'stock' => 42],
        ]);

        return $products->map(function ($data) use ($categories) {
            $categoriesArray = Category::pluck('id')->toArray();
            $randomCategory = $categoriesArray ? $categoriesArray[array_rand($categoriesArray)] : null;

            $product = Product::firstOrCreate(
                ['name' => $data['name']],
                [
                    'description' => "Produk herbal premium berkualitas tinggi untuk kesehatan optimal.",
                    'usage' => "Konsumsi 1-2 kali sehari sesuai kebutuhan.",
                    'benefits' => "Meningkatkan kesehatan dan daya tahan tubuh",
                    'composition' => "Bahan-bahan alami pilihan",
                    'price' => $data['price'],
                    'discount_price' => $data['discount'] > 0 ? $data['price'] - $data['discount'] : null,
                    'stock' => $data['stock'],
                    'is_featured' => rand(0, 1) === 1,
                    'is_bestseller' => rand(0, 1) === 1,
                    'rating' => rand(3, 5),
                    'rating_count' => rand(5, 100),
                    'sales_count' => rand(10, 500),
                ]
            );

            // Attach category
            if ($categoriesArray) {
                $product->categories()->syncWithoutDetaching([$randomCategory]);
            }

            return $product;
        });
    }

    /**
     * Create dummy addresses for customers
     */
    private function createDummyAddresses($customers)
    {
        $cities = ['Jakarta Pusat', 'Jakarta Selatan', 'Bandung', 'Surabaya', 'Medan', 'Makassar'];
        $provinces = ['DKI Jakarta', 'Jawa Barat', 'Jawa Timur', 'Sumatera Utara', 'Sulawesi Selatan'];
        $addresses = collect();

        foreach ($customers as $customer) {
            $city = $cities[array_rand($cities)];
            $province = $provinces[array_rand($provinces)];

            $address = Address::firstOrCreate(
                [
                    'user_id' => $customer->id,
                    'label' => 'Rumah',
                ],
                [
                    'recipient_name' => $customer->name,
                    'phone' => $customer->phone,
                    'street' => 'Jl. ' . fake()->streetName() . ' No. ' . rand(1, 999),
                    'city' => $city,
                    'province' => $province,
                    'postal_code' => rand(10000, 99999),
                    'is_default' => true,
                ]
            );

            $addresses->push($address);
        }

        return $addresses;
    }

    /**
     * Create dummy orders
     */
    private function createDummyOrders($customers, $products, $addresses)
    {
        $statuses = ['pending', 'paid', 'processing', 'shipped', 'completed', 'cancelled'];
        $methods = ['cod', 'ewallet', 'bank_transfer'];
        $couriers = ['JNE', 'J&T Express', 'SiCepat', 'Pos Indonesia'];

        // Create 15 dummy orders
        for ($i = 0; $i < 15; $i++) {
            $customer = $customers->random();
            $address = $addresses->where('user_id', $customer->id)->first() ?? $addresses->random();
            $status = $statuses[array_rand($statuses)];
            $randomDate = Carbon::now()->subDays(rand(0, 45));

            // Pick 1-3 random products
            $orderProducts = $products->random(rand(1, 3));
            $subtotal = 0;
            $shippingCost = rand(10000, 50000);

            $order = Order::create([
                'user_id' => $customer->id,
                'address_id' => $address->id,
                'status' => $status,
                'subtotal' => 0,
                'shipping_cost' => $shippingCost,
                'total_price' => 0,
                'notes' => rand(0, 1) === 1 ? 'Pesanan penting, mohon hati-hati.' : null,
                'tracking_number' => $status !== 'cancelled' ? 'DUMMY' . rand(100000, 999999) : null,
                'courier_name' => in_array($status, ['shipped', 'completed']) ? $couriers[array_rand($couriers)] : null,
                'estimated_delivery_at' => in_array($status, ['shipped', 'completed']) ? Carbon::now()->addDays(rand(1, 7)) : null,
                'created_at' => $randomDate,
                'updated_at' => $randomDate,
            ]);

            // Add order items
            foreach ($orderProducts as $product) {
                $quantity = rand(1, 3);
                $price = $product->discount_price ?? $product->price;
                $itemSubtotal = $price * $quantity;
                $subtotal += $itemSubtotal;

                OrderItem::create([
                    'order_id' => $order->id,
                    'product_id' => $product->id,
                    'quantity' => $quantity,
                    'price' => $price,
                    'status' => 'pending',
                ]);
            }

            // Update order totals
            $totalPrice = $subtotal + $shippingCost;
            $order->update([
                'subtotal' => $subtotal,
                'shipping_cost' => $shippingCost,
                'total_price' => $totalPrice,
            ]);

            // Create payment record
            $paymentStatus = 'pending';
            if ($status === 'pending') {
                $paymentStatus = 'pending';
            } elseif (in_array($status, ['paid', 'processing', 'shipped', 'completed'])) {
                $paymentStatus = 'verified';
            } elseif ($status === 'cancelled') {
                $paymentStatus = 'failed';
            }

            Payment::create([
                'order_id' => $order->id,
                'method' => $methods[array_rand($methods)],
                'status' => $paymentStatus,
                'account_name' => 'Dummy Account ' . rand(1, 999),
                'account_number' => 'ACC' . rand(10000000, 99999999),
                'paid_at' => in_array($paymentStatus, ['verified']) ? $randomDate->copy()->addHours(2) : null,
                'payment_deadline' => $randomDate->copy()->addHours(2),
            ]);
        }
    }
}
