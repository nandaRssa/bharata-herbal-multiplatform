<!-- DRAG & DROP FILE UPLOAD FEATURE DOCUMENTATION -->

## Fitur Drag & Drop Upload Gambar Produk

### 📋 Overview
Telah diimplementasikan fitur drag & drop upload untuk gambar produk di halaman Tambah Produk dan Edit Produk.

### ✨ Fitur-Fitur

#### 1. **Drag & Drop Support**
- Area upload menampilkan visual "Seret gambar ke sini"
- Saat file di-drag ke area, tampil feedback "Lepaskan file di sini" dengan animasi
- Area upload berubah warna menjadi hijau saat drag over

#### 2. **Click Upload (Fallback)**
- Tetap support klik biasa untuk memilih file
- Kompatibel dengan semua browser

#### 3. **File Preview**
- Setelah file dipilih/di-drop, tampil preview gambar ukuran 160x160px
- Preview menampilkan:
  - Thumbnail gambar
  - Nama file di bagian bawah
  - Tombol close (X) untuk menghapus pilihan
- Preview responsive dan cantik

#### 4. **Validasi File**
- ✅ Hanya terima file gambar: JPG, JPEG, PNG, WebP
- ✅ Maksimal ukuran: 2MB
- ❌ Tampil pesan error jika file tidak valid
- ❌ Tampil ukuran aktual file jika terlalu besar

#### 5. **Current Image Display**
- Halaman Edit Produk menampilkan gambar saat ini
- User dapat mengganti gambar dengan upload baru
- Teks helper: "Gambar saat ini. Upload baru untuk mengganti."

#### 6. **Form Integration**
- File input tersembunyi (hidden) untuk submit form
- Kompatibel dengan Laravel form submission
- Bekerja dengan enctype="multipart/form-data"

### 🎨 Visual States

#### Default State
```
┌────────────────────────────┐
│  📤 Seret gambar ke sini  │
│  atau klik untuk memilih file│
│  Maksimal 2MB • JPG, PNG, WebP
└────────────────────────────┘
```

#### Dragging State
```
┌────────────────────────────┐
│  ↓  ↓  ↓  ↓  ↓  ↓  ↓  ↓  │
│  Lepaskan file di sini    │
│  ↑  ↑  ↑  ↑  ↑  ↑  ↑  ↑  │
└────────────────────────────┘
(dengan background hijau herbal)
```

#### Preview State
```
┌──────────┐
│          │
│ Preview │ X
│  Image  │
├──────────┤
│ filename │
└──────────┘
```

### 🛠️ Implementasi Teknis

#### Component: `drag-drop-upload.blade.php`
```php
<x-forms.drag-drop-upload 
    name="image"                    // Nama field form
    label="Gambar Produk"          // Label di atas upload area
    accept="image/*"               // Accept attribute
    maxSize="2048"                 // Max size dalam KB (default 2MB)
    :currentImage="$imageUrl"      // URL gambar saat ini (opsional)
/>
```

#### Usage di Create/Edit Product
```php
@php
    $currentImageUrl = null;
    if (isset($product) && $product->image) {
        $currentImageUrl = \Illuminate\Support\Facades\Storage::url($product->image);
    }
@endphp

<x-forms.drag-drop-upload 
    name="image" 
    label="Gambar Produk"
    accept="image/*"
    maxSize="2048"
    :currentImage="$currentImageUrl"
/>
```

### 📂 File Structure

**Component:**
- `resources/views/components/forms/drag-drop-upload.blade.php`

**Views Using Component:**
- `resources/views/admin/products/create.blade.php` (untuk create & edit)
- `resources/views/admin/products/edit.blade.php` (include create)

### 🔧 Validasi & Error Handling

#### Client-Side Validation
```javascript
// Check file type
if (!allowedTypes.includes(file.type)) {
    alert('❌ Hanya file gambar (JPG, PNG, WebP) yang diterima.');
}

// Check file size
if (file.size > maxSize) {
    alert(`❌ Ukuran file terlalu besar. Maksimal 2MB, file Anda ${size}MB`);
}
```

#### Server-Side Validation (Laravel)
Tetap gunakan validasi Laravel di controller:
```php
$validated = $request->validate([
    'image' => 'nullable|image|mimes:jpeg,png,webp|max:2048',
]);
```

### 🌍 Browser Compatibility

✅ Chrome/Edge 13+
✅ Firefox 9+
✅ Safari 5+
✅ Opera 12+
✅ Mobile browsers (dengan drag & drop support)

### 💡 Tips Penggunaan

1. **Untuk Edit Produk**: Gambar saat ini ditampilkan di atas area upload
2. **Untuk Hapus Gambar**: Tekan tombol X pada preview
3. **Multiple Products**: Component reusable untuk field image lainnya
4. **Custom Size**: Ubah `maxSize="2048"` untuk maksimal size berbeda

### 🎯 Fitur Bonus

- ✨ Animasi smooth saat drag over
- 🎬 Bounce animation pada dragging state
- 🖼️ Gradient overlay pada preview
- 🎨 Tailwind CSS styling
- 🚀 Optimized untuk mobile

### 📝 Testing Checklist

- [ ] Drag file gambar ke area upload
- [ ] Tampil preview setelah drag
- [ ] Click area upload untuk file picker
- [ ] Validasi: reject file non-image
- [ ] Validasi: reject file > 2MB
- [ ] Click X untuk hapus preview
- [ ] Edit produk dengan gambar existing
- [ ] Submit form dengan gambar baru
- [ ] Check database untuk file tersimpan
