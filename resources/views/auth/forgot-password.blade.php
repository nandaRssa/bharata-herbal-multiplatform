<x-guest-layout>
    <x-slot name="title">Lupa Password</x-slot>

    <div class="mb-8">
        <h2 class="text-3xl font-bold text-gray-900">Lupa Password?</h2>
        <p class="text-gray-500 mt-2 text-sm leading-relaxed">
            Masukkan email Anda dan kami akan mengirimkan link untuk mereset password.
        </p>
    </div>

    {{-- Success Status --}}
    @if (session('status'))
        <div class="mb-6 p-4 bg-green-50 border border-green-200 rounded-xl text-green-700 text-sm font-medium flex items-start gap-3">
            <svg class="w-5 h-5 text-green-500 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
            <span>{{ session('status') }}</span>
        </div>
    @endif

    {{-- Dev Mode: Show reset link directly --}}
    @if (session('dev_reset_url') && config('app.debug'))
        <div class="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-xl">
            <div class="flex items-center gap-2 mb-2">
                <svg class="w-4 h-4 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                </svg>
                <p class="text-xs font-semibold text-blue-700">🔧 Mode Development — Link Reset Password:</p>
            </div>
            <a href="{{ session('dev_reset_url') }}"
               class="text-xs text-blue-600 break-all underline hover:text-blue-800 transition-colors leading-relaxed block">
                {{ session('dev_reset_url') }}
            </a>
            <p class="text-xs text-blue-500 mt-2 italic">Klik link di atas untuk melanjutkan reset password (hanya tampil di mode debug)</p>
        </div>
    @endif

    <form method="POST" action="{{ route('password.email') }}" class="space-y-5">
        @csrf

        {{-- Email --}}
        <div>
            <label for="email" class="block text-sm font-semibold text-gray-700 mb-1.5">Alamat Email</label>
            <input id="email" type="email" name="email" value="{{ old('email') }}" required autofocus
                   class="w-full px-4 py-3 rounded-xl border border-gray-200 bg-gray-50 focus:bg-white focus:border-herbal-500 focus:ring-2 focus:ring-herbal-200 outline-none transition text-sm"
                   placeholder="nama@email.com">
            @error('email')
                <p class="mt-1.5 text-sm text-red-600 flex items-center gap-1">
                    <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd"/></svg>
                    {{ $message }}
                </p>
            @enderror
        </div>

        {{-- Submit --}}
        <button type="submit"
                class="w-full bg-herbal-800 hover:bg-herbal-900 text-white font-semibold py-3.5 px-6 rounded-xl transition-all duration-200 shadow-sm hover:shadow-md active:scale-[0.98] text-sm flex items-center justify-center gap-2">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"/>
            </svg>
            Kirim Link Reset Password
        </button>
    </form>

    {{-- Back to Login --}}
    <div class="mt-8 pt-6 border-t border-gray-100 text-center">
        <a href="{{ route('login') }}" class="text-sm text-herbal-700 hover:text-herbal-900 font-medium transition-colors flex items-center justify-center gap-2">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 19l-7-7m0 0l7-7m-7 7h18"/>
            </svg>
            Kembali ke Halaman Masuk
        </a>
    </div>
</x-guest-layout>
