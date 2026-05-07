<?php

require __DIR__ . '/../vendor/autoload.php';
$db = new PDO('sqlite:' . __DIR__ . '/../database/database.sqlite');
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$totalCount = $db->query('SELECT count(*) FROM products')->fetchColumn();
echo "✅ Total Products: " . $totalCount . "\n\n";

echo "Products by Category:\n";
$categories = ['Herbal', 'Perawatan Tubuh', 'Suplemen'];
foreach ($categories as $catName) {
    $count = $db->query("SELECT count(*) FROM products p JOIN product_category pc ON p.id = pc.product_id JOIN categories c ON pc.category_id = c.id WHERE c.name = '" . addslashes($catName) . "'")->fetchColumn();
    echo "- " . $catName . ": " . $count . " products\n";
}

echo "\nSample Featured Products:\n";
$featured = $db->query('SELECT name, price, discount_price, image FROM products WHERE is_featured = 1 LIMIT 5');
while ($row = $featured->fetch(PDO::FETCH_ASSOC)) {
    $price = $row['discount_price'] ?? $row['price'];
    echo "- " . $row['name'] . " (Rp " . number_format($price, 0, ',', '.') . ")\n";
}

echo "\nTop Bestsellers:\n";
$bestsellers = $db->query('SELECT name, price, discount_price FROM products WHERE is_bestseller = 1 LIMIT 5');
while ($row = $bestsellers->fetch(PDO::FETCH_ASSOC)) {
    $price = $row['discount_price'] ?? $row['price'];
    echo "- " . $row['name'] . " (Rp " . number_format($price, 0, ',', '.') . ")\n";
}
