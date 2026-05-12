<x-layouts.admin title="Manajemen Voucher" subtitle="Kelola kode diskon untuk pelanggan">
<div class="space-y-6">
    {{-- Header --}}
    <div class="flex items-center justify-between">
        <a href="{{ route('admin.vouchers.create') }}"
           class="inline-flex items-center gap-2 bg-green-700 hover:bg-green-800 text-white px-4 py-2 rounded-lg text-sm font-medium transition">
            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4"/>
            </svg>
            Buat Voucher
        </a>
    </div>

    {{-- Table --}}
    <div class="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <table class="w-full text-sm">
            <thead class="bg-gray-50 border-b border-gray-100">
                <tr>
                    <th class="text-left px-4 py-3 text-gray-600 font-semibold">Kode</th>
                    <th class="text-left px-4 py-3 text-gray-600 font-semibold">Nama</th>
                    <th class="text-left px-4 py-3 text-gray-600 font-semibold">Diskon</th>
                    <th class="text-left px-4 py-3 text-gray-600 font-semibold">Min. Beli</th>
                    <th class="text-left px-4 py-3 text-gray-600 font-semibold">Terpakai</th>
                    <th class="text-left px-4 py-3 text-gray-600 font-semibold">Berlaku</th>
                    <th class="text-left px-4 py-3 text-gray-600 font-semibold">Status</th>
                    <th class="text-left px-4 py-3 text-gray-600 font-semibold">Aksi</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
                @forelse($vouchers as $v)
                    @php
                        $isExpired = $v->expires_at && now()->isAfter($v->expires_at);
                        $isFull    = $v->usage_limit > 0 && $v->used_count >= $v->usage_limit;
                    @endphp
                    <tr class="hover:bg-gray-50 transition">
                        <td class="px-4 py-3">
                            <span class="font-mono font-bold text-green-700 bg-green-50 px-2 py-1 rounded">{{ $v->code }}</span>
                        </td>
                        <td class="px-4 py-3 text-gray-800">{{ $v->name }}</td>
                        <td class="px-4 py-3 font-semibold text-green-700">{{ $v->discount_label }}</td>
                        <td class="px-4 py-3 text-gray-600">
                            {{ $v->min_purchase > 0 ? 'Rp ' . number_format($v->min_purchase, 0, ',', '.') : '-' }}
                        </td>
                        <td class="px-4 py-3 text-gray-600">
                            {{ $v->used_count }}{{ $v->usage_limit > 0 ? '/' . $v->usage_limit : '' }}
                        </td>
                        <td class="px-4 py-3 text-gray-500 text-xs">
                            @if($v->expires_at)
                                {{ $v->expires_at->format('d M Y') }}
                                @if($isExpired) <span class="text-red-500">(Exp)</span> @endif
                            @else
                                <span class="text-gray-400">Tidak terbatas</span>
                            @endif
                        </td>
                        <td class="px-4 py-3">
                            @if(!$v->is_active)
                                <span class="px-2 py-0.5 text-xs rounded-full bg-gray-100 text-gray-500">Nonaktif</span>
                            @elseif($isExpired)
                                <span class="px-2 py-0.5 text-xs rounded-full bg-red-100 text-red-600">Kadaluarsa</span>
                            @elseif($isFull)
                                <span class="px-2 py-0.5 text-xs rounded-full bg-orange-100 text-orange-600">Kuota Habis</span>
                            @else
                                <span class="px-2 py-0.5 text-xs rounded-full bg-green-100 text-green-700">Aktif</span>
                            @endif
                        </td>
                        <td class="px-4 py-3">
                            <div class="flex items-center gap-2">
                                <a href="{{ route('admin.vouchers.edit', $v) }}"
                                   class="text-blue-600 hover:underline text-xs">Edit</a>
                                <form action="{{ route('admin.vouchers.toggle', $v) }}" method="POST" class="inline">
                                    @csrf @method('PATCH')
                                    <button class="text-xs {{ $v->is_active ? 'text-orange-500' : 'text-green-600' }} hover:underline">
                                        {{ $v->is_active ? 'Nonaktifkan' : 'Aktifkan' }}
                                    </button>
                                </form>
                                <form action="{{ route('admin.vouchers.destroy', $v) }}" method="POST" class="inline"
                                      onsubmit="return confirm('Hapus voucher {{ $v->code }}?')">
                                    @csrf @method('DELETE')
                                    <button class="text-red-500 hover:underline text-xs">Hapus</button>
                                </form>
                            </div>
                        </td>
                    </tr>
                @empty
                    <tr>
                        <td colspan="8" class="text-center py-12 text-gray-400">
                            <div class="text-4xl mb-2">🎫</div>
                            <p>Belum ada voucher. <a href="{{ route('admin.vouchers.create') }}" class="text-green-700 underline">Buat sekarang</a></p>
                        </td>
                    </tr>
                @endforelse
            </tbody>
        </table>
        @if($vouchers->hasPages())
            <div class="px-4 py-3 border-t border-gray-100">{{ $vouchers->links() }}</div>
        @endif
    </div>
</div>
</x-layouts.admin>
