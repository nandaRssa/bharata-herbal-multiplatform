import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dio/dio.dart';
import '../services/checkout_service.dart';
import '../services/notification_service.dart';
import '../services/voucher_service.dart';
import '../models/address_model.dart';
import '../providers/cart_provider.dart';
import 'address_form_screen.dart';
import 'order_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CheckoutService _service = CheckoutService();
  final VoucherService _voucherService = VoucherService();
  final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final _notesCtrl = TextEditingController();
  final _voucherCtrl = TextEditingController();

  CheckoutSummary? _summary;
  bool _isLoading = true;
  bool _isPlacing = false;
  bool _isValidatingVoucher = false;
  String? _error;
  Address? _selectedAddress;
  PaymentOption? _selectedPayment;
  ShippingCourier? _selectedCourier;

  // Applied voucher state
  VoucherResult? _appliedVoucher;
  String? _voucherError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _voucherCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final s = await _service.getCheckoutSummary();
      setState(() {
        _summary = s;
        _selectedAddress = s.defaultAddress ?? (s.addresses.isNotEmpty ? s.addresses.first : null);
        _selectedPayment = s.paymentOptions.isNotEmpty ? s.paymentOptions.first : null;
        _selectedCourier = s.findCourier(s.defaultCourierCode) ??
            (s.couriers.isNotEmpty ? s.couriers.first : null);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Keranjang kosong atau tidak ada item dipilih.\nKembali dan pilih produk di keranjang.';
        _isLoading = false;
      });
    }
  }

  /// Current total including COD fee and voucher discount
  double get _currentTotal {
    if (_summary == null || _selectedPayment == null) return 0;
    return _summary!.totalFor(
      _selectedPayment!,
      courier: _selectedCourier,
      discount: _appliedVoucher?.discountAmount.toDouble() ?? 0,
    );
  }

  Future<void> _applyVoucher() async {
    final code = _voucherCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() { _isValidatingVoucher = true; _voucherError = null; _appliedVoucher = null; });
    try {
      final result = await _voucherService.validateVoucher(
        code: code,
        subtotal: _summary!.subtotal,
      );
      setState(() { _appliedVoucher = result; _isValidatingVoucher = false; });
      _snack('Voucher ${result.code} diterapkan! Hemat ${_currency.format(result.discountAmount)}');
    } catch (e) {
      setState(() {
        _voucherError = e.toString().replaceAll('Exception:', '').trim();
        _isValidatingVoucher = false;
      });
    }
  }

  void _removeVoucher() {
    setState(() { _appliedVoucher = null; _voucherError = null; _voucherCtrl.clear(); });
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      _snack('Pilih alamat pengiriman terlebih dahulu', isError: true);
      return;
    }
    if (_selectedPayment == null) {
      _snack('Pilih metode pembayaran terlebih dahulu', isError: true);
      return;
    }
    if (_summary?.usesCourierSelection == true && _selectedCourier == null) {
      _snack('Pilih kurir pengiriman terlebih dahulu', isError: true);
      return;
    }
    final confirm = await _showConfirmDialog();
    if (!confirm) return;

    setState(() => _isPlacing = true);
    try {
      final result = await _service.placeOrder(
        addressId: _selectedAddress!.id,
        paymentOption: _selectedPayment!,
        courierCode: _summary?.usesCourierSelection == true ? _selectedCourier?.code : null,
        notes: _notesCtrl.text.trim(),
        voucherCode: _appliedVoucher?.code,
      );
      if (!mounted) return;

      if (result['success'] == true) {
        context.read<CartProvider>().clearCart();
        final orderId = result['data']['order_id'] as int;
        final orderNumber = result['data']['order_number']?.toString() ?? '#$orderId';
        await NotificationService().showCheckoutSuccessNotification(
          orderNumber, _currency.format(_currentTotal));

        if (!mounted) return;
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)));
      } else {
        _snack(result['message'] ?? 'Gagal membuat pesanan', isError: true);
      }
    } catch (e) {
      String msg = 'Terjadi kesalahan. Silakan coba lagi.';
      if (e is DioException && e.response?.data is Map) {
        final apiMsg = (e.response!.data as Map)['message']?.toString();
        if (apiMsg != null && apiMsg.isNotEmpty) msg = apiMsg;
      } else if (e is DioException) {
        msg = 'Gagal terhubung ke server. Periksa koneksi Anda.';
      }
      _snack(msg, isError: true);
    } finally {
      if (mounted) setState(() => _isPlacing = false);
    }
  }

  Future<bool> _showConfirmDialog() async {
    if (!mounted) return false;
    final isCod = _selectedPayment?.backendValue == 'cod';
    return await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Total: ${_currency.format(_currentTotal)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A5C38))),
          const SizedBox(height: 8),
          Text('Metode: ${_selectedPayment?.label ?? "-"}'),
          if (isCod && (_summary?.codFee ?? 0) > 0)
            Text('  (termasuk biaya COD ${_currency.format(_summary!.codFee)})',
              style: const TextStyle(fontSize: 12, color: Colors.orange)),
          if (_summary?.usesCourierSelection == true && _selectedCourier != null) ...[
            const SizedBox(height: 4),
            Text('Kurir: ${_selectedCourier!.label}'),
            Text('Estimasi: ${_selectedCourier!.estimatedDays} hari',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
          const SizedBox(height: 4),
          Text('Ke: ${_selectedAddress?.recipientName ?? "-"}',
            style: const TextStyle(color: Colors.grey)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5C38), foregroundColor: Colors.white),
            child: const Text('Buat Pesanan'),
          ),
        ],
      ),
    ) ?? false;
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
        title: const Text('Checkout', style: TextStyle(color: Color(0xFF0F3D25), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Color(0xFF0F3D25)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1A5C38)))
          : _error != null ? _buildError()
          : _buildBody(),
    );
  }

  Widget _buildError() => Center(
    child: Padding(padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
        const SizedBox(height: 16),
        Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 15, height: 1.6)),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Kembali ke Keranjang'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A5C38), foregroundColor: Colors.white),
        ),
      ]),
    ),
  );

  Widget _buildBody() {
    final s = _summary!;
    return Column(children: [
      Expanded(child: ListView(padding: const EdgeInsets.all(16), children: [
        _addressCard(s),
        const SizedBox(height: 12),
        _itemsCard(s),
        if (s.usesCourierSelection) ...[
          const SizedBox(height: 12),
          _courierCard(s),
        ],
        const SizedBox(height: 12),
        _paymentMethodCard(s),
        if (_selectedPayment?.backendValue == 'bank_transfer' && s.bankAccounts.isNotEmpty) ...[
          const SizedBox(height: 12),
          _bankInfoCard(s),
        ],
        const SizedBox(height: 12),
        _voucherCard(s),
        const SizedBox(height: 12),
        _notesCard(),
        const SizedBox(height: 12),
        _priceSummaryCard(s),
        const SizedBox(height: 8),
      ])),
      _bottomCheckoutBar(s),
    ]);
  }

  Widget _addressCard(CheckoutSummary s) => _card(
    title: 'Alamat Pengiriman', icon: Icons.location_on_outlined,
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_selectedAddress != null) ...[
        Row(children: [
          _badge(_selectedAddress!.label),
          const SizedBox(width: 8),
          Text(_selectedAddress!.recipientName, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (_selectedAddress!.isDefault) ...[const SizedBox(width: 6), _badge('Utama', color: Colors.blue)],
        ]),
        const SizedBox(height: 6),
        Text(_selectedAddress!.fullAddress, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87)),
        const SizedBox(height: 4),
        Text(_selectedAddress!.phone, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ] else
        GestureDetector(
          onTap: () async {
            final r = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressFormScreen()));
            if (r == true) _load();
          },
          child: Container(padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF1A5C38), style: BorderStyle.solid), borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [Icon(Icons.add, color: Color(0xFF1A5C38)), SizedBox(width: 8), Text('Tambah Alamat Pengiriman', style: TextStyle(color: Color(0xFF1A5C38), fontWeight: FontWeight.w600))]),
          ),
        ),
      if (s.addresses.length > 1) ...[
        const SizedBox(height: 10),
        DropdownButtonFormField<int>(
          initialValue: _selectedAddress?.id,
          isDense: true,
          decoration: InputDecoration(labelText: 'Ganti Alamat', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
          items: s.addresses.map((a) => DropdownMenuItem<int>(value: a.id, child: Text('${a.label} — ${a.recipientName}', overflow: TextOverflow.ellipsis))).toList(),
          onChanged: (val) => setState(() => _selectedAddress = s.addresses.firstWhere((a) => a.id == val)),
        ),
      ],
    ]),
  );

  Widget _itemsCard(CheckoutSummary s) {
    final items = s.selectedItems.isNotEmpty ? s.selectedItems
        : s.cart.items.where((i) => i.isSelected).map((i) => {
          'product_name': i.productName,
          'product_image': i.productImage,
          'quantity': i.quantity,
          'unit_price': i.unitPrice,
          'subtotal': i.subtotal,
        }).toList();

    return _card(
      title: 'Produk yang Dipesan (${items.length} item)', icon: Icons.shopping_bag_outlined,
      child: Column(children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(8),
            child: SizedBox(width: 56, height: 56, child: Image.network(
              item['product_image']?.toString() ?? '',
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, st) => Container(color: const Color(0xFFF3F4F6), child: const Icon(Icons.image_not_supported, color: Colors.grey)),
            )),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['product_name']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 4),
            Text('${item['quantity']}x ${_currency.format(double.tryParse(item['unit_price'].toString()) ?? 0)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ])),
          Text(_currency.format(double.tryParse(item['subtotal'].toString()) ?? 0),
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A5C38))),
        ]),
      )).toList()),
    );
  }

  /// Payment method card — renders ONLY admin-enabled methods from API
  Widget _paymentMethodCard(CheckoutSummary s) {
    if (s.paymentOptions.isEmpty) {
      return _card(
        title: 'Metode Pembayaran', icon: Icons.payment_outlined,
        child: const Text('Tidak ada metode pembayaran yang aktif. Hubungi admin.', style: TextStyle(color: Colors.grey, fontSize: 13)),
      );
    }

    return _card(
      title: 'Metode Pembayaran', icon: Icons.payment_outlined,
      child: Column(children: s.paymentOptions.map((opt) {
        final sel = _selectedPayment?.backendValue == opt.backendValue &&
                    _selectedPayment?.label == opt.label;
        final isCod = opt.backendValue == 'cod';
        final hasCodFee = isCod && s.codFee > 0;

        return GestureDetector(
          onTap: () => setState(() => _selectedPayment = opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: sel ? const Color(0xFFE8F5E9) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: sel ? const Color(0xFF1A5C38) : Colors.grey.shade200, width: sel ? 1.5 : 1),
            ),
            child: Row(children: [
              Icon(opt.icon, size: 26, color: const Color(0xFF1A5C38)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(opt.label, style: TextStyle(
                  fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                  color: sel ? const Color(0xFF1A5C38) : Colors.black87,
                )),
                if (hasCodFee)
                  Text('+ biaya COD ${_currency.format(s.codFee)}',
                    style: const TextStyle(fontSize: 11, color: Colors.orange)),
              ])),
              if (sel) const Icon(Icons.check_circle, color: Color(0xFF1A5C38), size: 20),
            ]),
          ),
        );
      }).toList()),
    );
  }

  Widget _courierCard(CheckoutSummary s) => _card(
    title: 'Pilihan Pengiriman', icon: Icons.local_shipping_outlined,
    child: Column(
      children: s.couriers.map((courier) {
        final selected = _selectedCourier?.code == courier.code;
        final effectiveCost = s.shippingCostFor(courier);

        return GestureDetector(
          onTap: () => setState(() => _selectedCourier = courier),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE8F5E9) : const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? const Color(0xFF1A5C38) : Colors.grey.shade200,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, color: Color(0xFF1A5C38)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(courier.label,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                          color: const Color(0xFF1F2937),
                        )),
                      const SizedBox(height: 2),
                      Text(
                        s.isFreeShipping
                            ? 'Estimasi ${courier.estimatedDays} hari • Gratis ongkir'
                            : 'Estimasi ${courier.estimatedDays} hari',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      effectiveCost == 0 ? 'Gratis' : _currency.format(effectiveCost),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: effectiveCost == 0 ? Colors.green.shade700 : const Color(0xFF0F3D25),
                      ),
                    ),
                    if (selected)
                      const Icon(Icons.check_circle, color: Color(0xFF1A5C38), size: 18),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );

  Widget _bankInfoCard(CheckoutSummary s) => _card(
    title: 'Rekening Tujuan Transfer', icon: Icons.account_balance_outlined,
    child: Column(children: s.bankAccounts.map<Widget>((bank) => Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(bank['bank_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F3D25))),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('No. Rek: ${bank['account_number']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
        Text('a.n. ${bank['account_holder']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ]),
    )).toList()),
  );

  Widget _notesCard() => _card(
    title: 'Catatan (opsional)', icon: Icons.note_outlined,
    child: TextField(
      controller: _notesCtrl,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Contoh: Jangan dikirim siang hari...',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.all(12),
      ),
    ),
  );

  Widget _voucherCard(CheckoutSummary s) {
    if (_appliedVoucher != null) {
      return _card(
        title: 'Voucher Promo', icon: Icons.local_offer_outlined,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_appliedVoucher!.code,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontFamily: 'monospace')),
              Text('Hemat ${_currency.format(_appliedVoucher!.discountAmount)}',
                style: TextStyle(fontSize: 12, color: Colors.green.shade700)),
            ])),
            GestureDetector(
              onTap: _removeVoucher,
              child: Icon(Icons.close, size: 18, color: Colors.green.shade700),
            ),
          ]),
        ),
      );
    }

    return _card(
      title: 'Voucher Promo', icon: Icons.local_offer_outlined,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: _voucherCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Masukkan kode voucher...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: _isValidatingVoucher ? null : _applyVoucher,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A5C38), foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0, padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _isValidatingVoucher
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Pakai', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
        if (_voucherError != null) ...[
          const SizedBox(height: 6),
          Text(_voucherError!, style: const TextStyle(fontSize: 12, color: Colors.red)),
        ],
      ]),
    );
  }

  Widget _priceSummaryCard(CheckoutSummary s) {
    final isCod = _selectedPayment?.backendValue == 'cod';
    final codFee = isCod ? s.codFee : 0.0;
    final shippingCost = s.shippingCostFor(_selectedCourier);
    final total = _currentTotal;

    return _card(
      title: 'Ringkasan Pembayaran', icon: Icons.receipt_outlined,
      child: Column(children: [
        _priceRow('Subtotal Produk', _currency.format(s.subtotal)),
        const SizedBox(height: 8),
        // Shipping cost row with free shipping badge
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Text('Ongkos Kirim', style: TextStyle(color: Colors.grey.shade600)),
            if (s.isFreeShipping) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)),
                child: Text('GRATIS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
              ),
            ],
          ]),
          s.isFreeShipping
              ? Row(children: [
                  Text(_currency.format(_selectedCourier?.cost ?? s.shippingCost),
                    style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.grey, fontSize: 12)),
                  const SizedBox(width: 4),
                  Text('Gratis', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green.shade700)),
                ])
              : Text(_currency.format(shippingCost),
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
        ]),
        // COD fee row (only when COD selected and fee > 0)
        if (codFee > 0) ...[
          const SizedBox(height: 8),
          _priceRow('Biaya COD', _currency.format(codFee), valueColor: Colors.orange.shade700),
        ],
        // Voucher discount row
        if (_appliedVoucher != null) ...[
          const SizedBox(height: 8),
          _priceRow('Diskon Voucher (${_appliedVoucher!.code})',
            '- ${_currency.format(_appliedVoucher!.discountAmount)}',
            valueColor: Colors.green.shade700),
        ],
        const Divider(height: 20),
        _priceRow('Total Pembayaran', _currency.format(total), bold: true),
      ]),
    );
  }

  Widget _priceRow(String label, String value, {bool bold = false, Color? valueColor}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
      Text(value, style: TextStyle(
        fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
        color: valueColor ?? (bold ? const Color(0xFF1A5C38) : const Color(0xFF1F2937)),
        fontSize: bold ? 16 : 14,
      )),
    ],
  );

  Widget _bottomCheckoutBar(CheckoutSummary s) => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
    decoration: const BoxDecoration(color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))]),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (!s.isMinimumMet && s.minimumOrderAmount > 0)
        Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Text('Minimum pembelian ${_currency.format(s.minimumOrderAmount)}',
            style: const TextStyle(color: Colors.red, fontSize: 12))),
      if (s.isFreeShipping)
        Padding(padding: const EdgeInsets.only(bottom: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.local_shipping_outlined, size: 14, color: Colors.green.shade700),
            const SizedBox(width: 4),
            Text('Selamat! Kamu mendapat gratis ongkir',
              style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w600)),
          ]),
        ),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Total', style: TextStyle(fontSize: 12, color: Colors.grey)),
          Text(_currency.format(_currentTotal),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A5C38))),
        ]),
        SizedBox(
          width: 180,
          child: ElevatedButton(
            onPressed: (_isPlacing || !s.isMinimumMet || _selectedPayment == null) ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A5C38),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _isPlacing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Buat Pesanan', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    ]),
  );

  Widget _card({required String title, required IconData icon, required Widget child}) =>
    Container(padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 18, color: const Color(0xFF16A34A)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F3D25))),
        ]),
        const SizedBox(height: 12),
        child,
      ]),
    );

  Widget _badge(String text, {Color color = const Color(0xFF1A5C38)}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
  );
}
