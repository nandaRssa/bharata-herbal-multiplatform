import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../models/order_model.dart';
import '../models/address_model.dart';
import '../models/product_model.dart';
import 'review_screen.dart';
import 'product_detail_screen.dart';
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
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF1A5C38), size: 56),
          title: const Text('Pesanan Dibatalkan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: const Text('Dana akan dikembalikan dan pesanan berhasil dibatalkan.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, height: 1.5)),
          actions: [ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5C38), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('OK'))],
        ),
      );
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

  Future<void> _confirmReceived() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Penerimaan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Apakah kamu sudah menerima pesanan ini? Pastikan semua produk sudah diterima dengan baik sebelum konfirmasi.',
          style: TextStyle(fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Belum')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5C38), foregroundColor: Colors.white),
            child: const Text('Ya, Sudah Terima'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await _service.confirmReceived(widget.orderId);
    if (!mounted) return;
    if (ok) {
      _snack('Pesanan dikonfirmasi sebagai diterima!');
      _load();
    } else {
      _snack('Gagal mengkonfirmasi pesanan', isError: true);
    }
  }

  Future<void> _uploadProof() async {
    final picker = ImagePicker();
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Upload Bukti Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        content: const Text('Pilih sumber foto bukti transfer:'),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Kamera'),
          ),
          TextButton.icon(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Galeri'),
          ),
        ],
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    try {
      final url = await _service.uploadPaymentProof(widget.orderId, File(picked.path));
      if (!mounted) return;
      if (url.isNotEmpty) {
        _snack('Bukti bayar berhasil diunggah! Admin akan mengkonfirmasi segera.');
        _load();
      } else {
        _snack('Gagal mengunggah bukti bayar', isError: true);
      }
    } catch (e) {
      if (mounted) _snack('Gagal: ${e.toString()}', isError: true);
    }
  }

  Future<void> _payNow() async {
    // Langsung arahkan ke upload bukti pembayaran
    _uploadProof();
  }

  void _showReviewPicker(Order o) {
    final productsToReview = o.items.where((item) => !o.isProductReviewed(item.productId)).toList();
    final productsReviewed = o.items.where((item) => o.isProductReviewed(item.productId)).toList();

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
            const Text('Ulasan Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F3D25))),
            const SizedBox(height: 4),
            Text('${o.items.length} produk dalam pesanan', style: const TextStyle(fontSize: 13, color: Colors.grey)),
            if (productsToReview.isEmpty && productsReviewed.isEmpty)
              const Padding(padding: EdgeInsets.only(top: 16), child: Text('Tidak ada produk dalam pesanan ini.', style: TextStyle(color: Colors.grey)))
            else ...[
              if (productsToReview.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Belum diulas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF1A5C38))),
                const SizedBox(height: 8),
                ...productsToReview.map((item) => GestureDetector(
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
              ],
              if (productsReviewed.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Sudah diulas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 8),
                ...productsReviewed.map((item) => GestureDetector(
                  onTap: () async {
                    Navigator.pop(ctx);
                    final prod = await ProductService().getProductById(item.productId);
                    if (!context.mounted) return;
                    if (prod != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: prod)));
                    } else {
                      _snack('Gagal memuat produk', isError: true);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(children: [
                      ClipRRect(borderRadius: BorderRadius.circular(8),
                        child: SizedBox(width: 48, height: 48, child: Image.network(item.productImage, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(color: const Color(0xFFF3F4F6), child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 20))))),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                      const Icon(Icons.check_circle, color: Color(0xFF1A5C38), size: 20),
                      const SizedBox(width: 4),
                      const Text('Lihat', style: TextStyle(color: Color(0xFF1A5C38), fontWeight: FontWeight.bold, fontSize: 12)),
                    ]),
                  ),
                )),
              ],
            ],
          ]),
        ),
      ),
    );
  }

  Future<String?> _showCancelDialog() async {
    // Pilihan alasan preset sesuai spesifikasi
    const presetReasons = [
      'Berubah pikiran',
      'Menemukan harga lebih murah',
      'Salah memilih produk',
      'Pengiriman terlalu lama',
      'Lainnya',
    ];

    String? selected = presetReasons.first;
    final customCtrl = TextEditingController();
    bool showCustom = false;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(children: [
            Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
            SizedBox(width: 8),
            Text('Batalkan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ]),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Pilih alasan pembatalan:', style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 8),
              ...presetReasons.map((reason) => InkWell(
                onTap: () => setDlgState(() {
                  selected = reason;
                  showCustom = reason == 'Lainnya';
                }),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected == reason ? const Color(0xFFFEF2F2) : Colors.transparent,
                    border: Border.all(color: selected == reason ? Colors.red.shade300 : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    Radio<String>(
                      value: reason,
                      groupValue: selected,
                      activeColor: Colors.red,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      onChanged: (v) => setDlgState(() {
                        selected = v;
                        showCustom = v == 'Lainnya';
                      }),
                    ),
                    const SizedBox(width: 4),
                    Expanded(child: Text(reason,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: selected == reason ? FontWeight.w600 : FontWeight.normal,
                        color: selected == reason ? Colors.red.shade700 : Colors.black87,
                      ))),
                  ]),
                ),
              )),
              if (showCustom) ...[
                const SizedBox(height: 8),
                TextField(
                  controller: customCtrl,
                  maxLines: 2,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan alasan lainnya...',
                    hintStyle: const TextStyle(fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.all(12),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ]),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx, null),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Tutup'),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = showCustom
                    ? (customCtrl.text.trim().isEmpty ? 'Lainnya' : customCtrl.text.trim())
                    : (selected ?? presetReasons.first);
                Navigator.pop(ctx, reason);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Ya, Batalkan'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF1A5C38),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_order != null ? _order!.orderNumber : 'Detail Pesanan',
          style: const TextStyle(color: Color(0xFF0F3D25), fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F3D25)),
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A5C38)))
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
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5C38), foregroundColor: Colors.white),
      child: const Text('Coba Lagi')),
  ]));

  Widget _buildBody() {
    final o = _order!;
    return RefreshIndicator(
      color: const Color(0xFF1A5C38),
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
          if (o.courierLabel != null || o.courierName != null) _row('Kurir', o.courierLabel ?? o.courierName!),
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
      Icon(o.statusIcon, size: 32, color: Colors.white),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(o.statusLabel, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(_statusDescription(o), style: const TextStyle(color: Colors.white70, fontSize: 13)),
        if (o.needsPayment && o.paymentDeadline != null) ...[
          const SizedBox(height: 6),
          Text('Bayar sebelum: ${_safeDate(o.paymentDeadline!)}',
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ])),
    ]),
  );

  Widget _timelineCard(Order o) {
    // Use real tracking updates if available, else fallback to status timeline
    if (o.trackingUpdates.isNotEmpty) {
      return _card('Tracking Pengiriman', child: Column(children: [
        ...o.trackingUpdates.reversed.toList().asMap().entries.map((entry) {
          final i = entry.key;
          final t = entry.value;
          final isFirst = i == 0;
          final isLast = i == o.trackingUpdates.length - 1;
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Column(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFirst ? const Color(0xFF1A5C38) : Colors.grey.shade300,
                  boxShadow: isFirst ? [BoxShadow(color: const Color(0xFF1A5C38).withValues(alpha: 0.3), blurRadius: 6)] : [],
                ),
                child: Icon(
                  isFirst ? Icons.local_shipping_rounded : Icons.circle, 
                  color: isFirst ? Colors.white : Colors.grey.shade500, 
                  size: isFirst ? 16 : 8,
                ),
              ),
              if (!isLast) Container(width: 2, height: 40, color: Colors.grey.shade300),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.keterangan, style: TextStyle(fontWeight: isFirst ? FontWeight.bold : FontWeight.normal, color: isFirst ? const Color(0xFF0F3D25) : Colors.black87, fontSize: 13)),
                const SizedBox(height: 2),
                Text(t.lokasi, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                if (t.createdAt != null) Text(_safeDate(t.createdAt!), style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ]),
            )),
          ]);
        }),
      ]));
    }

    return _card('Status Pesanan', child: Column(children: [
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
                color: step.isCompleted ? const Color(0xFF1A5C38) : Colors.grey.shade300,
                border: step.isCurrent ? Border.all(color: const Color(0xFF1A5C38), width: 3) : null,
              ),
              child: step.isCompleted ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
            ),
            if (!isLast) Container(width: 2, height: 30, color: step.isCompleted ? const Color(0xFF1A5C38) : Colors.grey.shade300),
          ]),
          const SizedBox(width: 12),
          Padding(padding: const EdgeInsets.only(top: 3),
            child: Text(step.label, style: TextStyle(
              fontWeight: step.isCurrent ? FontWeight.bold : FontWeight.normal,
              color: step.isCompleted ? const Color(0xFF1A5C38) : Colors.grey,
              fontSize: 13,
            ))),
        ]);
      }),
    ]));
  }

  Widget _productsCard(Order o) => _card('Produk (${o.items.length} item)', child: Column(
    children: o.items.map((item) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(8),
          child: SizedBox(width: 60, height: 60, child: Image.network(item.productImage, fit: BoxFit.cover,
            errorBuilder: (ctx, err, st) => Container(color: const Color(0xFFF3F4F6), child: const Icon(Icons.image_not_supported, color: Colors.grey))))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          Text('${item.quantity}x ${_currency.format(item.unitPrice)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ])),
        Text(_currency.format(item.subtotal), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A5C38))),
      ]),
    )).toList(),
  ));

  Widget _priceCard(Order o) => _card('Ringkasan Harga', child: Column(children: [
    _row('Subtotal Produk', _currency.format(o.subtotal)),
    _row('Ongkos Kirim', _currency.format(o.shippingCost)),
    if ((o.discountAmount ?? 0) > 0)
      _row('Diskon Voucher', '- ${_currency.format(o.discountAmount!)}', valueColor: Colors.green.shade700),
    const Divider(height: 20),
    _row('Total Pembayaran', _currency.format(o.totalPrice), bold: true),
  ]));

  Widget _addressCard(Address address) => _card('Alamat Pengiriman', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xFF1A5C38), borderRadius: BorderRadius.circular(6)),
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
    _row('Status', payment.statusLabel),
    _row('Jumlah', _currency.format(payment.amount)),
    if (payment.paidAt != null) _row('Dibayar', _safeDate(payment.paidAt!)),
  ]));

  Widget _actionsCard(Order o) => _card('Aksi Pesanan', child: Column(children: [
    if (o.canPayNow) ...[
      _primaryBtn('Bayar Sekarang', Icons.credit_card_rounded, Colors.red, _payNow),
      const SizedBox(height: 8),
    ],
    if (o.canUploadPaymentProof) ...[
      _primaryBtn('Upload Bukti Pembayaran', Icons.camera_alt_rounded, Colors.orange.shade700, _uploadProof),
      const SizedBox(height: 8),
    ],
    // Konfirmasi Terima — when status = shipped
    if (o.canConfirmReceived) ...[
      _primaryBtn('Konfirmasi Pesanan Diterima', Icons.check_circle_rounded, const Color(0xFF1A5C38), _confirmReceived),
      const SizedBox(height: 8),
    ],
    if (o.canBeCancelled) ...[
      _outlineBtn('Batalkan Pesanan', Icons.cancel_outlined, Colors.red, _cancelOrder),
      const SizedBox(height: 8),
    ],
    if (o.isCompleted) ...[
      if (o.items.any((item) => !o.isProductReviewed(item.productId)))
        _primaryBtn('Beri Ulasan', Icons.star_rounded, const Color(0xFF1A5C38), () => _showReviewPicker(o))
      else
        _primaryBtn('Lihat Ulasan', Icons.rate_review_rounded, const Color(0xFF0F3D25), () => _showReviewPicker(o)),
      const SizedBox(height: 8),
      _outlineBtn('Beli Lagi', Icons.refresh_rounded, const Color(0xFF1A5C38), _buyAgain),
    ],
    if (o.isCancelled) ...[
      _outlineBtn('Beli Lagi', Icons.refresh_rounded, const Color(0xFF1A5C38), _buyAgain),
    ],
  ]));

  Widget _primaryBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
    SizedBox(width: double.infinity,
      child: ElevatedButton.icon(onPressed: onTap, icon: Icon(icon, size: 18),
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))));

  Widget _outlineBtn(String label, IconData icon, Color color, VoidCallback onTap) =>
    SizedBox(width: double.infinity,
      child: OutlinedButton.icon(onPressed: onTap, icon: Icon(icon, size: 18),
        style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))));

  Widget _card(String title, {required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F3D25))),
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
          fontSize: bold ? 16 : 13, color: valueColor ?? (bold ? const Color(0xFF1A5C38) : const Color(0xFF1F2937))))),
    ]),
  );

  String _statusDescription(Order order) {
    if (order.status == 'pending') {
      return order.needsPayment
          ? 'Selesaikan pembayaran dan unggah bukti transfer agar pesanan bisa diproses'
          : 'Pesanan sudah masuk dan menunggu diproses oleh admin';
    }

    const desc = {
      'paid': 'Pembayaran sudah diverifikasi dan siap diproses',
      'processing': 'Pesanan sedang dikemas oleh penjual',
      'shipped': 'Pesanan dalam perjalanan ke alamat kamu',
      'completed': 'Pesanan telah berhasil diterima',
      'cancelled': 'Pesanan ini telah dibatalkan',
    };
    return desc[order.status] ?? '';
  }

  String _safeDate(String raw) {
    try { return _date.format(DateTime.parse(raw)); } catch (_) { return raw; }
  }
}
