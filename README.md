# BHARATA HERBAL
### Sistem E-Commerce Multiplatform Produk Herbal

Bharata Herbal merupakan aplikasi e-commerce produk herbal yang dikembangkan menggunakan Laravel sebagai backend utama dan Flutter sebagai aplikasi mobile customer. Sistem ini dibuat dengan konsep multiplatform, yaitu satu backend digunakan bersama oleh aplikasi web dan mobile.

---

# Gambaran Umum

Aplikasi ini terdiri dari:

- **Web Admin (Laravel Blade + Tailwind CSS)**  
  Digunakan admin untuk mengelola produk, kategori, pesanan, pembayaran, laporan, voucher, dan pengaturan toko.

- **Mobile App Customer (Flutter)**  
  Digunakan customer untuk melihat produk, checkout, upload bukti pembayaran, memberi ulasan, dan menerima notifikasi pesanan.

Kedua platform menggunakan satu backend Laravel yang sama melalui REST API dan database terpusat.

---

# Arsitektur Sistem

```text
Flutter Mobile App
        │
        │ REST API + JSON
        ▼
Laravel Backend (API & Web)
        │
        ├── MySQL Database
        ├── Storage Gambar
        ├── Firebase Notification
        └── Web Push Notification
```

Backend Laravel berfungsi sebagai pusat autentikasi, pengelolaan data, validasi sistem, transaksi, dan pengiriman notifikasi.

---

# Fitur Utama

## Customer Mobile
- Register dan login
- Melihat katalog produk herbal
- Keranjang belanja dan checkout
- Upload bukti pembayaran
- Tracking status pesanan
- Review dan rating produk
- GPS auto-fill alamat
- Push notification status pesanan

## Admin Web
- Dashboard admin
- CRUD produk dan kategori
- Manajemen stok
- Verifikasi pembayaran
- Manajemen pesanan
- Laporan penjualan
- Pengaturan toko
- Web Push Notification
- PWA installable

---

# Platform-Specific Features

## Mobile Features
- GPS Auto Address menggunakan `geolocator`
- Upload Kamera dan Galeri menggunakan `image_picker`
- Push Notification menggunakan Firebase Cloud Messaging

## Web Features
- PWA (Progressive Web App)
- Web Push Notification
- Drag and Drop Upload

---

# Teknologi yang Digunakan

## Backend
- Laravel 11
- PHP 8.2
- MySQL
- Laravel Sanctum
- Eloquent ORM

## Frontend Web
- Blade Template Engine
- Tailwind CSS
- Alpine.js
- Vite

## Mobile
- Flutter
- Provider
- Dio HTTP Client
- Firebase Messaging
- Shared Preferences

---

# Sistem Autentikasi

- Mobile menggunakan Laravel Sanctum Token Authentication
- Web admin menggunakan Session Authentication
- Role pengguna terdiri dari:
  - Customer
  - Admin
  - Super Admin

---

# Fitur Otomatisasi

- Auto update rating produk dari review
- Auto update jumlah penjualan produk
- Auto cancel pesanan expired
- Auto status stok produk
- Notifikasi stok menipis

---

# Struktur Project

```text
bharata-herbal/
├── Backend Laravel
│   ├── routes
│   ├── app
│   ├── resources/views
│   └── database
│
└── Mobile Flutter
    ├── lib/screens
    ├── lib/services
    ├── lib/providers
    └── lib/models
```

---

# Cara Menjalankan Project

## Backend Laravel

```bash
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed
npm install
npm run dev
php artisan serve
```

## Mobile Flutter

```bash
flutter pub get
flutter run
```

---

# Akun Demo

| Role | Email | Password |
|---|---|---|
| Admin | admin@bharataherbal.id | password |
| Customer | customer@example.com | password |

---

# Penutup

Bharata Herbal dibuat sebagai implementasi aplikasi multiplatform dengan satu backend bersama. Project ini memanfaatkan fitur khas masing-masing platform seperti GPS, kamera, push notification, PWA, dan Web Push Notification untuk memberikan pengalaman pengguna yang lebih baik.

---

*Dikembangkan untuk Tugas Besar Mata Kuliah Pengembangan Aplikasi Berbasis Platform*
