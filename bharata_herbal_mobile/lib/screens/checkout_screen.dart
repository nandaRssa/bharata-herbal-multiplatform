import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/checkout_service.dart';
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
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  CheckoutSummary? _summary;
  bool _isLoading = true;
  bool _isPlacingOrder = false;
  String? _error;

  Address? _selectedAddress;
  String _selectedPayment = 'transfer';
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final summary = await _service.getCheckoutSummary();
      setState(() {
        _summary = summary;
        _selectedAddress = summary.defaultAddress ?? 
            (summary.addresses.isNotEmpty ? summary.addresses.first : null);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat data checkout. Pastikan ada item terpilih di keranjang.';
        _isLoading = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedAddress == null) {
      _showSnack('Pilih alamat pengiriman terlebih dahulu');
      return;
    }
    setState(() => _isPlacingOrder = true);
    try {
      final result = await _service.placeOrder(
        _selectedAddress!.id,
        _selectedPayment,
        _notesController.text,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        // Clear cart
        context.read<CartProvider>().clearLocal();
        final orderId = result['data']['order_id'] as int;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: orderId),
          ),
        );
      } else {
        _showSnack(result['message'] ?? 'Gagal membuat pesanan');
      }
    } catch (e) {
      _showSnack('Terjadi kesalahan. Coba lagi.');
    }
    if (mounted) setState(() => _isPlacingOrder = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Checkout',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2D5016)),
            )
          : _error != null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D5016),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final summary = _summary!;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // --- Alamat Pengiriman ---
              _sectionCard(
                title: 'Alamat Pengiriman',
                icon: Icons.location_on_outlined,
                child: _buildAddressSection(summary),
              ),
              const SizedBox(height: 12),
              // --- Item Pesanan ---
              _sectionCard(
                title: 'Produk yang Dipesan',
                icon: Icons.shopping_bag_outlined,
                child: _buildItemsSection(summary),
              ),
              const SizedBox(height: 12),
              // --- Metode Pembayaran ---
              _sectionCard(
                title: 'Metode Pembayaran',
                icon: Icons.payment_outlined,
                child: _buildPaymentSection(summary),
              ),
              const SizedBox(height: 12),
              // --- Info Rekening (jika transfer) ---
              if (_selectedPayment == 'transfer' &&
                  summary.bankAccounts.isNotEmpty)
                _buildBankSection(summary),
              const SizedBox(height: 12),
              // --- Catatan ---
              _sectionCard(
                title: 'Catatan (opsional)',
                icon: Icons.note_outlined,
                child: TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan catatan untuk penjual...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // --- Ringkasan Harga ---
              _buildPriceSummary(summary),
            ],
          ),
        ),
        _buildPayButton(summary),
      ],
    );
  }

  Widget _buildAddressSection(CheckoutSummary summary) {
    if (summary.addresses.isEmpty) {
      return GestureDetector(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddressFormScreen()),
          );
          if (result == true) _load();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFF2D5016),
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.add, color: Color(0xFF2D5016)),
              SizedBox(width: 8),
              Text(
                'Tambah Alamat Pengiriman',
                style: TextStyle(
                  color: Color(0xFF2D5016),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Selected address display
        if (_selectedAddress != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF4A7C2C)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D5016),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _selectedAddress!.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedAddress!.recipientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _selectedAddress!.fullAddress,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedAddress!.phone,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        // Dropdown pilih alamat jika lebih dari 1
        if (summary.addresses.length > 1)
          DropdownButtonFormField<int>(
            value: _selectedAddress?.id,
            decoration: InputDecoration(
              labelText: 'Ganti Alamat',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: summary.addresses
                .map(
                  (a) => DropdownMenuItem<int>(
                    value: a.id,
                    child: Text(
                      '${a.label} — ${a.recipientName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              setState(() {
                _selectedAddress = summary.addresses.firstWhere(
                  (a) => a.id == val,
                );
              });
            },
          ),
      ],
    );
  }

  Widget _buildItemsSection(CheckoutSummary summary) {
    return Column(
      children: summary.cart.items
          .where((i) => i.isSelected)
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Image.network(
                        item.productImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFF3F4F6),
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.grey),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
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
                      ],
                    ),
                  ),
                  Text(
                    _currency.format(item.subtotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D5016),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPaymentSection(CheckoutSummary summary) {
    return Column(
      children: summary.paymentMethods.map((method) {
        final label = method == 'transfer' ? 'Transfer Bank' : 'Bayar di Tempat (COD)';
        final icon = method == 'transfer' ? Icons.account_balance : Icons.money;
        return RadioListTile<String>(
          value: method,
          groupValue: _selectedPayment,
          onChanged: (val) => setState(() => _selectedPayment = val!),
          title: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          secondary: Icon(icon, color: const Color(0xFF2D5016)),
          activeColor: const Color(0xFF2D5016),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildBankSection(CheckoutSummary summary) {
    return _sectionCard(
      title: 'Rekening Tujuan',
      icon: Icons.account_balance_outlined,
      child: Column(
        children: summary.bankAccounts.map<Widget>((bank) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A0F),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No. Rek: ${bank['account_number']}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'a.n. ${bank['account_holder']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPriceSummary(CheckoutSummary summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _row('Subtotal', _currency.format(summary.subtotal)),
          const SizedBox(height: 8),
          _row('Ongkos Kirim', _currency.format(summary.shippingCost)),
          const Divider(height: 20),
          _row(
            'Total Pembayaran',
            _currency.format(summary.total),
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
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

  Widget _buildPayButton(CheckoutSummary summary) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isPlacingOrder ? null : _placeOrder,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2D5016),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _isPlacingOrder
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Buat Pesanan • ${_currency.format(summary.total)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _sectionCard({
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
}
