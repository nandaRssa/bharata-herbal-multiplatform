import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';
import 'order_detail_screen.dart';
import 'review_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
  final OrderService _service = OrderService();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _date = DateFormat('dd MMM yyyy');
  late TabController _tab;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;

  // Cache per tab
  final Map<int, List<Order>> _cache = {};
  final Map<int, int> _currentPage = {};
  final Map<int, bool> _hasMore = {};
  final Map<int, ScrollController> _scrollControllers = {};

  static const _tabs = [
    ('', 'Semua'),
    ('pending', 'Menunggu'),
    ('paid', 'Sudah Bayar'),
    ('processing', 'Diproses'),
    ('shipped', 'Dikirim'),
    ('completed', 'Selesai'),
    ('cancelled', 'Dibatalkan'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _tab.addListener(() { if (!_tab.indexIsChanging) _loadTab(_tab.index); });
    _loadTab(0);
  }

  @override
  void dispose() {
    _tab.dispose();
    for (final ctrl in _scrollControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  ScrollController _getScrollController(int idx) {
    if (!_scrollControllers.containsKey(idx)) {
      final ctrl = ScrollController();
      ctrl.addListener(() {
        if (ctrl.position.pixels >= ctrl.position.maxScrollExtent - 250) {
          _loadMore(idx);
        }
      });
      _scrollControllers[idx] = ctrl;
    }
    return _scrollControllers[idx]!;
  }

  Future<void> _loadTab(int idx, {bool force = false}) async {
    if (_cache.containsKey(idx) && !force) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      final status = _tabs[idx].$1;
      final result = await _service.getOrders(status: status.isEmpty ? null : status);
      final orders = result['orders'] as List<Order>;
      final hasMore = result['has_more'] as bool;
      setState(() {
        _cache[idx] = orders;
        _currentPage[idx] = 1;
        _hasMore[idx] = hasMore;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = 'Gagal memuat pesanan'; _isLoading = false; });
    }
  }

  Future<void> _loadMore(int idx) async {
    final page = _currentPage[idx] ?? 1;
    final hasMore = _hasMore[idx] ?? false;
    if (!hasMore || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final status = _tabs[idx].$1;
      final result = await _service.getOrders(
        status: status.isEmpty ? null : status,
        page: page + 1,
      );
      final newOrders = result['orders'] as List<Order>;
      final more = result['has_more'] as bool;
      setState(() {
        _cache[idx] = [...(_cache[idx] ?? []), ...newOrders];
        _currentPage[idx] = page + 1;
        _hasMore[idx] = more;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _openReview(Order order) async {
    final detail = await _service.getOrderDetail(order.id);
    if (!mounted) return;
    final reviewedIds = detail.reviewedProductIds;
    final toReview = detail.items.where((item) => !reviewedIds.contains(item.productId)).toList();

    if (toReview.isEmpty) {
      _snack('Semua produk sudah diulas');
      return;
    }

    if (toReview.length == 1) {
      final item = toReview.first;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(
        orderId: detail.id, productId: item.productId,
        productName: item.productName, productImage: item.productImage)));
    } else {
      _showReviewPicker(detail);
    }
  }

  void _showReviewPicker(Order o) {
    final toReview = o.items.where((item) => !o.isProductReviewed(item.productId)).toList();
    final reviewed = o.items.where((item) => o.isProductReviewed(item.productId)).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pilih Produk untuk Diulas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F3D25))),
            const SizedBox(height: 4),
            Text('${toReview.length} produk belum diulas', style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            ...toReview.map((item) => GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(
                  orderId: o.id, productId: item.productId,
                  productName: item.productName, productImage: item.productImage)));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8),
                    child: SizedBox(width: 48, height: 48, child: Image.network(item.productImage, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF3F4F6), child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 20))))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('${item.quantity}x ${_currency.format(item.unitPrice)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ])),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A5C38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Beri Ulasan', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ]),
              ),
            )),
            if (reviewed.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${reviewed.length} produk sudah diulas', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ]),
        ),
      ),
    );
  }

  Future<void> _buyAgain(Order order) async {
    final ok = await _service.buyAgain(order.id);
    if (!mounted) return;
    if (ok) {
      _snack('Produk ditambahkan ke keranjang!');
    } else {
      _snack('Gagal menambahkan ke keranjang', isError: true);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF1A5C38),
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _refresh() async {
    _cache.clear();
    _currentPage.clear();
    _hasMore.clear();
    await _loadTab(_tab.index, force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Pesanan Saya', style: TextStyle(color: Color(0xFF0F3D25), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0F3D25)),
        bottom: TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: const Color(0xFF1A5C38),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF1A5C38),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: List.generate(_tabs.length, (i) => _buildTabContent(i)),
      ),
    );
  }

  Widget _buildTabContent(int idx) {
    if (_isLoading && !_cache.containsKey(idx)) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (_, __) => _skeletonCard(),
      );
    }
    if (_error != null && !_cache.containsKey(idx)) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, size: 56, color: Colors.red),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => _loadTab(idx, force: true),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5C38), foregroundColor: Colors.white),
          child: const Text('Coba Lagi')),
      ]));
    }

    final orders = _cache[idx] ?? [];
    final hasMore = _hasMore[idx] ?? false;
    if (orders.isEmpty) return _emptyState();

    return RefreshIndicator(
      color: const Color(0xFF1A5C38),
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _getScrollController(idx),
        padding: const EdgeInsets.all(16),
        itemCount: orders.length + (hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == orders.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A5C38)),
              )),
            );
          }
          return _orderCard(orders[i]);
        },
      ),
    );
  }

  Widget _orderCard(Order order) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)));
        _refresh();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(order.statusIcon, size: 18, color: const Color(0xFF1A5C38)),
                const SizedBox(width: 6),
                Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
              _statusBadge(order),
            ]),
          ),
          const Divider(height: 1),

          // Thumbnail produk + nama
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              ...order.items.take(2).map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  ClipRRect(borderRadius: BorderRadius.circular(8),
                    child: SizedBox(width: 52, height: 52, child: Image.network(
                      item.productImage, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF3F4F6),
                        child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 20)),
                    )),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('${item.quantity}x ${_currency.format(item.unitPrice)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ])),
                ]),
              )),
              if (order.items.length > 2)
                Align(alignment: Alignment.centerLeft,
                  child: Text('+${order.items.length - 2} produk lainnya',
                    style: const TextStyle(fontSize: 12, color: Colors.grey))),
            ]),
          ),
          const Divider(height: 1),

          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_safeDate(order.createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 2),
                Text('Total ${_currency.format(order.totalPrice)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F3D25))),
              ]),
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (order.needsPayment)
                  _actionBtn('Bayar', isPrimary: true, onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)))),
                if (order.isCompleted)
                  _actionBtn('Beri Ulasan', isPrimary: true, onTap: () => _openReview(order)),
                if (order.isCompleted)
                  _actionBtn('Beli Lagi', onTap: () => _buyAgain(order)),
                if (!order.needsPayment && !order.isCompleted)
                  _actionBtn('Detail', onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)))),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _statusBadge(Order order) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: Color(order.statusColor).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(order.statusLabel, style: TextStyle(color: Color(order.statusColor), fontSize: 11, fontWeight: FontWeight.bold)),
  );

  Widget _actionBtn(String label, {bool isPrimary = false, required VoidCallback onTap}) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFF1A5C38) : Colors.transparent,
          border: Border.all(color: const Color(0xFF1A5C38)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.bold,
          color: isPrimary ? Colors.white : const Color(0xFF1A5C38))),
      ),
    );

  Widget _emptyState() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Image.network('https://cdn-icons-png.flaticon.com/512/4076/4076478.png', width: 100,
      errorBuilder: (_, __, ___) => const Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey)),
    const SizedBox(height: 16),
    const Text('Belum ada pesanan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF374151))),
    const SizedBox(height: 8),
    const Text('Pesanan kamu akan muncul di sini', style: TextStyle(color: Colors.grey)),
  ]));

  Widget _skeletonCard() => Container(
    margin: const EdgeInsets.only(bottom: 12),
    height: 140,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: const _SkeletonBox(),
  );

  String _safeDate(String raw) {
    try { return _date.format(DateTime.parse(raw)); } catch (_) { return raw; }
  }
}

class _SkeletonBox extends StatefulWidget {
  const _SkeletonBox();
  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this)..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.withValues(alpha: _anim.value),
      ),
    ),
  );
}
