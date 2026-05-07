import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../models/order_model.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<Map<String, String>> _tabs = [
    {'label': 'Semua', 'status': ''},
    {'label': 'Belum Bayar', 'status': 'unpaid'},
    {'label': 'Diproses', 'status': 'processing'},
    {'label': 'Dikirim', 'status': 'shipped'},
    {'label': 'Selesai', 'status': 'completed'},
    {'label': 'Dibatalkan', 'status': 'cancelled'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<OrderProvider>().loadOrders(
          status: _tabs[_tabController.index]['status'],
        );
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Pesanan Saya',
          style: TextStyle(
            color: Color(0xFF1E3A0F),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A0F)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF2D5016),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF2D5016),
          tabs: _tabs.map((t) => Tab(text: t['label'])).toList(),
          tabAlignment: TabAlignment.start,
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D5016)),
            );
          }
          if (provider.error != null) {
            return _buildError(context, provider);
          }
          if (provider.orders.isEmpty) {
            return _buildEmpty();
          }
          return RefreshIndicator(
            color: const Color(0xFF2D5016),
            onRefresh: () => provider.loadOrders(
              status: _tabs[_tabController.index]['status'],
            ),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.orders.length,
              itemBuilder: (context, index) =>
                  _buildOrderCard(context, provider.orders[index], provider),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(
    BuildContext context,
    Order order,
    OrderProvider provider,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: order.id),
          ),
        ).then((_) => provider.loadOrders(
              status: _tabs[_tabController.index]['status'],
            ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E3A0F),
                    ),
                  ),
                  _statusBadge(order.status),
                ],
              ),
            ),
            const Divider(height: 1),
            // Item preview (max 2)
            ...order.items.take(2).map(
              (item) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: Image.network(
                          item.productImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF3F4F6),
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${item.quantity}x ${_currency.format(item.unitPrice)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (order.items.length > 2)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 6),
                child: Text(
                  '+ ${order.items.length - 2} produk lainnya',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Pesanan',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      Text(
                        _currency.format(order.totalPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Color(0xFF2D5016),
                        ),
                      ),
                    ],
                  ),
                  _buildActionButton(context, order, provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    Order order,
    OrderProvider provider,
  ) {
    if (order.status == 'unpaid') {
      return ElevatedButton(
        onPressed: () async {
          final data = await provider.payNow(order.id);
          if (!context.mounted) return;
          if (data.isNotEmpty) {
            _showPaymentInfo(context, data, order.orderNumber);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Bayar',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );
    }
    if (order.status == 'completed') {
      return OutlinedButton(
        onPressed: () async {
          final ok = await provider.buyAgain(order.id);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ok ? 'Produk ditambahkan ke keranjang!' : 'Gagal. Coba lagi.',
              ),
              backgroundColor: ok ? const Color(0xFF2D5016) : Colors.red,
            ),
          );
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF2D5016)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Text(
          'Beli Lagi',
          style: TextStyle(
            color: Color(0xFF2D5016),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _statusBadge(String status) {
    final colors = {
      'pending': (Colors.grey.shade600, Colors.grey.shade100),
      'unpaid': (Colors.orange.shade700, Colors.orange.shade50),
      'processing': (Colors.blue.shade700, Colors.blue.shade50),
      'shipped': (Colors.indigo.shade700, Colors.indigo.shade50),
      'completed': (const Color(0xFF2D5016), const Color(0xFFE8F5E9)),
      'cancelled': (Colors.red.shade700, Colors.red.shade50),
    };

    final labels = {
      'pending': 'Menunggu',
      'unpaid': 'Belum Bayar',
      'processing': 'Diproses',
      'shipped': 'Dikirim',
      'completed': 'Selesai',
      'cancelled': 'Dibatalkan',
    };

    final (textColor, bgColor) =
        colors[status] ?? (Colors.grey, Colors.grey.shade100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        labels[status] ?? status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Color(0xFF4A7C2C),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum ada pesanan',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A0F),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pesananmu akan muncul di sini.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, OrderProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Gagal memuat pesanan', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadOrders(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2D5016),
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _showPaymentInfo(
    BuildContext context,
    Map<String, dynamic> data,
    String orderNumber,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi Pembayaran',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text('Pesanan: $orderNumber'),
            if (data['bank_accounts'] != null)
              ...(data['bank_accounts'] as List<dynamic>).map<Widget>((bank) {
                return Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bank['bank_name'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('No. Rek: ${bank['account_number']}'),
                      Text('a.n. ${bank['account_holder']}'),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5016),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Mengerti'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
