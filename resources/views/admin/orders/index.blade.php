<x-layouts.admin>
    <x-slot name="title">Manajemen Pesanan</x-slot>
    <x-slot name="subtitle">Kelola dan pantau semua transaksi pelanggan</x-slot>

    {{-- ═══════════════════════════════════════════════════════════════════
    TOP ACTION BAR  (Search · Filter Dropdown · Buttons)
═══════════════════════════════════════════════════════════════════ --}}
    <form method="GET" action="{{ route('admin.orders.index') }}" id="filterForm">

        <div class="flex flex-col gap-4 mb-6">

            {{-- Row 1: Search + Create + Export --}}
            <div class="flex flex-col sm:flex-row gap-3">

                {{-- Search --}}
                <div class="relative flex-1 min-w-0">
                    <span class="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                        <i data-lucide="search" class="w-4 h-4 text-gray-400"></i>
                    </span>
                    <input
                        type="text"
                        name="search"
                        id="searchInput"
                        value="{{ $search }}"
                        placeholder="Cari ID pesanan, nama customer, atau nomor resi…"
                        class="w-full pl-10 pr-4 py-2.5 text-sm bg-white border border-gray-200 rounded-xl
                           shadow-sm focus:outline-none focus:ring-2 focus:ring-green-500/30 focus:border-green-400
                           transition placeholder-gray-400"
                        autocomplete="off">
                </div>

                {{-- Status Dropdown Filter --}}
                <div class="relative">
                    <span class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                        <i data-lucide="filter" class="w-4 h-4 text-gray-400"></i>
                    </span>
                    <select
                        name="status"
                        id="statusSelect"
                        onchange="this.form.submit()"
                        class="pl-9 pr-8 py-2.5 text-sm bg-white border border-gray-200 rounded-xl shadow-sm
                           focus:outline-none focus:ring-2 focus:ring-green-500/30 focus:border-green-400
                           appearance-none cursor-pointer transition w-48">
                        <option value="">Semua Status</option>
                        <option value="pending" {{ $status === 'pending'    ? 'selected' : '' }}>Belum Dibayar</option>
                        <option value="paid" {{ $status === 'paid'       ? 'selected' : '' }}>Dibayar</option>
                        <option value="processing" {{ $status === 'processing' ? 'selected' : '' }}>Diproses</option>
                        <option value="shipped" {{ $status === 'shipped'    ? 'selected' : '' }}>Dikirim</option>
                        <option value="completed" {{ $status === 'completed'  ? 'selected' : '' }}>Selesai</option>
                        <option value="cancelled" {{ $status === 'cancelled'  ? 'selected' : '' }}>Dibatalkan</option>
                    </select>
                    <span class="absolute inset-y-0 right-0 pr-3 flex items-center pointer-events-none">
                        <i data-lucide="chevron-down" class="w-3.5 h-3.5 text-gray-400"></i>
                    </span>
                </div>

                {{-- Buttons --}}
                <div class="flex gap-2 shrink-0">
                    {{-- Export CSV --}}
                    <a href="{{ route('admin.orders.export', array_filter(['status' => $status, 'search' => $search])) }}"
                        id="exportBtn"
                        class="inline-flex items-center gap-2 px-4 py-2.5 text-sm font-semibold
                          bg-white border border-gray-200 text-gray-700 rounded-xl shadow-sm
                          hover:bg-gray-50 hover:border-gray-300 transition">
                        <i data-lucide="upload" class="w-4 h-4"></i>
                        Export CSV
                    </a>
                </div>
            </div>

            {{-- ── STATUS TABS ─────────────────────────────────────────────── --}}
            @php
            $tabs = [
            '' => ['label' => 'Semua', 'count' => $totalAll],
            'pending' => ['label' => 'Belum Dibayar', 'count' => $statusCounts['pending'] ?? 0],
            'processing' => ['label' => 'Diproses', 'count' => $statusCounts['processing'] ?? 0],
            'shipped' => ['label' => 'Dikirim', 'count' => $statusCounts['shipped'] ?? 0],
            'completed' => ['label' => 'Selesai', 'count' => $statusCounts['completed'] ?? 0],
            'cancelled' => ['label' => 'Dibatalkan', 'count' => $statusCounts['cancelled'] ?? 0],
            ];
            @endphp

            <div class="flex flex-wrap gap-2">
                @foreach ($tabs as $tabValue => $tab)
                @php
                $isActive = ($status === $tabValue) || ($tabValue === '' && !$status);
                @endphp
                <a href="{{ route('admin.orders.index', array_filter(['status' => $tabValue, 'search' => $search], fn($v) => $v !== '')) }}"
                    class="inline-flex items-center gap-2 px-4 py-2 rounded-full text-sm font-semibold transition-all
                          {{ $isActive
                              ? 'bg-green-800 text-white shadow-sm'
                              : 'bg-white border border-gray-200 text-gray-600 hover:border-green-300 hover:text-green-800' }}">
                    {{ $tab['label'] }}
                    <span class="inline-flex items-center justify-center min-w-[20px] h-5 px-1.5 rounded-full text-xs font-bold
                                 {{ $isActive ? 'bg-green-700 text-green-100' : 'bg-gray-100 text-gray-500' }}">
                        {{ $tab['count'] }}
                    </span>
                </a>
                @endforeach
            </div>

        </div>

    </form>

    {{-- ═══════════════════════════════════════════════════════════════════
    FLASH MESSAGE
═══════════════════════════════════════════════════════════════════ --}}
    @if (session('success'))
    <div class="mb-4 flex items-center gap-3 bg-green-50 border border-green-200 text-green-800 px-4 py-3 rounded-xl text-sm font-medium">
        <i data-lucide="check-circle-2" class="w-4 h-4 text-green-600 shrink-0"></i>
        {{ session('success') }}
    </div>
    @endif

    {{-- ═══════════════════════════════════════════════════════════════════
    BULK ACTION BAR
═══════════════════════════════════════════════════════════════════ --}}
    <div id="bulkActionBar" class="mb-4 hidden bg-blue-50 border border-blue-200 rounded-lg p-4 flex items-center justify-between">
        <div class="flex items-center gap-3">
            <i data-lucide="check-square" class="w-5 h-5 text-blue-600"></i>
            <span class="text-sm font-medium text-blue-900">
                <span id="selectedCount">0</span> pesanan dipilih
            </span>
        </div>
        <form id="bulkActionForm" method="POST" action="{{ route('admin.orders.bulk-update-status') }}" class="flex items-center gap-2">
            @csrf
            <select name="status" id="bulkStatusSelect" required
                    class="px-3 py-2 text-sm bg-white border border-blue-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500">
                <option value="">-- Ubah Status Ke --</option>
                <option value="pending">Belum Dibayar</option>
                <option value="paid">Dibayar</option>
                <option value="processing">Diproses</option>
                <option value="shipped">Dikirim</option>
                <option value="completed">Selesai</option>
                <option value="cancelled">Dibatalkan</option>
            </select>
            <button type="submit" class="px-4 py-2 text-sm font-semibold bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition">
                Terapkan
            </button>
            <button type="button" onclick="clearBulkSelection()" class="px-4 py-2 text-sm font-semibold bg-white border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition">
                Batal
            </button>
        </form>
    </div>

    {{-- ═══════════════════════════════════════════════════════════════════
    ORDERS TABLE
═══════════════════════════════════════════════════════════════════ --}}
    <div class="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">

        <div class="overflow-x-auto">
            <form id="bulkSelectionForm">
                <table class="w-full text-sm">

                    {{-- THEAD --}}
                    <thead class="bg-gray-50 border-b border-gray-100">
                        <tr>
                            <th class="px-4 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide whitespace-nowrap w-10">
                                <input type="checkbox" id="selectAllCheckbox" class="w-4 h-4 cursor-pointer rounded border-gray-300 text-blue-600"
                                       onchange="toggleSelectAll(this)">
                            </th>
                            <th class="px-5 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide whitespace-nowrap">
                                No. Pesanan
                            </th>
                        <th class="px-5 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide whitespace-nowrap">
                            Tanggal Order
                        </th>
                        <th class="px-5 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide whitespace-nowrap">
                            Nama Customer
                        </th>
                        <th class="px-5 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide whitespace-nowrap">
                            Produk
                        </th>
                        <th class="px-5 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide whitespace-nowrap">
                            Status
                        </th>
                        <th class="px-5 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide whitespace-nowrap">
                            Total
                        </th>
                        <th class="px-5 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide whitespace-nowrap">
                            Pengiriman
                        </th>
                        <th class="px-5 py-4 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide whitespace-nowrap">
                            Nomor Resi
                        </th>
                        <th class="px-5 py-4 w-10"></th>
                    </tr>
                </thead>

                {{-- TBODY --}}
                <tbody class="divide-y divide-gray-50">

                    @forelse ($orders as $order)
                    @php
                   
                    $statusConfig = [
                    'pending' => ['ring' => 'ring-yellow-200 bg-yellow-50 text-yellow-700', 'dot' => 'bg-yellow-400'],
                    'paid' => ['ring' => 'ring-blue-200 bg-blue-50 text-blue-700', 'dot' => 'bg-blue-400'],
                    'processing' => ['ring' => 'ring-indigo-200 bg-indigo-50 text-indigo-700', 'dot' => 'bg-indigo-400'],
                    'shipped' => ['ring' => 'ring-orange-200 bg-orange-50 text-orange-700', 'dot' => 'bg-orange-400'],
                    'completed' => ['ring' => 'ring-green-200 bg-green-50 text-green-700', 'dot' => 'bg-green-500'],
                    'cancelled' => ['ring' => 'ring-red-200 bg-red-50 text-red-700', 'dot' => 'bg-red-400'],
                    ];
                    $sc = $statusConfig[$order->status] ?? ['ring' => 'ring-gray-200 bg-gray-50 text-gray-600', 'dot' => 'bg-gray-400'];

                    $resi = $order->tracking_number ?? null;
                    $courier = null;
                    if ($resi) {
                    $prefix = strtoupper(substr($resi, 0, 3));
                    if (str_starts_with(strtoupper($resi), 'JNE')) $courier = ['name' => 'JNE', 'color' => 'bg-red-500'];
                    elseif (str_starts_with(strtoupper($resi), 'JNT')) $courier = ['name' => 'J&T', 'color' => 'bg-yellow-500'];
                    elseif (str_starts_with(strtoupper($resi), 'SIL')) $courier = ['name' => 'SICEPAT', 'color' => 'bg-blue-500'];
                    else $courier = ['name' => 'Kurir', 'color' => 'bg-green-600'];
                    }

                    $itemsList = $order->items->take(2);
                    $extraCount = max(0, $order->items->count() - 2);
                    $totalQty = $order->items->sum('quantity');
                    @endphp

                    <tr class="hover:bg-green-50/30 transition-colors group">

                        {{-- Checkbox --}}
                        <td class="px-4 py-4 whitespace-nowrap" onclick="event.stopPropagation();">
                            <input type="checkbox" name="order_ids[]" value="{{ $order->id }}" class="w-4 h-4 cursor-pointer rounded border-gray-300 text-blue-600 order-checkbox"
                                   onchange="updateBulkActionBar()">
                        </td>

                        {{-- No. Pesanan --}}
                        <td class="px-5 py-4 whitespace-nowrap cursor-pointer" data-href="{{ route('admin.orders.show', $order) }}">
                            <span class="font-mono font-bold text-green-800 text-[13px] tracking-wide">
                                {{ $order->order_number }}
                            </span>
                        </td>

                        {{-- Tanggal Order --}}
                        <td class="px-5 py-4 whitespace-nowrap cursor-pointer" data-href="{{ route('admin.orders.show', $order) }}">
                            <div class="text-gray-800 font-medium text-xs">
                                {{ $order->created_at->format('d M Y') }}
                            </div>
                            <div class="text-gray-400 text-[11px] mt-0.5">
                                {{ $order->created_at->format('H:i') }} WIB
                            </div>
                        </td>

                        {{-- Nama Customer --}}
                        <td class="px-5 py-4 whitespace-nowrap cursor-pointer" data-href="{{ route('admin.orders.show', $order) }}">
                            <div class="flex items-center gap-2.5">
                                <div class="w-8 h-8 rounded-full bg-green-100 text-green-800 font-bold text-xs
                                        flex items-center justify-center shrink-0 ring-1 ring-green-200">
                                    {{ strtoupper(substr($order->user->name ?? '?', 0, 2)) }}
                                </div>
                                <div>
                                    <div class="font-semibold text-gray-800 text-sm leading-tight">
                                        {{ $order->user->name ?? '-' }}
                                    </div>
                                    <div class="text-gray-400 text-[11px]">
                                        {{ $order->user->email ?? '' }}
                                    </div>
                                </div>
                            </div>
                        </td>

                        {{-- Produk --}}
                        <td class="px-5 py-4 cursor-pointer" data-href="{{ route('admin.orders.show', $order) }}">
                            <div class="flex flex-col gap-0.5 max-w-[200px]">
                                @foreach ($itemsList as $item)
                                <div class="flex items-center gap-1.5 min-w-0">
                                    <span class="inline-flex items-center justify-center w-5 h-5 rounded
                                                 bg-green-100 text-green-700 text-[10px] font-bold shrink-0">
                                        {{ $item->quantity }}
                                    </span>
                                    <span class="text-gray-700 text-xs truncate">
                                        {{ $item->product->name ?? 'Produk dihapus' }}
                                    </span>
                                </div>
                                @endforeach
                                @if ($extraCount > 0)
                                <span class="text-[11px] text-gray-400 font-medium">+{{ $extraCount }} produk lainnya</span>
                                @endif
                            </div>
                            <div class="mt-1 text-[11px] text-gray-400">
                                Total {{ $totalQty }} item
                            </div>
                        </td>

                        {{-- Status Badge --}}
                        <td class="px-5 py-4 whitespace-nowrap cursor-pointer" data-href="{{ route('admin.orders.show', $order) }}">
                            <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold ring-1
                                     {{ $sc['ring'] }}">
                                <span class="w-1.5 h-1.5 rounded-full {{ $sc['dot'] }} inline-block"></span>
                                {{ $order->status_label }}
                            </span>
                        </td>

                        {{-- Total --}}
                        <td class="px-5 py-4 whitespace-nowrap cursor-pointer" data-href="{{ route('admin.orders.show', $order) }}">
                            <div class="font-bold text-gray-900 text-sm">
                                Rp {{ number_format($order->total_price, 0, ',', '.') }}
                            </div>
                            @if ($order->payment)
                            <div class="text-[11px] text-gray-400">
                                {{ $order->payment->method_label ?? '' }}
                            </div>
                            @endif
                        </td>

                        {{-- Pengiriman (Kurir) --}}
                        <td class="px-5 py-4 whitespace-nowrap cursor-pointer" data-href="{{ route('admin.orders.show', $order) }}">
                            @if ($courier)
                            <div class="flex items-center gap-2">
                                <span class="w-2 h-2 rounded-full {{ $courier['color'] }} shrink-0"></span>
                                <span class="text-xs font-semibold text-gray-700">{{ $courier['name'] }}</span>
                            </div>
                            @else
                            <span class="text-gray-400 text-xs">—</span>
                            @endif
                        </td>

                        {{-- Nomor Resi --}}
                        <td class="px-5 py-4 whitespace-nowrap cursor-pointer" data-href="{{ route('admin.orders.show', $order) }}">
                            @if ($resi)
                            <span class="font-mono text-[12px] text-gray-700 bg-gray-100 px-2 py-0.5 rounded">
                                {{ $resi }}
                            </span>
                            @else
                            <span class="text-gray-300 text-xs">Belum ada</span>
                            @endif
                        </td>

                        {{-- Action --}}
                        <td class="px-5 py-4 whitespace-nowrap text-right" onclick="event.stopPropagation()">
                            <a href="{{ route('admin.orders.show', $order) }}"
                                class="w-8 h-8 rounded-lg bg-gray-100 hover:bg-green-100 flex items-center justify-center
                                  opacity-0 group-hover:opacity-100 transition-all ml-auto"
                                title="Lihat detail">
                                <i data-lucide="eye" class="w-4 h-4 text-gray-500 hover:text-green-700"></i>
                            </a>
                        </td>

                    </tr>

                    @empty
                    <tr>
                        <td colspan="10" class="px-6 py-20 text-center">
                            <div class="flex flex-col items-center gap-3 text-gray-300">
                                <div class="w-16 h-16 bg-gray-100 rounded-2xl flex items-center justify-center">
                                    <i data-lucide="inbox" class="w-8 h-8 text-gray-300"></i>
                                </div>
                                <div>
                                    <p class="text-base font-semibold text-gray-400">Tidak ada pesanan ditemukan</p>
                                    @if ($search || $status)
                                    <p class="text-sm text-gray-400 mt-1">Coba ubah kata kunci atau filter yang digunakan</p>
                                    <a href="{{ route('admin.orders.index') }}"
                                        class="mt-3 inline-flex items-center gap-1.5 text-sm font-semibold text-green-700 hover:text-green-900">
                                        <i data-lucide="x-circle" class="w-4 h-4"></i>
                                        Reset filter
                                    </a>
                                    @else
                                    <p class="text-sm text-gray-400 mt-1">Belum ada pesanan masuk</p>
                                    @endif
                                </div>
                            </div>
                        </td>
                    </tr>
                    @endforelse

                </tbody>
            </table>
        </div>

        {{-- ── FOOTER: info + pagination ──────────────────────────────────── --}}
        @if ($orders->total() > 0)
        <div class="px-5 py-4 border-t border-gray-100 flex flex-col sm:flex-row items-center justify-between gap-3">
            <p class="text-xs text-gray-400 shrink-0">
                Menampilkan
                <span class="font-semibold text-gray-700">{{ $orders->firstItem() }}–{{ $orders->lastItem() }}</span>
                dari
                <span class="font-semibold text-gray-700">{{ $orders->total() }}</span>
                pesanan
            </p>
            <div class="pagination-wrap text-sm">
                {{ $orders->links() }}
            </div>
        </div>
        @endif

            </form>
    </div>

    <script>
    function toggleSelectAll(checkbox) {
        const checkboxes = document.querySelectorAll('.order-checkbox');
        checkboxes.forEach(cb => cb.checked = checkbox.checked);
        updateBulkActionBar();
    }

    function updateBulkActionBar() {
        const selectedCheckboxes = document.querySelectorAll('.order-checkbox:checked');
        const bulkActionBar = document.getElementById('bulkActionBar');
        const selectedCount = document.getElementById('selectedCount');
        
        if (selectedCheckboxes.length > 0) {
            selectedCount.textContent = selectedCheckboxes.length;
            bulkActionBar.classList.remove('hidden');
        } else {
            bulkActionBar.classList.add('hidden');
        }
    }

    function clearBulkSelection() {
        document.getElementById('selectAllCheckbox').checked = false;
        const checkboxes = document.querySelectorAll('.order-checkbox');
        checkboxes.forEach(cb => cb.checked = false);
        updateBulkActionBar();
    }

    document.getElementById('bulkActionForm').addEventListener('submit', function(e) {
        e.preventDefault();
        
        const selectedCheckboxes = document.querySelectorAll('.order-checkbox:checked');
        if (selectedCheckboxes.length === 0) {
            alert('Silakan pilih minimal satu pesanan');
            return false;
        }
        
        if (!document.getElementById('bulkStatusSelect').value) {
            alert('Silakan pilih status yang akan diterapkan');
            return false;
        }

        // Collect selected order IDs
        const orderIds = Array.from(selectedCheckboxes).map(cb => cb.value);
        
        // Create hidden inputs for order_ids
        const form = this;
        
        // Remove existing hidden inputs first
        form.querySelectorAll('input[name="order_ids[]"]').forEach(input => input.remove());
        
        // Add new hidden inputs
        orderIds.forEach(id => {
            const input = document.createElement('input');
            input.type = 'hidden';
            input.name = 'order_ids[]';
            input.value = id;
            form.appendChild(input);
        });
        
        // Now submit the form
        form.submit();
    });

    // Make table rows clickable (except checkbox cell)
    document.querySelectorAll('tbody tr').forEach(row => {
        row.addEventListener('click', function(e) {
            // Don't navigate if clicking on checkbox
            const clickedCell = e.target.closest('td');
            if (!clickedCell) return;
            
            const checkbox = clickedCell.querySelector('input[type="checkbox"]');
            if (checkbox) {
                // Checkbox column clicked
                return;
            }
            
            // Check if any cell has data-href
            const href = clickedCell.getAttribute('data-href');
            if (href) {
                window.location = href;
            }
        });
    });
    </script>

    {{-- ═══════════════════════════════════════════════════════════════════
    CUSTOM PAGINATION STYLE  (clean, green-themed)
═══════════════════════════════════════════════════════════════════ --}}
    <style>
        
        .pagination-wrap nav {
            display: flex;
            align-items: center;
            gap: 0.25rem;
        }

        .pagination-wrap nav svg {
            width: 1rem;
            height: 1rem;
        }

        .pagination-wrap nav span[aria-current],
        .pagination-wrap nav button[aria-current] {
            background:
            color:
            border-color:
            border-radius: 0.5rem !important;
        }

        .pagination-wrap nav a,
        .pagination-wrap nav button {
            border-radius: 0.5rem !important;
        }
    </style>

    {{-- ═══════════════════════════════════════════════════════════════════
    JS: live search on Enter / blur  (form already submits on select change)
═══════════════════════════════════════════════════════════════════ --}}
    <script>
       
        document.addEventListener('DOMContentLoaded', () => {
            if (typeof lucide !== 'undefined') lucide.createIcons();
        });
    </script>

</x-layouts.admin>