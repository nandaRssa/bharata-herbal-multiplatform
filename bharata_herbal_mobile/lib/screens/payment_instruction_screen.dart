import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/order_model.dart';
import 'order_detail_screen.dart';

/// Halaman instruksi pembayaran dengan countdown
class PaymentInstructionScreen extends StatefulWidget {
  final Order order;
  final List<Map<String, dynamic>> bankAccounts;
  final Map<String, dynamic>? ewallet;

  const PaymentInstructionScreen({
    super.key,
    required this.order,
    required this.bankAccounts,
    this.ewallet,
  });

  @override
  State<PaymentInstructionScreen> createState() => _PaymentInstructionScreenState();
}

class _PaymentInstructionScreenState extends State<PaymentInstructionScreen> {
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _expired = false;
  bool _showFullQr = false;

  @override
  void initState() {
    super.initState();
    _initCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initCountdown() {
    final r = widget.order.paymentTimeRemaining;
    if (r == null || r == Duration.zero) {
      setState(() => _expired = true);
      return;
    }
    setState(() => _remaining = r);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final newR = widget.order.paymentTimeRemaining ?? Duration.zero;
      if (newR <= Duration.zero) {
        _timer?.cancel();
        setState(() { _remaining = Duration.zero; _expired = true; });
      } else {
        setState(() => _remaining = newR);
      }
    });
  }

  String _fmt(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$label disalin!'),
      backgroundColor: const Color(0xFF1A5C38),
      behavior: SnackBarBehavior.floating,
    ));
  }

  bool get _isEwallet => widget.ewallet != null;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Instruksi Pembayaran', style: TextStyle(color: Color(0xFF0F3D25), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F3D25)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
            (r) => false),
        ),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        // ─── Countdown ───────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _expired
                  ? [Colors.red.shade700, Colors.red.shade900]
                  : [const Color(0xFF1A5C38), const Color(0xFF16A34A)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            Text(_expired ? '⏰ Pembayaran Kadaluarsa' : '⏳ Selesaikan Pembayaran Dalam',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Text(_expired ? '00:00:00' : _fmt(_remaining),
              style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text('Total: ${_currency.format(order.totalPrice)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ]),
        ),
        if (_expired) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
            child: const Row(children: [
              Icon(Icons.warning_rounded, color: Colors.red),
              SizedBox(width: 10),
              Expanded(child: Text('Waktu pembayaran habis. Pesanan Anda akan otomatis dibatalkan oleh sistem.',
                style: TextStyle(color: Colors.red, fontSize: 13))),
            ]),
          ),
        ],

        const SizedBox(height: 16),

        // ─── Nomor Pesanan ─────────────────────────────────────────
        _infoCard('Informasi Pesanan', [
          _infoRow('No. Pesanan', order.orderNumber),
          _infoRow('Status', order.statusLabel),
        ]),
        const SizedBox(height: 12),

        // ─── E-Wallet Section ──────────────────────────────────────
        if (_isEwallet) ...[
          _buildEwalletSection(),
          const SizedBox(height: 12),
        ],

        // ─── Rekening Tujuan ───────────────────────────────────────
        if (!_isEwallet && widget.bankAccounts.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.account_balance_outlined, size: 18, color: Color(0xFF16A34A)),
                SizedBox(width: 8),
                Text('Rekening Tujuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F3D25))),
              ]),
              const SizedBox(height: 12),
              ...widget.bankAccounts.map((bank) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF16A34A).withValues(alpha: 0.3))),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(bank['bank_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F3D25))),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFF1A5C38), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Aktif', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                  ]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Nomor Rekening', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(bank['account_number'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ]),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Color(0xFF1A5C38)),
                      onPressed: () => _copyToClipboard(bank['account_number'] ?? '', 'Nomor rekening'),
                      tooltip: 'Salin',
                    ),
                  ]),
                  Text('a.n. ${bank['account_holder']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  if (bank['notes'] != null && bank['notes'].toString().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('ℹ️ ${bank['notes']}', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                  ],
                ]),
              )),
            ]),
          ),
          const SizedBox(height: 12),
        ],

        // ─── Jumlah Transfer ───────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(_isEwallet ? Icons.payments_outlined : Icons.payments_outlined, size: 18, color: const Color(0xFF16A34A)),
              const SizedBox(width: 8),
              Text(_isEwallet ? 'Jumlah Pembayaran' : 'Jumlah Transfer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F3D25))),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(_isEwallet ? 'Bayar tepat' : 'Transfer tepat', style: const TextStyle(color: Colors.grey)),
              Row(children: [
                Text(_currency.format(order.totalPrice),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A5C38))),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: Color(0xFF1A5C38), size: 20),
                  onPressed: () => _copyToClipboard(order.totalPrice.toStringAsFixed(0), 'Jumlah pembayaran'),
                  padding: EdgeInsets.zero,
                ),
              ]),
            ]),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(child: Text(
                  _isEwallet ? 'Lakukan pembayaran dengan jumlah TEPAT.' : 'Transfer dengan jumlah TEPAT untuk mempercepat verifikasi.',
                  style: const TextStyle(fontSize: 12, color: Colors.black87))),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // ─── Langkah Pembayaran ─────────────────────────────────────
        if (_isEwallet)
          _buildEwalletSteps()
        else
          _infoCard('Cara Pembayaran', null, customChild: Column(children: [
            _step('1', 'Buka aplikasi mobile banking atau ATM'),
            _step('2', 'Pilih Transfer ke nomor rekening tujuan di atas'),
            _step('3', 'Masukkan nominal TEPAT sesuai jumlah tagihan'),
            _step('4', 'Simpan bukti transfer'),
            _step('5', 'Unggah bukti pembayaran di halaman pesanan'),
          ])),
        const SizedBox(height: 16),

        // ─── Tombol Lihat Pesanan ──────────────────────────────────
        SizedBox(width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushAndRemoveUntil(context,
              MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
              (r) => false),
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Lihat Detail Pesanan & Upload Bukti'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF1A5C38),
              side: const BorderSide(color: Color(0xFF1A5C38)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _buildEwalletSection() {
    final ew = widget.ewallet!;
    final method = widget.order.payment?.method ?? '';
    final labels = <String, String>{
      'dana': 'DANA',
      'gopay': 'GoPay',
      'qris': 'QRIS',
    };
    final label = labels[method] ?? method.toUpperCase();
    final merchant = ew['merchant']?.toString() ?? '';
    final qrCode = ew['qr_code']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.phone_android_outlined, size: 18, color: Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Text('Pembayaran $label', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F3D25))),
        ]),
        const SizedBox(height: 12),
        if (merchant.isNotEmpty) ...[
          _infoRow('Merchant', merchant),
          const SizedBox(height: 8),
        ],
        if (qrCode.isNotEmpty) ...[
          GestureDetector(
            onTap: () => setState(() => _showFullQr = !_showFullQr),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    qrCode,
                    height: _showFullQr ? 250 : 150,
                    width: _showFullQr ? 250 : 150,
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, st) => Container(
                      height: 150, width: 150,
                      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.qr_code_2, size: 48, color: Colors.grey),
                        const SizedBox(height: 4),
                        Text('QR $label', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(_showFullQr ? 'Tap untuk perkecil' : 'Tap untuk perbesar',
                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildEwalletSteps() {
    final method = widget.order.payment?.method ?? '';
    final labels = <String, String>{
      'dana': 'DANA',
      'gopay': 'GoPay',
      'qris': 'QRIS',
    };
    final label = labels[method] ?? method.toUpperCase();

    return _infoCard('Cara Pembayaran $label', null, customChild: Column(children: [
      if (method == 'qris') ...[
        _step('1', 'Buka aplikasi pembayaran (GoPay, DANA, OVO, Mobile Banking)'),
        _step('2', 'Pilih menu Scan QR / QRIS'),
        _step('3', 'Scan kode QR di atas'),
        _step('4', 'Periksa nominal dan konfirmasi pembayaran'),
        _step('5', 'Simpan bukti pembayaran'),
        _step('6', 'Unggah bukti pembayaran di halaman pesanan'),
      ] else ...[
        _step('1', 'Buka aplikasi $label'),
        _step('2', 'Pilih Bayar / Kirim Uang'),
        _step('3', 'Masukkan merchant "$label" tujuan'),
        _step('4', 'Masukkan nominal TEPAT sesuai tagihan'),
        _step('5', 'Konfirmasi dan selesaikan pembayaran'),
        _step('6', 'Simpan bukti pembayaran'),
        _step('7', 'Unggah bukti pembayaran di halaman pesanan'),
      ],
    ]));
  }

  Widget _infoCard(String title, List<Widget>? rows, {Widget? customChild}) =>
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F3D25))),
        const SizedBox(height: 12),
        if (rows != null) ...rows else if (customChild != null) customChild,
      ]),
    );

  Widget _infoRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );

  Widget _step(String num, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(width: 24, height: 24,
        decoration: const BoxDecoration(color: Color(0xFF1A5C38), shape: BoxShape.circle),
        child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 13, height: 1.5))),
    ]),
  );
}
