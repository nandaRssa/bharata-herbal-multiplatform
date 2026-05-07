<?php

require __DIR__ . '/../vendor/autoload.php';
$db = new PDO('sqlite:' . __DIR__ . '/../database/database.sqlite');
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$now = date('Y-m-d H:i:s');

$stmt = $db->prepare('INSERT OR IGNORE INTO users (name,email,email_verified_at,password,phone,role,remember_token,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,?)');
$stmt->execute([
    'Admin Bharata',
    'admin@bharata.local',
    $now,
    '$2y$12$dZ5y/mS6pRGXnsmY.UrtbOuu5jUo6CCcEAEtx9nSUWlLXyXTXOGrG',
    null,
    'admin',
    null,
    $now,
    $now,
]);

$categories = [
    ['Herbal', 'herbal'],
    ['Perawatan Tubuh', 'perawatan-tubuh'],
    ['Suplemen', 'suplemen'],
];
foreach ($categories as $cat) {
    $stmt = $db->prepare('INSERT OR IGNORE INTO categories (name,slug,description,icon,created_at,updated_at) VALUES (?,?,?,?,?,?)');
    $stmt->execute([$cat[0], $cat[1], null, null, $now, $now]);
}

$products = [
    [
        'name' => 'Minyak Herbal Terapi',
        'description' => 'Minyak herbal untuk perawatan tubuh dan relaksasi',
        'price' => 125000,
        'discount_price' => 110000,
        'stock' => 50,
        'image' => 'products/QFvyzJqmxiQYNTcBM00RbVPr8XVev1deyPggeMyV.jpg',
        'is_featured' => 1,
        'is_bestseller' => 1,
        'category' => 'Herbal',
    ],
    [
        'name' => 'Sabun Organik Mandi',
        'description' => 'Sabun alami lembut untuk membersihkan dan merawat kulit',
        'price' => 85000,
        'discount_price' => null,
        'stock' => 30,
        'image' => 'products/QFvyzJqmxiQYNTcBM00RbVPr8XVev1deyPggeMyV.jpg',
        'is_featured' => 0,
        'is_bestseller' => 1,
        'category' => 'Perawatan Tubuh',
    ],
    [
        'name' => 'Serbuk Kunyit Alami',
        'description' => 'Suplemen kunyit organik untuk kesehatan sehari-hari',
        'price' => 45000,
        'discount_price' => 40000,
        'stock' => 20,
        'image' => 'products/QFvyzJqmxiQYNTcBM00RbVPr8XVev1deyPggeMyV.jpg',
        'is_featured' => 0,
        'is_bestseller' => 0,
        'category' => 'Suplemen',
    ],
];

foreach ($products as $p) {
    $slug = strtolower(str_replace(' ', '-', $p['name']));
    $status = $p['stock'] > 0 ? 'active' : 'inactive';

    $stmt = $db->prepare('INSERT OR IGNORE INTO products (name,slug,description,usage,benefits,composition,price,discount_price,stock,image,is_featured,is_bestseller,rating,rating_count,status,sales_count,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)');
    $stmt->execute([
        $p['name'],
        $slug,
        $p['description'],
        null,
        null,
        null,
        $p['price'],
        $p['discount_price'],
        $p['stock'],
        $p['image'],
        $p['is_featured'],
        $p['is_bestseller'],
        0,
        0,
        $status,
        0,
        $now,
        $now,
    ]);

    $categoryId = $db->query("SELECT id FROM categories WHERE name = '" . addslashes($p['category']) . "'")->fetchColumn();
    $productId = $db->query("SELECT id FROM products WHERE slug = '" . addslashes($slug) . "'")->fetchColumn();
    if ($categoryId && $productId) {
        $db->exec("INSERT OR IGNORE INTO product_category (product_id, category_id) VALUES ($productId, $categoryId)");
    }
}

echo "seeded\n";
