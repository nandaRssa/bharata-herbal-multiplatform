<?php
$file = 'database/seeders/ProductReplaceSeeder.php';
$content = file_get_contents($file);

// Update name and slug
$content = preg_replace("/'name'\s*=>\s*'([A-Z\s\-]+) BHARATA'/", "'name'          => '$1 BHRATA'", $content);
$content = preg_replace("/'slug'\s*=>\s*'([a-z\-]+)-bharata'/", "'slug'          => '$1-bhrata'", $content);

// The slugs are now -bhrata. Let's find all the new slugs and replace the corresponding image path.
$lines = explode("\n", $content);
$currentSlug = '';

foreach ($lines as &$line) {
    if (preg_match("/'slug'\s*=>\s*'([^']+)'/", $line, $matches)) {
        $currentSlug = $matches[1]; // e.g. prefilax-bhrata
    }
    
    if (preg_match("/'image'\s*=>\s*'products\/\d+\.png'/", $line)) {
        if ($currentSlug) {
            $line = "                'image'         => 'products/{$currentSlug}.png',";
            $currentSlug = ''; // Reset for safety
        }
    }
}

$newContent = implode("\n", $lines);
file_put_contents($file, $newContent);

echo "Seeder updated successfully.\n";
