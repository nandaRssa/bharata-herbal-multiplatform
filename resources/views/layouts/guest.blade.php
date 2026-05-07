<!DOCTYPE html>
<html lang="id" class="scroll-smooth">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ $title ?? 'Autentikasi' }} — Bharata Herbal</title>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&display=swap" rel="stylesheet">
    @vite(['resources/css/app.css', 'resources/js/app.js'])
</head>
<body class="font-sans antialiased bg-gradient-to-br from-herbal-50 via-white to-emerald-50 min-h-screen">

    <div class="min-h-screen flex">
        {{-- Left Decorative Panel --}}
        <div class="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-herbal-800 via-herbal-700 to-emerald-800 relative overflow-hidden">
            {{-- Background Pattern --}}
            <div class="absolute inset-0 opacity-10">
                <div class="absolute top-10 left-10 w-64 h-64 rounded-full bg-white"></div>
                <div class="absolute bottom-20 right-10 w-48 h-48 rounded-full bg-white"></div>
                <div class="absolute top-1/2 left-1/3 w-32 h-32 rounded-full bg-white"></div>
            </div>

            <div class="relative z-10 flex flex-col justify-center px-16 text-white">
                {{-- Logo --}}
                <a href="{{ route('home') }}" class="flex items-center gap-3 mb-16">
                    <img src="{{ asset('images/logo-bharata.jpeg') }}" alt="Logo" class="w-16 h-16 rounded-2xl object-cover border-2 border-white/20 shadow-lg">
                    <div>
                        <span class="font-bold text-2xl tracking-tight">Bharata</span><span class="font-bold text-2xl text-emerald-300">Herbal</span>
                    </div>
                </a>

                <h1 class="text-4xl font-bold leading-tight mb-6">
                    Produk Herbal<br>
                    <span class="text-emerald-300">Alami & Terpercaya</span>
                </h1>
                <p class="text-white/80 text-lg leading-relaxed mb-10">
                    Temukan kebaikan alam Nusantara dalam setiap produk herbal kami yang dipilih dengan cermat untuk kesehatan dan kesejahteraan Anda.
                </p>

                <div class="grid grid-cols-3 gap-4">
                    <div class="bg-white/10 backdrop-blur-sm rounded-2xl p-4 text-center">
                        <div class="text-2xl font-bold text-emerald-300">500+</div>
                        <div class="text-white/70 text-xs mt-1">Produk Herbal</div>
                    </div>
                    <div class="bg-white/10 backdrop-blur-sm rounded-2xl p-4 text-center">
                        <div class="text-2xl font-bold text-emerald-300">10K+</div>
                        <div class="text-white/70 text-xs mt-1">Pelanggan Puas</div>
                    </div>
                    <div class="bg-white/10 backdrop-blur-sm rounded-2xl p-4 text-center">
                        <div class="text-2xl font-bold text-emerald-300">100%</div>
                        <div class="text-white/70 text-xs mt-1">Alami</div>
                    </div>
                </div>
            </div>
        </div>

        {{-- Right Form Panel --}}
        <div class="w-full lg:w-1/2 flex items-center justify-center px-6 py-12">
            <div class="w-full max-w-md">
                {{-- Mobile Logo --}}
                <div class="lg:hidden flex items-center gap-3 mb-8 justify-center">
                    <img src="{{ asset('images/logo-bharata.jpeg') }}" alt="Logo" class="w-12 h-12 rounded-xl object-cover shadow-sm">
                    <span class="font-bold text-xl text-herbal-800">Bharata<span class="text-herbal-500">Herbal</span></span>
                </div>

                {{ $slot }}
            </div>
        </div>
    </div>

</body>
</html>
