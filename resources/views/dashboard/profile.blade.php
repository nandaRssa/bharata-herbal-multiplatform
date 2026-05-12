<x-layouts.dashboard>
    <x-slot name="title">Profil Saya</x-slot>
    <x-slot name="slot">

    <div class="space-y-6">
        {{-- Profile Photo --}}
        <div class="card p-6">
            <h2 class="font-bold text-gray-800 text-lg mb-5">Foto Profil</h2>
            <div class="flex items-center gap-5">
                @if ($user->avatar_url)
                <img src="{{ $user->avatar_url }}" alt="{{ $user->name }}" class="w-24 h-24 rounded-full object-cover">
                @else
                <div class="w-24 h-24 bg-herbal-100 rounded-full flex items-center justify-center">
                    <span class="font-bold text-herbal-700 text-3xl">{{ $user->initials }}</span>
                </div>
                @endif

                <form id="profile-photo-form" action="{{ route('user.profile.photo') }}" method="POST" enctype="multipart/form-data" class="space-y-2">
                    @csrf
                    <label class="btn-primary text-sm py-2.5 inline-flex cursor-pointer">
                        Unggah Foto
                        <input id="profile-photo-input" type="file" name="photo" accept="image/jpeg,image/png,image/jpg" class="hidden">
                    </label>
                    <p class="text-xs text-gray-400">JPG/PNG, maks 2MB.</p>
                    @error('photo')<p class="text-red-500 text-xs mt-1">{{ $message }}</p>@enderror
                </form>
            </div>
        </div>

        {{-- Profile Info --}}
        <div class="card p-6">
            <h2 class="font-bold text-gray-800 text-lg mb-5">Informasi Profil</h2>
            <form action="{{ route('user.profile.update') }}" method="POST" class="space-y-4">
                @csrf @method('PUT')
                <div>
                    <label class="form-label">Nama Lengkap</label>
                    <input type="text" name="name" value="{{ old('name', $user->name) }}" class="form-input" required>
                    @error('name')<p class="text-red-500 text-xs mt-1">{{ $message }}</p>@enderror
                </div>
                <div>
                    <label class="form-label">Email</label>
                    <input type="email" value="{{ $user->email }}" class="form-input bg-gray-50" disabled>
                    <p class="text-xs text-gray-400 mt-1">Email tidak dapat diubah.</p>
                </div>
                <div>
                    <label class="form-label">Nomor HP</label>
                    <input type="text" name="phone" value="{{ old('phone', $user->phone) }}" class="form-input" placeholder="08xx-xxxx-xxxx">
                    @error('phone')<p class="text-red-500 text-xs mt-1">{{ $message }}</p>@enderror
                </div>
                <button type="submit" class="btn-primary text-sm py-2.5">Simpan Perubahan</button>
            </form>
        </div>

        {{-- Change Password --}}
        <div class="card p-6">
            <h2 class="font-bold text-gray-800 text-lg mb-5">Ubah Password</h2>
            <form action="{{ route('user.password.update') }}" method="POST" class="space-y-4">
                @csrf @method('PUT')
                <div>
                    <label class="form-label">Password Saat Ini</label>
                    <input type="password" name="current_password" class="form-input" required>
                    @error('current_password')<p class="text-red-500 text-xs mt-1">{{ $message }}</p>@enderror
                </div>
                <div>
                    <label class="form-label">Password Baru</label>
                    <input type="password" name="password" class="form-input" required>
                    @error('password')<p class="text-red-500 text-xs mt-1">{{ $message }}</p>@enderror
                </div>
                <div>
                    <label class="form-label">Konfirmasi Password Baru</label>
                    <input type="password" name="password_confirmation" class="form-input" required>
                </div>
                <button type="submit" class="btn-primary text-sm py-2.5">Ubah Password</button>
            </form>
        </div>
    </div>

    <script>
        document.getElementById('profile-photo-input')?.addEventListener('change', function () {
            if (this.files.length > 0) {
                document.getElementById('profile-photo-form').submit();
            }
        });
    </script>

    </x-slot>
</x-layouts.dashboard>
