import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/services/order_service.dart';
import '../../../../core/services/recommendation_service.dart';
import '../../../../features/admin/data/admin_models.dart' as models;
import '../../../../features/user/data/user_models.dart';

class UserCheckoutPage extends StatefulWidget {
  const UserCheckoutPage({super.key});

  @override
  State<UserCheckoutPage> createState() => _UserCheckoutPageState();
}

class _UserCheckoutPageState extends State<UserCheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final CartService _cartService = CartService();
  final OrderService _orderService = OrderService();

  String _selectedPayment = 'QRIS';
  bool _isPlacingOrder = false;
  UserCart? _cart;
  bool _isLoadingCart = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
    _prefillUserInfo();
  }

  void _prefillUserInfo() {
    final auth = context.read<AuthService>();
    _nameCtrl.text = auth.userName ?? '';
  }

  Future<void> _loadCart() async {
    final userId = context.read<AuthService>().userId;
    if (userId == null) return;
    final cart = await _cartService.getUserCart(userId);
    if (mounted) {
      setState(() {
        _cart = cart;
        _isLoadingCart = false;
      });
    }
  }

  double get _serviceFee => 2000.0;
  double get _subtotal =>
      (_cart?.items ?? []).fold(0.0, (s, e) => s + e.price * e.quantity);
  double get _total => _subtotal + _serviceFee;

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cart == null || _cart!.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keranjang kosong')),
      );
      return;
    }

    setState(() => _isPlacingOrder = true);
    try {
      final auth = context.read<AuthService>();
      final items = _cart!.items
          .map((c) => models.OrderItem(
                menuId: c.menuId,
                menuName: c.menuName,
                quantity: c.quantity,
                price: c.price,
              ))
          .toList();

      final orderId = await _orderService.createOrder(
        userId: auth.userId!,
        userName: _nameCtrl.text.trim(),
        userPhone: _phoneCtrl.text.trim(),
        items: items,
        totalPrice: _total,
        notes:
            '${_addressCtrl.text.trim()}${_notesCtrl.text.isNotEmpty ? " | ${_notesCtrl.text.trim()}" : ""}',
      );

      if (orderId == null) throw Exception('Gagal membuat pesanan');

      // Clear cart after successful order
      await _cartService.clearCart(_cart!.id);

      // Invalidate recommendation cache
      await RecommendationService().invalidateCache(auth.userId!);

      if (mounted) {
        if (_selectedPayment == 'QRIS') {
          _showQrisPaymentDialog(orderId);
        } else {
          _showOrderSuccess(orderId);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat pesanan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  void _showQrisPaymentDialog(String orderId) {
    final qrisData =
        'SMARTCANTEEN|ORDER:$orderId|AMOUNT:${_total.toStringAsFixed(0)}|MERCHANT:SmartCanteen';
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        titlePadding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        title: const Text('Pembayaran QRIS',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1F2937))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Scan QR Code berikut untuk menyelesaikan pembayaran:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: QrImageView(
                data: qrisData,
                version: QrVersions.auto,
                size: 180,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Text('No. Pesanan: #${orderId.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4B5563))),
                  const SizedBox(height: 6),
                  Text('Total: Rp ${_total.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7C3AED))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showOrderSuccess(orderId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Konfirmasi Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showOrderSuccess(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Column(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 56),
            SizedBox(height: 8),
            Text('Pesanan Berhasil!',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Pesanan Anda (#${orderId.substring(0, 8)}...) telah diterima.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            const Text('Admin kantin akan segera memproses pesanan Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.userOrders,
                (r) => r.settings.name == AppRoutes.userHome,
              );
            },
            child: const Text('Lihat Pesanan'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.userHome,
                (r) => false,
              );
            },
            child: const Text('Ke Beranda'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingCart) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('Informasi Penerima'),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _nameCtrl,
              label: 'Nama Penerima',
              icon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Nama tidak boleh kosong' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _phoneCtrl,
              label: 'Nomor HP',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) => (v == null || v.isEmpty)
                  ? 'Nomor HP tidak boleh kosong'
                  : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _addressCtrl,
              label: 'Alamat / Lokasi Pengambilan',
              icon: Icons.location_on_outlined,
              maxLines: 2,
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Alamat tidak boleh kosong' : null,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _notesCtrl,
              label: 'Catatan (opsional)',
              icon: Icons.note_outlined,
              maxLines: 2,
              required: false,
            ),
            const SizedBox(height: 24),
            _sectionTitle('Metode Pembayaran'),
            const SizedBox(height: 12),
            ...['QRIS', 'E-Wallet', 'Tunai'].map((method) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PaymentOptionCard(
                  method: method,
                  isSelected: _selectedPayment == method,
                  onTap: () => setState(() => _selectedPayment = method),
                ),
              );
            }),
            const SizedBox(height: 24),
            _sectionTitle('Ringkasan Pesanan'),
            const SizedBox(height: 12),
            _buildOrderSummaryCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isPlacingOrder ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _isPlacingOrder
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white)),
                      SizedBox(width: 8),
                      Text('Memproses Pesanan...'),
                    ],
                  )
                : Text(
                    'Buat Pesanan • Rp ${_total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937)));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1F2937)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF7C3AED)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildOrderSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ..._cart!.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Text('${item.quantity}x ',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                    Expanded(child: Text(item.menuName, style: const TextStyle(color: Color(0xFF4B5563)))),
                    Text(
                        'Rp ${(item.price * item.quantity).toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                  ],
                ),
              )),
          const Divider(color: Color(0xFFF3F4F6), height: 20),
          _summaryRow('Subtotal', _subtotal),
          const SizedBox(height: 6),
          _summaryRow('Biaya Layanan', _serviceFee),
          const Divider(color: Color(0xFFF3F4F6), height: 20),
          _summaryRow('Total Pembayaran', _total, isBold: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isBold ? 15 : 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? const Color(0xFF1F2937) : const Color(0xFF6B7280))),
        Text(
          'Rp ${amount.toStringAsFixed(0)}',
          style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? const Color(0xFF7C3AED) : const Color(0xFF1F2937)),
        ),
      ],
    );
  }
}

class _PaymentOptionCard extends StatelessWidget {
  final String method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  IconData get _icon {
    switch (method) {
      case 'QRIS':
        return Icons.qr_code;
      case 'E-Wallet':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.payments_outlined;
    }
  }

  String get _subtitle {
    switch (method) {
      case 'QRIS':
        return 'Scan QR Code untuk bayar';
      case 'E-Wallet':
        return 'GoPay, OVO, Dana, dll.';
      default:
        return 'Bayar saat menerima pesanan';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C3AED).withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE5E7EB),
            width: isSelected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.04 : 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF7C3AED).withOpacity(0.12)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon,
                  color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF4B5563)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isSelected
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF1F2937))),
                  const SizedBox(height: 2),
                  Text(_subtitle,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: Color(0xFF7C3AED), size: 22),
          ],
        ),
      ),
    );
  }
}
