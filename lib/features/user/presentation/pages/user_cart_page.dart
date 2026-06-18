import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../features/user/data/user_models.dart';
import '../widgets/empty_state_widget.dart';

class UserCartPage extends StatefulWidget {
  const UserCartPage({super.key});

  @override
  State<UserCartPage> createState() => _UserCartPageState();
}

class _UserCartPageState extends State<UserCartPage> {
  final CartService _cartService = CartService();
  bool _canteenOpen = true;
  UserCart? _cart;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    final userId = context.read<AuthService>().userId;
    if (userId == null) return;
    setState(() => _isLoading = true);
    
    try {
      final futures = await Future.wait([
        _cartService.getUserCart(userId),
        FirebaseFirestore.instance.collection('settings').doc('canteen_config').get(),
      ]);
      final cart = futures[0] as UserCart?;
      final settingsDoc = futures[1] as DocumentSnapshot;

      bool open = true;
      if (settingsDoc.exists) {
        final sData = settingsDoc.data() as Map<String, dynamic>;
        open = sData['isOpen'] ?? true;
      }

      if (mounted) {
        setState(() {
          _cart = cart;
          _canteenOpen = open;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading cart: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateQuantity(CartItem item, int delta) async {
    if (_cart == null) return;
    final newQty = item.quantity + delta;
    if (newQty <= 0) {
      _removeItem(item);
      return;
    }
    item.quantity = newQty;
    final newTotal = _cart!.items.fold(0.0, (s, e) => s + e.price * e.quantity);
    await _cartService.updateCart(_cart!.id, _cart!.items, newTotal);
    _loadCart();
  }

  Future<void> _removeItem(CartItem item) async {
    if (_cart == null) return;
    final newTotal = _cart!.totalPrice - item.price * item.quantity;
    await _cartService.removeItemFromCart(
        _cart!.id, item.menuId, newTotal < 0 ? 0 : newTotal);
    _loadCart();
  }

  Future<void> _clearCart() async {
    if (_cart == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kosongkan Keranjang'),
        content: const Text('Apakah Anda yakin ingin mengosongkan keranjang?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Kosongkan', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _cartService.clearCart(_cart!.id);
      _loadCart();
    }
  }

  double get _subtotal =>
      (_cart?.items ?? []).fold(0.0, (s, e) => s + e.price * e.quantity);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang Belanja'),
        actions: [
          if (_cart != null && _cart!.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _clearCart,
              tooltip: 'Kosongkan keranjang',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_cart == null || _cart!.items.isEmpty)
              ? EmptyStateWidget(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Keranjang Kosong',
                  message: 'Tambahkan makanan dari menu untuk mulai memesan',
                  actionLabel: 'Lihat Menu',
                  onAction: () =>
                      Navigator.pushNamed(context, AppRoutes.userHome),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _cart!.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = _cart!.items[index];
                          return _CartItemCard(
                            item: item,
                            onIncrease: () => _updateQuantity(item, 1),
                            onDecrease: () => _updateQuantity(item, -1),
                            onRemove: () => _removeItem(item),
                          );
                        },
                      ),
                    ),
                    _buildOrderSummary(),
                  ],
                ),
    );
  }

  Widget _buildOrderSummary() {
    const deliveryFee = 2000.0;
    final total = _subtotal + deliveryFee;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _summaryRow('Subtotal', _subtotal),
            const SizedBox(height: 6),
            _summaryRow('Biaya Layanan', deliveryFee),
            const Divider(height: 20, color: Color(0xFFF3F4F6)),
            _summaryRow('Total Pembayaran', total, isBold: true),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!_canteenOpen) {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        title: const Text('Kantin Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                        content: const Text('Maaf, saat ini kantin sedang tutup. Anda tidak dapat melakukan checkout pesanan.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Tutup', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                    return;
                  }
                  Navigator.pushNamed(context, AppRoutes.userCheckout);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  shadowColor: const Color(0xFF7C3AED).withOpacity(0.3),
                ),
                child: Text(
                  'Checkout (Rp ${total.toStringAsFixed(0)})',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: isBold ? const Color(0xFF1F2937) : const Color(0xFF6B7280))),
        Text(
          'Rp ${amount.toStringAsFixed(0)}',
          style: TextStyle(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color:
                  isBold ? const Color(0xFF7C3AED) : const Color(0xFF1F2937)),
        ),
      ],
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onIncrease,
    required this.onDecrease,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFF3E8FF),
              shape: BoxShape.circle,
            ),
            child: const Center(
                child: Text('🍽️', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.menuName,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                const SizedBox(height: 6),
                Text(
                  'Rp ${item.price.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: Color(0xFF7C3AED), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFCA5A5).withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.close, size: 14, color: Color(0xFFEF4444)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _qtyButton(Icons.remove, onDecrease),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('${item.quantity}',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
                  ),
                  _qtyButton(Icons.add, onIncrease),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Color(0xFF7C3AED),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 12),
      ),
    );
  }
}
