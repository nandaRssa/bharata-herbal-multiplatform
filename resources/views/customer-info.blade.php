<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Unduh Aplikasi Mobile - {{ $storeName }}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
            background: linear-gradient(135deg, #2d5016 0%, #4a7c2c 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .container {
            max-width: 600px;
            background: white;
            border-radius: 16px;
            box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
            overflow: hidden;
        }

        .header {
            background: linear-gradient(135deg, #2d5016 0%, #4a7c2c 100%);
            color: white;
            padding: 60px 40px 40px;
            text-align: center;
        }

        .logo {
            font-size: 48px;
            margin-bottom: 20px;
        }

        .header h1 {
            font-size: 28px;
            margin-bottom: 10px;
            font-weight: 600;
        }

        .header p {
            font-size: 16px;
            opacity: 0.9;
            line-height: 1.5;
        }

        .content {
            padding: 40px;
        }

        .message-box {
            background: #f0f9ff;
            border-left: 4px solid #2d5016;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
        }

        .message-box h2 {
            color: #2d5016;
            font-size: 18px;
            margin-bottom: 10px;
        }

        .message-box p {
            color: #1e3a0f;
            line-height: 1.6;
            font-size: 14px;
        }

        .features {
            margin: 30px 0;
        }

        .features h3 {
            color: #2d5016;
            font-size: 16px;
            margin-bottom: 15px;
        }

        .feature-list {
            list-style: none;
        }

        .feature-list li {
            display: flex;
            align-items: flex-start;
            margin-bottom: 12px;
            color: #374151;
            font-size: 14px;
        }

        .feature-list li:before {
            content: "✓";
            color: #4a7c2c;
            font-weight: bold;
            margin-right: 12px;
            font-size: 18px;
        }

        .download-section {
            margin: 30px 0;
            padding: 20px;
            background: #f9fafb;
            border-radius: 8px;
            text-align: center;
        }

        .download-section h3 {
            color: #2d5016;
            margin-bottom: 15px;
            font-size: 16px;
        }

        .download-links {
            display: flex;
            gap: 15px;
            justify-content: center;
            flex-wrap: wrap;
        }

        .download-link {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 12px 24px;
            background: white;
            border: 2px solid #2d5016;
            color: #2d5016;
            text-decoration: none;
            border-radius: 8px;
            font-weight: 600;
            transition: all 0.3s ease;
            font-size: 14px;
        }

        .download-link:hover {
            background: #2d5016;
            color: white;
            transform: translateY(-2px);
            box-shadow: 0 8px 16px rgba(45, 80, 22, 0.3);
        }

        .download-link.primary {
            background: #2d5016;
            color: white;
            border-color: #2d5016;
        }

        .download-link.primary:hover {
            background: #1e3a0f;
            border-color: #1e3a0f;
        }

        .contact-section {
            margin-top: 30px;
            padding-top: 30px;
            border-top: 1px solid #e5e7eb;
        }

        .contact-section h3 {
            color: #2d5016;
            font-size: 14px;
            margin-bottom: 12px;
        }

        .contact-info {
            display: flex;
            flex-direction: column;
            gap: 8px;
            font-size: 14px;
            color: #6b7280;
        }

        .contact-info a {
            color: #2d5016;
            text-decoration: none;
        }

        .contact-info a:hover {
            text-decoration: underline;
        }

        .admin-link {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #e5e7eb;
        }

        .admin-link a {
            font-size: 12px;
            color: #9ca3af;
            text-decoration: none;
            transition: color 0.3s ease;
        }

        .admin-link a:hover {
            color: #2d5016;
        }

        @media (max-width: 600px) {
            .header {
                padding: 40px 25px 25px;
            }

            .header h1 {
                font-size: 24px;
            }

            .header p {
                font-size: 14px;
            }

            .content {
                padding: 25px;
            }

            .download-links {
                flex-direction: column;
            }

            .download-link {
                width: 100%;
                justify-content: center;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <img src="{{ asset('/foto bharata/logo-bharata.jpg') }}" alt="Logo Bharata Herbal" style="width: 100px; height: 100px; object-fit: cover; border-radius: 20px; margin-bottom: 20px; box-shadow: 0 10px 25px rgba(0,0,0,0.2); border: 3px solid rgba(255,255,255,0.2);">
            <h1>{{ $storeName }}</h1>
            <p>Belanja produk herbal alami berkualitas tinggi</p>
        </div>

        <div class="content">
            <div class="message-box">
                <h2>📱 Layanan Pelanggan Pindah ke Aplikasi Mobile</h2>
                <p>
                    Untuk pengalaman berbelanja yang lebih baik dan mudah, kami menghadirkan aplikasi mobile khusus untuk pelanggan setia {{ $storeName }}.
                </p>
            </div>

            <div class="features">
                <h3>Keuntungan Aplikasi Mobile:</h3>
                <ul class="feature-list">
                    <li>Belanja dengan mudah kapan saja, di mana saja</li>
                    <li>Notifikasi real-time untuk status pesanan Anda</li>
                    <li>Akses riwayat pembelian dengan lengkap</li>
                    <li>Promo dan diskon eksklusif untuk pengguna aplikasi</li>
                    <li>Interface yang dioptimalkan untuk mobile</li>
                    <li>Pembayaran yang aman dan cepat</li>
                </ul>
            </div>

            <div class="download-section">
                <h3>Unduh Aplikasi Sekarang</h3>
                <div class="download-links">
                    <a href="#" class="download-link primary">
                        📱 App Store (iOS)
                    </a>
                    <a href="#" class="download-link primary">
                        🤖 Google Play (Android)
                    </a>
                </div>
                <p style="font-size: 12px; color: #9ca3af; margin-top: 12px;">
                    (Link akan diperbarui segera)
                </p>
            </div>

            <div class="contact-section">
                <h3>Butuh Bantuan?</h3>
                <div class="contact-info">
                    @if($storePhone)
                        <span>📞 Telepon: <a href="tel:{{ $storePhone }}">{{ $storePhone }}</a></span>
                    @endif
                    @if($storeEmail)
                        <span>📧 Email: <a href="mailto:{{ $storeEmail }}">{{ $storeEmail }}</a></span>
                    @endif
                    <span>⏰ Layanan pelanggan: 08:00 - 17:00 WIB (Senin-Jumat)</span>
                </div>
            </div>

            <div class="admin-link">
                <a href="{{ route('admin.dashboard') }}">Admin Panel</a>
            </div>
        </div>
    </div>
</body>
</html>
