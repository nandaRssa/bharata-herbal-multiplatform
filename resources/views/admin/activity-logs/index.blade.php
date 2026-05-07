<x-layouts.admin>
<x-slot name="title">Aktivitas Log</x-slot>
<x-slot name="subtitle">Rekaman semua aktivitas yang dilakukan admin</x-slot>

@php
$actionColors = [
    'blue'   => 'bg-blue-100 text-blue-700',
    'gray'   => 'bg-gray-100 text-gray-600',
    'green'  => 'bg-green-100 text-green-700',
    'yellow' => 'bg-yellow-100 text-yellow-700',
    'orange' => 'bg-orange-100 text-orange-700',
    'teal'   => 'bg-teal-100 text-teal-700',
    'red'    => 'bg-red-100 text-red-700',
    'purple' => 'bg-purple-100 text-purple-700',
    'indigo' => 'bg-indigo-100 text-indigo-700',
];

$actionIcons = [
    'admin_login'         => 'log-in',
    'admin_logout'        => 'log-out',
    'create_product'      => 'plus-circle',
    'update_product'      => 'pencil',
    'archive_product'     => 'archive',
    'restore_product'     => 'refresh-ccw',
    'delete_product'      => 'trash-2',
    'update_order_status' => 'truck',
    'update_settings'     => 'settings',
];
@endphp

{{-- ═══════════════════════════════════════════
  FILTER BAR
═══════════════════════════════════════════ --}}
<div class="bg-white rounded-2xl shadow-sm border border-gray-100 p-5 mb-6">
    <form method="GET" action="{{ route('admin.activity-logs.index') }}" class="flex flex-wrap gap-3 items-end">
        
        {{-- Search (admin name) --}}
        <div class="flex-1 min-w-[180px]">
            <label class="block text-xs font-semibold text-gray-500 mb-1.5">Cari Admin</label>
            <div class="relative">
                <i data-lucide="search" class="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2"></i>
                <input type="text" name="search" value="{{ request('search') }}"
                       placeholder="Nama admin..."
                       class="w-full pl-9 pr-3 py-2 text-sm border border-gray-200 rounded-lg
                              focus:outline-none focus:ring-2 focus:ring-green-500/30 focus:border-green-400 bg-gray-50">
            </div>
        </div>

        {{-- Filter by Aksi --}}
        <div class="min-w-[190px]">
            <label class="block text-xs font-semibold text-gray-500 mb-1.5">Jenis Aksi</label>
            <select name="action"
                    class="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg
                           focus:outline-none focus:ring-2 focus:ring-green-500/30 focus:border-green-400 bg-gray-50">
                <option value="">Semua Aksi</option>
                @foreach ($actions as $key => $cfg)
                    <option value="{{ $key }}" {{ request('action') === $key ? 'selected' : '' }}>
                        {{ $cfg['label'] }}
                    </option>
                @endforeach
            </select>
        </div>

        {{-- Filter Date From --}}
        <div class="min-w-[150px]">
            <label class="block text-xs font-semibold text-gray-500 mb-1.5">Dari Tanggal</label>
            <input type="date" name="date_from" value="{{ request('date_from') }}"
                   class="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg
                          focus:outline-none focus:ring-2 focus:ring-green-500/30 focus:border-green-400 bg-gray-50">
        </div>

        {{-- Filter Date To --}}
        <div class="min-w-[150px]">
            <label class="block text-xs font-semibold text-gray-500 mb-1.5">Sampai Tanggal</label>
            <input type="date" name="date_to" value="{{ request('date_to') }}"
                   class="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg
                          focus:outline-none focus:ring-2 focus:ring-green-500/30 focus:border-green-400 bg-gray-50">
        </div>

        {{-- Buttons --}}
        <div class="flex gap-2">
            <button type="submit"
                    class="flex items-center gap-2 bg-green-700 hover:bg-green-800 text-white
                           px-4 py-2 rounded-lg text-sm font-medium transition">
                <i data-lucide="filter" class="w-4 h-4"></i>
                Filter
            </button>
            @if(request()->hasAny(['search', 'action', 'date_from', 'date_to']))
            <a href="{{ route('admin.activity-logs.index') }}"
               class="flex items-center gap-2 bg-gray-100 hover:bg-gray-200 text-gray-700
                      px-4 py-2 rounded-lg text-sm font-medium transition">
                <i data-lucide="x" class="w-4 h-4"></i>
                Reset
            </a>
            @endif
        </div>

    </form>
</div>

{{-- ═══════════════════════════════════════════
  SUMMARY CHIPS
═══════════════════════════════════════════ --}}
<div class="flex flex-wrap gap-3 mb-5">
    <div class="bg-white rounded-xl border border-gray-100 shadow-sm px-4 py-3 flex items-center gap-2.5 min-w-[140px]">
        <div class="w-8 h-8 bg-green-50 rounded-lg flex items-center justify-center">
            <i data-lucide="activity" class="w-4 h-4 text-green-700"></i>
        </div>
        <div>
            <p class="text-[10px] text-gray-400 font-medium uppercase tracking-wider">Total Log</p>
            <p class="text-lg font-bold text-gray-900 leading-none">{{ number_format($logs->total()) }}</p>
        </div>
    </div>

    <div class="bg-white rounded-xl border border-gray-100 shadow-sm px-4 py-3 flex items-center gap-2.5 min-w-[140px]">
        <div class="w-8 h-8 bg-blue-50 rounded-lg flex items-center justify-center">
            <i data-lucide="calendar" class="w-4 h-4 text-blue-600"></i>
        </div>
        <div>
            <p class="text-[10px] text-gray-400 font-medium uppercase tracking-wider">Halaman</p>
            <p class="text-lg font-bold text-gray-900 leading-none">{{ $logs->currentPage() }} / {{ $logs->lastPage() }}</p>
        </div>
    </div>
