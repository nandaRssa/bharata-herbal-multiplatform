import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/order_provider.dart';
import '../providers/cart_provider.dart';
import '../models/order_model.dart';
import 'review_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrderDetail(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            color: Color(0xFF1E3A0F),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A0F)),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D5016)),
            );
          }
          final order = provider.selectedOrder;
          if (order == null) {
            return const Center(child: Text('Pesanan tidak ditemukan.'));
          }
          return RefreshIndicator(
            color: const Color(0xFF2D5016),
            onRefresh: () =>
                provider.loadOrderDetail(widget.orderId),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatusCard(order),
                const SizedBox(height: 12),
                _buildItemsCard(order),
                const SizedBox(height: 12),
                _buildAddressCard(order),
                const SizedBox(height: 12),
                _buildPriceCard(order),
                const SizedBox(height: 12),
                if (order.trackingNumber != null)
                  _buildTrackingCard(order),
                const SizedBox(height: 12),
                _buildActionsCard(context, order, provider),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(Order order) {
    final colors = {
      'pending': Colors.grey.shade600,
      'unpaid': Colors.orange.shade700,
      'processing': Colors.blue.shade700,
      'shipped': Colors.indigo.shade700,
      'completed': const Color(0xFF2D5016),
      'cancelled': Colors.red.shade700,
    };
    final color = colors[order.status] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.orderNumber,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.statusLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatDate(order.createdAt),
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (order.status == 'unpaid' && order.paymentDeadline != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Bayar sebelum: ${_formatDate(order.paymentDeadline!)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
          if (order.cancelReason != null) ...[
            const SizedBox(height: 8),
            Text(
              'Alasan: ${order.cancelReason}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsCard(Order order) {
    return _card(
      title: 'Produk Dipesan',
      icon: Icons.shopping_bag_outlined,
      child: Column(
        children: order.items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: Image.network(
                          item.productImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: const Color(0xFFF3F4F6),
                            child: const Icon(
                              Icons.image_not_supported,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${item.quantity}x ${_currency.format(item.unitPrice)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currency.format(item.subtotal),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D5016),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Review button per item
                    if (order.status == 'completed' && order.canReview)
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReviewScreen(
                              orderId: order.id,
                              productId: item.productId,
                              productName: item.productName,
                              productImage: item.productImage,
                            ),
                          ),
                        ).then((_) => context
                            .read<OrderProvider>()
                            .loadOrderDetail(widget.orderId)),
                        child: const Text(
                          'Ulas',
                          style: TextStyle(
                            color: Color(0xFF2D5016),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildAddressCard(Order order) {
    if (order.address == null) return const SizedBox.shrink();
    final addr = order.address!;
    return _card(
      title: 'Alamat Pengiriman',
      icon: Icons.location_on_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5016),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  addr.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                addr.recipientName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(addr.fullAddress, style: const TextStyle(fontSize: 13, height: 1.4)),
          const SizedBox(height: 4),
          Text(addr.phone, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildPriceCard(Order order) {
    return _card(
      title: 'Rincian Pembayaran',
      icon: Icons.receipt_outlined,
      child: Column(
        children: [
          _priceRow('Subtotal', _currency.format(order.subtotal)),
          const SizedBox(height: 8),
          _priceRow('Ongkos Kirim', _currency.format(order.shippingCost)),
          const Divider(height: 20),
          _priceRow(
            'Total Pembayaran',
            _currency.format(order.totalPrice),
            bold: true,
          ),
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Catatan: ${order.notes}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackingCard(Order order) {
    return _card(
      title: 'Informasi Pengiriman',
      icon: Icons.local_shipping_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (order.courierName != null)
            Text(
              'Kurir: ${order.courierName}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 4),
          Text(
            'No. Resi: ${order.trackingNumber}',
            style: const TextStyle(fontSize: 14, color: Color(0xFF2D5016)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard(
    BuildContext context,
    Order order,
    OrderProvider provider,
  ) {
    return Column(
      children: [
        // Bayar (unpaid)
        if (order.status == 'unpaid')
          _actionBtn(
            label: 'Bayar Sekarang',
            color: Colors.orange,
            icon: Icons.payment,
            onTap: () async {
              final data = await provider.payNow(order.id);
              if (!context.mounted) return;
              _showPaymentSheet(context, data, order.orderNumber);
            },
          ),
        // Batalkan (pending / unpaid)
        if (order.status == 'pending' || order.status == 'unpaid')
          _actionBtn(
            label: 'Batalkan Pesanan',
            color: Colors.red.shade600,
            icon: Icons.cancel_outlined,
            outlined: true,
            onTap: () => _showCancelDialog(context, order, provider),
          ),
        // Beli Lagi (completed)
        if (order.status == 'completed')
          _actionBtn(
            label: 'Beli Lagi',
            color: const Color(0xFF2D5016),
            icon: Icons.shopping_cart_outlined,
            onTap: () async {
              final ok = await provider.buyAgain(order.id);
              if (!context.mounted) return;
              context.read<CartProvider>().loadCart();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? 'Produk ditambahkan ke keranjang!'
                        : 'Gagal. Coba lagi.',
                  ),
                  backgroundColor: ok ? const Color(0xFF2D5016) : Colors.red,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _actionBtn({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: color),
              label: Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, color: Colors.white),
              label: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF4A7C2C)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1E3A0F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            color: bold ? const Color(0xFF2D5016) : const Color(0xFF1F2937),
            fontSize: bold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm', 'id').format(dt);
    } catch (_) {
      return raw;
    }
  }

  void _showCancelDialog(
    BuildContext context,
    Order order,
    OrderProvider provider,
  ) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Pesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Berikan alasan pembatalan (opsional):'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Alasan pembatalan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kembali'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await provider.cancelOrder(
                order.id,
                reasonCtrl.text,
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Pesanan berhasil dibatalkan' : 'Gagal membatalkan',
                  ),
                  backgroundColor: ok ? const Color(0xFF2D5016) : Colors.red,
                ),
              );
            },
            child: const Text(
              'Batalkan Pesanan',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentSheet(
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
            const SizedBox(height: 8),
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
