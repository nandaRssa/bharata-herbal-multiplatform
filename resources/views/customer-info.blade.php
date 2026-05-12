<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Informasi Pelanggan - {{ $storeName }}</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: linear-gradient(135deg, #0f2f1f 0%, #071d13 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }

        .container {
            max-width: 500px;
            width: 100%;
            background: white;
            border-radius: 24px;
            box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
            overflow: hidden;
            animation: fadeIn 0.6s ease-out;
        }

        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }

        .header {
            background: linear-gradient(to bottom, #0f2f1f, #1a4d33);
            color: white;
            padding: 50px 40px;
            text-align: center;
            position: relative;
        }

        .header img {
            width: 90px;
            height: 90px;
            object-fit: cover;
            border-radius: 22px;
            margin-bottom: 20px;
            box-shadow: 0 10px 20px rgba(0,0,0,0.3);
            border: 2px solid rgba(255,255,255,0.2);
        }

        .header h1 {
            font-size: 24px;
            margin-bottom: 8px;
            font-weight: 700;
            letter-spacing: -0.025em;
        }

        .header p {
            font-size: 15px;
            color: rgba(255, 255, 255, 0.8);
            line-height: 1.5;
        }

        .content {
            padding: 40px;
        }

        .info-card {
            background: #f8fafc;
            border: 1px solid #e2e8f0;
            padding: 24px;
            border-radius: 16px;
            margin-bottom: 30px;
        }

        .info-card p {
            color: #475569;
            line-height: 1.6;
            font-size: 15px;
            text-align: center;
        }

        .back-login-btn {
            display: inline-flex;
            align-items: center;
            gap: 10px;
            padding: 16px 32px;
            background: #16a34a;
            color: white;
            text-decoration: none;
            border-radius: 14px;
            font-weight: 600;
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
            font-size: 15px;
            border: none;
            cursor: pointer;
            width: 100%;
            justify-content: center;
            box-shadow: 0 4px 12px rgba(22, 163, 74, 0.2);
        }

        .back-login-btn:hover {
            background: #15803d;
            transform: translateY(-2px);
            box-shadow: 0 8px 20px rgba(22, 163, 74, 0.3);
        }

        .back-login-btn:active {
            transform: translateY(0);
        }

        .contact-section {
            margin-top: 30px;
            padding-top: 25px;
            border-top: 1px solid #f1f5f9;
        }

        .contact-section h3 {
            color: #0f2f1f;
            font-size: 14px;
            font-weight: 600;
            margin-bottom: 15px;
            text-transform: uppercase;
            letter-spacing: 0.05em;
            text-align: center;
        }

        .contact-info {
            display: flex;
            flex-direction: column;
            gap: 12px;
            font-size: 14px;
            color: #64748b;
        }

        .contact-item {
            display: flex;
            align-items: center;
            gap: 10px;
            padding: 10px 14px;
            background: #f1f5f9;
            border-radius: 10px;
            text-decoration: none;
            color: #475569;
            transition: all 0.2s;
        }

        .contact-item:hover {
            background: #e2e8f0;
            color: #0f2f1f;
        }

        .contact-item svg {
            width: 18px;
            height: 18px;
            color: #16a34a;
        }

        @media (max-width: 480px) {
            .header { padding: 40px 20px; }
            .content { padding: 30px 20px; }
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <img src="{{ asset('/images/logo bharata.png') }}" alt="Logo Bharata Herbal">
            <h1>{{ $storeName }}</h1>
            <p>Pusat Produk Herbal Berkualitas</p>
        </div>

        <div class="content">
            <div class="info-card">
                <p>Silakan gunakan <strong>Aplikasi Mobile</strong> kami untuk pengalaman belanja yang lebih lengkap dan fitur notifikasi real-time.</p>
            </div>

            @auth
                <form method="POST" action="{{ route('logout') }}" id="logout-form">
                    @csrf
                    <button type="submit" class="back-login-btn">
                        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
                        Keluar & Kembali ke Login
                    </button>
                </form>
            @else
                <a href="{{ route('login') }}" class="back-login-btn">
                    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4"></path><polyline points="10 17 5 12 10 7"></polyline><line x1="15" y1="12" x2="5" y2="12"></line></svg>
                    Kembali ke Halaman Login
                </a>
            @endauth

            <div class="contact-section">
                <h3>Butuh Bantuan?</h3>
                <div class="contact-info">
                    @if($storePhone)
                        <a href="https://wa.me/{{ preg_replace('/[^0-9]/', '', $storePhone) }}" class="contact-item">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l2.28-2.28a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"></path></svg>
                            WhatsApp: {{ $storePhone }}
                        </a>
                    @endif
                    @if($storeEmail)
                        <a href="mailto:{{ $storeEmail }}" class="contact-item">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path><polyline points="22,6 12,13 2,6"></polyline></svg>
                            Email: {{ $storeEmail }}
                        </a>
                    @endif
                </div>
            </div>
        </div>
    </div>
</body>
</html>

