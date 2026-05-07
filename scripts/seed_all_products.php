<?php

require __DIR__ . '/../vendor/autoload.php';
$db = new PDO('sqlite:' . __DIR__ . '/../database/database.sqlite');
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
$now = date('Y-m-d H:i:s');

// Product template data for 21 products across 3 categories
$productsData = [
    // Herbal Category (1-7)
    ['name' => 'Minyak Herbal Terapi', 'description' => 'Minyak herbal premium untuk perawatan tubuh dan relaksasi', 'price' => 125000, 'discount_price' => 110000, 'stock' => 50, 'image' => 'products/1.png', 'is_featured' => true, 'is_bestseller' => true, 'category' => 'Herbal'],
    ['name' => 'Teh Herbal Anti Inflamasi', 'description' => 'Teh herbal alami untuk mengurangi peradangan dan meningkatkan imunitas', 'price' => 45000, 'discount_price' => 40000, 'stock' => 60, 'image' => 'products/2.png', 'is_featured' => false, 'is_bestseller' => true, 'category' => 'Herbal'],
    ['name' => 'Aromaterapi Essential Oil', 'description' => 'Minyak esensial murni untuk aromaterapi dan relaksasi', 'price' => 95000, 'discount_price' => null, 'stock' => 35, 'image' => 'products/3.png', 'is_featured' => true, 'is_bestseller' => false, 'category' => 'Herbal'],
    ['name' => 'Herbal Cleanse Detox', 'description' => 'Ramuan herbal untuk membersihkan tubuh dan detoksifikasi', 'price' => 155000, 'discount_price' => 140000, 'stock' => 25, 'image' => 'products/4.png', 'is_featured' => false, 'is_bestseller' => false, 'category' => 'Herbal'],
    ['name' => 'Ekstrak Jahe Organik', 'description' => 'Ekstrak jahe murni untuk kesehatan pencernaan dan kehangatan tubuh', 'price' => 65000, 'discount_price' => 58000, 'stock' => 45, 'image' => 'products/5.png', 'is_featured' => false, 'is_bestseller' => true, 'category' => 'Herbal'],
    ['name' => 'Licorice Root Tea', 'description' => 'Teh akar licorice untuk kesehatan saluran napas dan pencernaan', 'price' => 55000, 'discount_price' => null, 'stock' => 40, 'image' => 'products/6.png', 'is_featured' => false, 'is_bestseller' => false, 'category' => 'Herbal'],
    ['name' => 'Herbal Sleeping Blend', 'description' => 'Campuran herbal untuk membantu tidur nyenyak dan istirahat berkualitas', 'price' => 85000, 'discount_price' => 75000, 'stock' => 30, 'image' => 'products/7.png', 'is_featured' => false, 'is_bestseller' => false, 'category' => 'Herbal'],
    
    // Perawatan Tubuh Category (8-14)
    ['name' => 'Sabun Organik Mandi', 'description' => 'Sabun alami lembut untuk membersihkan dan merawat kulit', 'price' => 85000, 'discount_price' => null, 'stock' => 30, 'image' => 'products/8.png', 'is_featured' => false, 'is_bestseller' => true, 'category' => 'Perawatan Tubuh'],
    ['name' => 'Body Lotion Alami', 'description' => 'Losion tubuh dengan bahan alami untuk kulit lembut dan halus', 'price' => 75000, 'discount_price' => 65000, 'stock' => 35, 'image' => 'products/9.png', 'is_featured' => true, 'is_bestseller' => true, 'category' => 'Perawatan Tubuh'],
    ['name' => 'Face Cream Herbal', 'description' => 'Krim wajah dengan ekstrak herbal untuk kulit bercahaya dan sehat', 'price' => 145000, 'discount_price' => 130000, 'stock' => 20, 'image' => 'products/10.png', 'is_featured' => false, 'is_bestseller' => false, 'category' => 'Perawatan Tubuh'],
    ['name' => 'Serum Anti Aging Natural', 'description' => 'Serum alami untuk melawan tanda-tanda penuaan dan menjaga elastisitas kulit', 'price' => 175000, 'discount_price' => 155000, 'stock' => 15, 'image' => 'products/11.png', 'is_featured' => true, 'is_bestseller' => false, 'category' => 'Perawatan Tubuh'],
    ['name' => 'Shampoo Herbal Organik', 'description' => 'Sampo alami untuk rambut sehat, kuat, dan berkilau', 'price' => 65000, 'discount_price' => 58000, 'stock' => 40, 'image' => 'products/12.png', 'is_featured' => false, 'is_bestseller' => true, 'category' => 'Perawatan Tubuh'],
    ['name' => 'Conditioner Pelembut Rambut', 'description' => 'Kondisioner untuk melembutkan dan mengharumkan rambut secara alami', 'price' => 55000, 'discount_price' => null, 'stock' => 38, 'image' => 'products/13.png', 'is_featured' => false, 'is_bestseller' => false, 'category' => 'Perawatan Tubuh'],
    ['name' => 'Scrub Body Natural', 'description' => 'Scrub tubuh dengan bahan alami untuk mengangkat sel kulit mati', 'price' => 95000, 'discount_price' => 85000, 'stock' => 28, 'image' => 'products/14.png', 'is_featured' => false, 'is_bestseller' => false, 'category' => 'Perawatan Tubuh'],
    
    // Suplemen Category (15-21)
    ['name' => 'Serbuk Kunyit Alami', 'description' => 'Suplemen kunyit organik untuk kesehatan sehari-hari dan anti inflamasi', 'price' => 45000, 'discount_price' => 40000, 'stock' => 20, 'image' => 'products/15.png', 'is_featured' => false, 'is_bestseller' => false, 'category' => 'Suplemen'],
    ['name' => 'Vitamin C Alami', 'description' => 'Vitamin C dari buah-buahan alami untuk meningkatkan imunitas', 'price' => 125000, 'discount_price' => 110000, 'stock' => 32, 'image' => 'products/16.png', 'is_featured' => true, 'is_bestseller' => true, 'category' => 'Suplemen'],
    ['name' => 'Zinc Supplement Premium', 'description' => 'Suplemen zinc alami untuk kesehatan kulit dan imunitas tubuh', 'price' => 95000, 'discount_price' => 85000, 'stock' => 25, 'image' => 'products/17.png', 'is_featured' => false, 'is_bestseller' => false, 'category' => 'Suplemen'],
    ['name' => 'Collagen Peptide Drink', 'description' => 'Minuman kolagen untuk kesehatan kulit, rambut, dan sendi', 'price' => 165000, 'discount_price' => 150000, 'stock' => 18, 'image' => 'products/18.png', 'is_featured' => true, 'is_bestseller' => true, 'category' => 'Suplemen'],
    ['name' => 'Omega 3 Fish Oil', 'description' => 'Minyak ikan omega 3 untuk kesehatan jantung dan otak', 'price' => 135000, 'discount_price' => 120000, 'stock' => 28, 'image' => 'products/19.png', 'is_featured' => false, 'is_bestseller' => false, 'category' => 'Suplemen'],
    ['name' => 'Probiotics Powder', 'description' => 'Bubuk probiotik untuk kesehatan pencernaan dan flora usus', 'price' => 105000, 'discount_price' => 95000, 'stock' => 22, 'image' => 'products/20.png', 'is_featured' => false, 'is_bestseller' => true, 'category' => 'Suplemen'],
    ['name' => 'Multivitamin Gummy', 'description' => 'Gummy multivitamin lezat untuk kesehatan keluarga', 'price' => 75000, 'discount_price' => 68000, 'stock' => 50, 'image' => 'products/21.png', 'is_featured' => false, 'is_bestseller' => false, 'category' => 'Suplemen'],
];

foreach ($productsData as $p) {
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
        $p['is_featured'] ? 1 : 0,
        $p['is_bestseller'] ? 1 : 0,
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

echo "✅ Successfully added 21 products to the database!\n";
echo "Products are now visible in the storefront and admin dashboard.\n";