</div>

{{-- ═══════════════════════════════════════════
  LOG TABLE
═══════════════════════════════════════════ --}}
<div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">

    {{-- Table Header --}}
    <div class="flex items-center justify-between px-6 py-4 border-b border-gray-100">
        <div>
            <h2 class="font-bold text-gray-900">Daftar Aktivitas</h2>
            <p class="text-xs text-gray-400 mt-0.5">Menampilkan {{ $logs->count() }} dari {{ $logs->total() }} aktivitas</p>
        </div>
        <div class="flex items-center gap-2 text-xs text-gray-500">
            <i data-lucide="clock" class="w-4 h-4"></i>
            Diperbarui {{ now()->format('H:i') }} WIB
        </div>
    </div>

    <div class="overflow-x-auto">
        <table class="w-full text-sm">
            <thead>
                <tr class="bg-gray-50 border-b border-gray-100">
                    <th class="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide w-44">Waktu</th>
                    <th class="text-left px-6 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide w-40">Admin</th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide w-44">Aksi</th>
                    <th class="text-left px-4 py-3 text-xs font-semibold text-gray-500 uppercase tracking-wide">Detail / Deskripsi</th>
                </tr>
            </thead>
            <tbody class="divide-y divide-gray-50">
                @forelse ($logs as $log)
                @php
                    $actionCfg  = $actions[$log->action] ?? ['label' => $log->action, 'color' => 'gray'];
                    $badgeCss   = $actionColors[$actionCfg['color']] ?? 'bg-gray-100 text-gray-600';
                    $iconName   = $actionIcons[$log->action] ?? 'activity';
                @endphp
                <tr class="hover:bg-gray-50/60 transition-colors">
                    {{-- Waktu --}}
                    <td class="px-6 py-4">
                        <div class="flex flex-col">
                            <span class="font-semibold text-gray-800 text-xs">{{ $log->created_at->format('d M Y') }}</span>
                            <span class="text-gray-400 text-[11px]">{{ $log->created_at->format('H:i:s') }} WIB</span>
                            <span class="text-gray-300 text-[10px] mt-0.5">{{ $log->created_at->diffForHumans() }}</span>
                        </div>
                    </td>

                    {{-- Admin --}}
                    <td class="px-6 py-4">
                        @if ($log->admin)
                        <div class="flex items-center gap-2">
                            <div class="w-8 h-8 rounded-full bg-green-100 flex items-center justify-center
                                        text-green-800 font-bold text-xs shrink-0">
                                {{ strtoupper(substr($log->admin->name, 0, 2)) }}
                            </div>
                            <div>
                                <p class="font-medium text-gray-800 text-xs leading-none">{{ $log->admin->name }}</p>
                                <p class="text-gray-400 text-[10px] mt-0.5">{{ $log->admin->role_label ?? 'Admin' }}</p>
                            </div>
                        </div>
                        @else
                        <span class="text-gray-400 text-xs italic">Sistem</span>
                        @endif
                    </td>

                    {{-- Aksi Badge --}}
                    <td class="px-4 py-4">
                        <span class="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs font-semibold {{ $badgeCss }}">
                            <i data-lucide="{{ $iconName }}" class="w-3.5 h-3.5"></i>
                            {{ $actionCfg['label'] }}
                        </span>
                    </td>

                    {{-- Deskripsi --}}
                    <td class="px-4 py-4">
                        <p class="text-gray-700 text-sm leading-relaxed">{{ $log->description }}</p>
                        @if ($log->subject_type && $log->subject_id)
                        <p class="text-gray-400 text-[10px] mt-0.5">
                            {{ $log->subject_type }} #{{ $log->subject_id }}
                        </p>
                        @endif
                    </td>
                </tr>
                @empty
                <tr>
                    <td colspan="4" class="px-6 py-20 text-center">
                        <div class="flex flex-col items-center gap-3 text-gray-300">
                            <i data-lucide="clipboard-list" class="w-14 h-14"></i>
                            <div>
                                <p class="text-base font-semibold text-gray-400">Belum ada aktivitas tercatat</p>
                                <p class="text-sm text-gray-300 mt-1">Aktivitas akan muncul setelah admin melakukan tindakan</p>
                            </div>
                        </div>
                    </td>
                </tr>
                @endforelse
            </tbody>
        </table>
    </div>

    {{-- Pagination --}}
    @if ($logs->hasPages())
    <div class="px-6 py-4 border-t border-gray-100 text-sm">
        {{ $logs->links() }}
    </div>
    @endif

</div>

</x-layouts.admin>
