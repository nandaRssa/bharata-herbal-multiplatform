<x-layouts.admin :title="isset($voucher) ? 'Edit Voucher' : 'Buat Voucher'">
<div class="max-w-2xl mx-auto">
    <div class="flex items-center gap-3 mb-6">
        <a href="{{ route('admin.vouchers.index') }}" class="text-gray-400 hover:text-gray-600">
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
            </svg>
        </a>
        <h1 class="text-xl font-bold text-gray-900">
            {{ isset($voucher) ? '✏️ Edit Voucher: ' . $voucher->code : '🎫 Buat Voucher Baru' }}
        </h1>
    </div>

    @if($errors->any())
        <div class="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm mb-6">
            <ul class="list-disc list-inside space-y-1">
                @foreach($errors->all() as $e) <li>{{ $e }}</li> @endforeach
            </ul>
        </div>
    @endif

    <form action="{{ isset($voucher) ? route('admin.vouchers.update', $voucher) : route('admin.vouchers.store') }}"
          method="POST" class="bg-white rounded-xl shadow-sm border border-gray-100 p-6 space-y-5">
        @csrf
        @if(isset($voucher)) @method('PUT') @endif

        {{-- Kode & Nama --}}
        <div class="grid grid-cols-2 gap-4">
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Kode Voucher <span class="text-red-500">*</span></label>
                <input type="text" name="code" value="{{ old('code', $voucher->code ?? '') }}"
                       placeholder="HEMAT20" maxlength="50"
                       class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm font-mono uppercase focus:ring-2 focus:ring-green-500 focus:border-transparent"
                       oninput="this.value=this.value.toUpperCase()">
                <p class="text-xs text-gray-400 mt-1">Huruf kapital, tanpa spasi</p>
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Nama Voucher <span class="text-red-500">*</span></label>
                <input type="text" name="name" value="{{ old('name', $voucher->name ?? '') }}"
                       placeholder="Diskon 20% Akhir Pekan"
                       class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-green-500 focus:border-transparent">
            </div>
        </div>

        {{-- Deskripsi --}}
        <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">Deskripsi</label>
            <textarea name="description" rows="2" placeholder="Deskripsi opsional..."
                      class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-green-500 focus:border-transparent">{{ old('description', $voucher->description ?? '') }}</textarea>
        </div>

        {{-- Tipe & Nilai Diskon --}}
        <div class="grid grid-cols-2 gap-4">
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Tipe Diskon <span class="text-red-500">*</span></label>
                <select name="type" id="voucherType"
                        class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-green-500">
                    <option value="flat"    {{ old('type', $voucher->type ?? '') === 'flat'    ? 'selected' : '' }}>💰 Nominal (Rp)</option>
                    <option value="percent" {{ old('type', $voucher->type ?? '') === 'percent' ? 'selected' : '' }}>📊 Persentase (%)</option>
                </select>
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">
                    Nilai Diskon <span class="text-red-500">*</span>
                    <span id="valueUnit" class="text-gray-400 font-normal">(Rp)</span>
                </label>
                <input type="number" name="value" value="{{ old('value', $voucher->value ?? '') }}"
                       min="1" placeholder="10000"
                       class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-green-500 focus:border-transparent">
            </div>
        </div>

        {{-- Max Diskon (untuk persen) --}}
        <div id="maxDiscountRow" class="{{ old('type', $voucher->type ?? '') !== 'percent' ? 'hidden' : '' }}">
            <label class="block text-sm font-medium text-gray-700 mb-1">Maksimal Diskon (Rp)</label>
            <input type="number" name="max_discount" value="{{ old('max_discount', $voucher->max_discount ?? '') }}"
                   min="0" placeholder="Kosongkan = tidak ada batas"
                   class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-green-500 focus:border-transparent">
            <p class="text-xs text-gray-400 mt-1">Batas maksimal diskon dalam Rupiah (opsional)</p>
        </div>

        {{-- Min Pembelian & Batas Penggunaan --}}
        <div class="grid grid-cols-2 gap-4">
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Minimum Pembelian (Rp)</label>
                <input type="number" name="min_purchase" value="{{ old('min_purchase', $voucher->min_purchase ?? 0) }}"
                       min="0" placeholder="0"
                       class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-green-500 focus:border-transparent">
                <p class="text-xs text-gray-400 mt-1">0 = tidak ada batas</p>
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Batas Penggunaan</label>
                <input type="number" name="usage_limit" value="{{ old('usage_limit', $voucher->usage_limit ?? 0) }}"
                       min="0" placeholder="0"
                       class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-green-500 focus:border-transparent">
                <p class="text-xs text-gray-400 mt-1">0 = tidak terbatas</p>
            </div>
        </div>

        {{-- Periode --}}
        <div class="grid grid-cols-2 gap-4">
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Berlaku Mulai</label>
                <input type="datetime-local" name="starts_at"
                       value="{{ old('starts_at', isset($voucher) && $voucher->starts_at ? $voucher->starts_at->format('Y-m-d\TH:i') : '') }}"
                       class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-green-500 focus:border-transparent">
            </div>
            <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Berlaku Sampai</label>
                <input type="datetime-local" name="expires_at"
                       value="{{ old('expires_at', isset($voucher) && $voucher->expires_at ? $voucher->expires_at->format('Y-m-d\TH:i') : '') }}"
                       class="w-full border border-gray-200 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-green-500 focus:border-transparent">
            </div>
        </div>

        {{-- Status --}}
        <div class="flex items-center gap-3">
            <input type="hidden" name="is_active" value="0">
            <input type="checkbox" name="is_active" id="isActive" value="1"
                   {{ old('is_active', $voucher->is_active ?? true) ? 'checked' : '' }}
                   class="w-4 h-4 text-green-600 border-gray-300 rounded">
            <label for="isActive" class="text-sm font-medium text-gray-700">Aktifkan voucher ini</label>
        </div>

        {{-- Submit --}}
        <div class="flex items-center justify-end gap-3 pt-2 border-t border-gray-100">
            <a href="{{ route('admin.vouchers.index') }}"
               class="px-4 py-2 text-sm text-gray-600 border border-gray-200 rounded-lg hover:bg-gray-50">Batal</a>
            <button type="submit"
                    class="px-5 py-2 text-sm font-medium bg-green-700 hover:bg-green-800 text-white rounded-lg transition">
                {{ isset($voucher) ? 'Simpan Perubahan' : 'Buat Voucher' }}
            </button>
        </div>
    </form>
</div>

<script>
    const typeSelect = document.getElementById('voucherType');
    const valueUnit  = document.getElementById('valueUnit');
    const maxRow     = document.getElementById('maxDiscountRow');

    function updateType() {
        const isPercent = typeSelect.value === 'percent';
        valueUnit.textContent = isPercent ? '(%)' : '(Rp)';
        maxRow.classList.toggle('hidden', !isPercent);
    }

    typeSelect.addEventListener('change', updateType);
    updateType();
</script>
</x-layouts.admin>
