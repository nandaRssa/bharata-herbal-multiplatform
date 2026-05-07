import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';
import '../models/address_model.dart';
import 'review_screen.dart';
import 'payment_instruction_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _service = OrderService();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _date = DateFormat('dd MMM yyyy, HH:mm');

  Order? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final o = await _service.getOrderDetail(widget.orderId);
      setState(() { _order = o; _isLoading = false; });
    } catch (e) {
      setState(() { _error = 'Gagal memuat detail pesanan'; _isLoading = false; });
    }
  }

  Future<void> _cancelOrder() async {
    final reason = await _showCancelDialog();
    if (reason == null) return;
    final ok = await _service.cancelOrder(widget.orderId, reason);
    if (!mounted) return;
    if (ok) {
      _snack('Pesanan berhasil dibatalkan');
      _load();
    } else {
      _snack('Gagal membatalkan pesanan', isError: true);
    }
  }

  Future<void> _buyAgain() async {
    final ok = await _service.buyAgain(widget.orderId);
    if (!mounted) return;
    if (ok) {
      _snack('Produk ditambahkan ke keranjang!');
    } else {
      _snack('Gagal menambahkan ke keranjang', isError: true);
    }
  }

  Future<void> _payNow() async {
    try {
      final data = await _service.payNow(widget.orderId);
      if (!mounted) return;
      // Arahkan ke halaman instruksi pembayaran dengan data bank
      final bankDetails = data['payment']?['bank_transfer_details'];
      final List<Map<String, dynamic>> banks = bankDetails != null
          ? [Map<String, dynamic>.from(bankDetails)]
          : [];
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => PaymentInstructionScreen(order: _order!, bankAccounts: banks)));
    } catch (e) {
      _snack('Gagal memuat info pembayaran', isError: true);
    }
  }

  Future<String?> _showCancelDialog() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pesanan?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Masukkan alasan pembatalan (opsional):',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Alasan pembatalan...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Tutup')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF2D5016),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_order != null ? _order!.orderNumber : 'Detail Pesanan',
          style: const TextStyle(color: Color(0xFF1E3A0F), fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A0F)),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFF2D5016)))
          : _error != null ? _buildError()
          : _buildBody(),
    );
  }

  Widget _buildError() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.error_outline, size: 60, color: Colors.red),
    const SizedBox(height: 12),
    Text(_error!, style: const TextStyle(color: Colors.grey)),
    const SizedBox(height: 16),
    ElevatedButton(onPressed: _load,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2D5016), foregroundColor: Colors.white),
      child: const Text('Coba Lagi')),
  ]));

  Widget _buildBody() {
    final o = _order!;
    return RefreshIndicator(
      color: const Color(0xFF2D5016),
      onRefresh: _load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        // ─── Status Banner ─────────────────────────────────────────
        _statusBanner(o),
        const SizedBox(height: 12),

        // ─── Status Timeline ──────────────────────────────────────
        if (!o.isCancelled) ...[_timelineCard(o), const SizedBox(height: 12)],

        // ─── Informasi Pesanan ─────────────────────────────────────
        _card('Informasi Pesanan', child: Column(children: [
          _row('No. Pesanan', o.orderNumber),
          _row('Tanggal', _safeDate(o.createdAt)),
          if (o.notes != null && o.notes!.isNotEmpty) _row('Catatan', o.notes!),
          if (o.courierName != null) _row('Kurir', o.courierName!),
          if (o.trackingNumber != null) _row('No. Resi', o.trackingNumber!),
          if (o.cancelReason != null && o.cancelReason!.isNotEmpty) _row('Alasan Batal', o.cancelReason!, valueColor: Colors.red),
        ])),
        const SizedBox(height: 12),

        // ─── Produk ────────────────────────────────────────────────
        _productsCard(o),
        const SizedBox(height: 12),

        // ─── Ringkasan Harga ───────────────────────────────────────
        _priceCard(o),
        const SizedBox(height: 12),

        // ─── Alamat Pengiriman ─────────────────────────────────────
        if (o.address != null) ...[_addressCard(o.address!), const SizedBox(height: 12)],

        // ─── Informasi Pembayaran ──────────────────────────────────
        if (o.payment != null) ...[_paymentCard(o.payment!), const SizedBox(height: 12)],

        // ─── Action Buttons ────────────────────────────────────────
        _actionsCard(o),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _statusBanner(Order o) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(o.statusColor), Color(o.statusColor).withValues(alpha: 0.7)],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(children: [
      Text(o.statusIcon, style: const TextStyle(fontSize: 32)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(o.statusLabel, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(_statusDescription(o.status), style: const TextStyle(color: Colors.white70, fontSize: 13)),
        if (o.needsPayment && o.paymentDeadline != null) ...[
          const SizedBox(height: 6),
          Text('Bayar sebelum: ${_safeDate(o.paymentDeadline!)}',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ])),
    ]),
  );

  Widget _timelineCard(Order o) => _card('Status Pesanan', child: Column(children: [
    ...o.statusTimeline.asMap().entries.map((entry) {
      final i = entry.key;
      final step = entry.value;
      final isLast = i == o.statusTimeline.length - 1;
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.isCompleted ? const Color(0xFF2D5016) : Colors.grey.shade300,
              border: step.isCurrent ? Border.all(color: const Color(0xFF2D5016), width: 3) : null,
            ),
            child: step.isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          if (!isLast)
            Container(width: 2, height: 30, color: step.isCompleted ? const Color(0xFF2D5016) : Colors.grey.shade300),
        ]),
        const SizedBox(width: 12),
        Padding(padding: const EdgeInsets.only(top: 3),
          child: Text(step.label,
            style: TextStyle(
              fontWeight: step.isCurrent ? FontWeight.bold : FontWeight.normal,
              color: step.isCompleted ? const Color(0xFF2D5016) : Colors.grey,
              fontSize: 13,
            ))),
      ]);
    }),
  ]));

  Widget _productsCard(Order o) => _card('Produk (${o.items.length} item)', child: Column(
    children: o.items.map((item) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 60, height: 60, child: Image.network(item.productImage, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF3F4F6), child: const Icon(Icons.image_not_supported, color: Colors.grey))))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text('${item.quantity}x ${_currency.format(item.unitPrice)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ])),
        Text(_currency.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D5016))),
      ]),
    )).toList(),
  ));

  Widget _priceCard(Order o) => _card('Ringkasan Harga', child: Column(children: [
    _row('Subtotal Produk', _currency.format(o.subtotal)),
    _row('Ongkos Kirim', _currency.format(o.shippingCost)),
    const Divider(height: 20),
    _row('Total Pembayaran', _currency.format(o.totalPrice), bold: true),
  ]));

  Widget _addressCard(Address address) => _card('Alamat Pengiriman', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFF2D5016), borderRadius: BorderRadius.circular(6)),
        child: Text(address.label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
      const SizedBox(width: 8),
      Text(address.recipientName, style: const TextStyle(fontWeight: FontWeight.bold)),
    ]),
    const SizedBox(height: 6),
    Text(address.fullAddress, style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87)),
    const SizedBox(height: 4),
    Text(address.phone, style: const TextStyle(fontSize: 13, color: Colors.grey)),
  ]));

  Widget _paymentCard(OrderPayment payment) => _card('Informasi Pembayaran', child: Column(children: [
    _row('Metode', payment.methodLabel),
    _row('Status', payment.status == 'paid' ? '✅ Lunas' : '⏳ Menunggu'),
    _row('Jumlah', _currency.format(payment.amount)),
    if (payment.paidAt != null) _row('Dibayar', _safeDate(payment.paidAt!)),
  ]));

  Widget _actionsCard(Order o) => _card('Aksi Pesanan', child: Column(children: [
    if (o.needsPayment) ...[
      _primaryBtn('💳  Bayar Sekarang', Colors.red, _payNow),
      const SizedBox(height: 8),
    ],
    if (o.canBeCancelled) ...[
      _outlineBtn('Batalkan Pesanan', Colors.red, _cancelOrder),
      const SizedBox(height: 8),
    ],
    if (o.isCompleted && o.canReview) ...[
      _primaryBtn('⭐  Beri Ulasan', const Color(0xFF2D5016), () {
        if (o.items.isNotEmpty) {
          final item = o.items.first;
          Navigator.push(context, MaterialPageRoute(builder: (_) => ReviewScreen(
            orderId: o.id, productId: item.productId,
            productName: item.productName, productImage: item.productImage)));
        }
      }),
      const SizedBox(height: 8),
    ],
    if (o.isCompleted || o.isCancelled) ...[
      _outlineBtn('🔄  Pesan Lagi', const Color(0xFF2D5016), _buyAgain),
    ],
  ]));

  Widget _primaryBtn(String label, Color color, VoidCallback onTap) =>
    SizedBox(width: double.infinity,
      child: ElevatedButton(onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))));

  Widget _outlineBtn(String label, Color color, VoidCallback onTap) =>
    SizedBox(width: double.infinity,
      child: OutlinedButton(onPressed: onTap,
        style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))));

  Widget _card(String title, {required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A0F))),
      const SizedBox(height: 12),
      child,
    ]),
  );

  Widget _row(String label, String value, {bool bold = false, Color? valueColor}) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      Flexible(child: Text(value, textAlign: TextAlign.end,
        style: TextStyle(fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
          fontSize: bold ? 16 : 13, color: valueColor ?? (bold ? const Color(0xFF2D5016) : const Color(0xFF1F2937))))),
    ]),
  );

  String _statusDescription(String s) {
    const desc = {
      'unpaid': 'Selesaikan pembayaran untuk melanjutkan',
      'pending': 'Pesanan sedang menunggu konfirmasi toko',
      'processing': 'Pesanan sedang dikemas oleh penjual',
      'shipped': 'Pesanan dalam perjalanan ke alamat kamu',
      'completed': 'Pesanan telah berhasil diterima',
      'cancelled': 'Pesanan ini telah dibatalkan',
    };
    return desc[s] ?? '';
  }

  String _safeDate(String raw) {
    try { return _date.format(DateTime.parse(raw)); } catch (_) { return raw; }
  }
}
