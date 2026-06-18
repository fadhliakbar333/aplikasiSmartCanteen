import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/rating_model.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/services/rating_service.dart';
import '../../../../features/admin/data/admin_models.dart';
import '../../../../features/user/data/user_models.dart';
import '../widgets/star_rating_widget.dart';

class UserMenuDetailPage extends StatefulWidget {
  const UserMenuDetailPage({super.key});

  @override
  State<UserMenuDetailPage> createState() => _UserMenuDetailPageState();
}

class _UserMenuDetailPageState extends State<UserMenuDetailPage> {
  final CartService _cartService = CartService();
  final RatingService _ratingService = RatingService();

  int _quantity = 1;
  bool _isAddingToCart = false;
  MenuItem? _menuItem;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is MenuItem) {
        setState(() => _menuItem = args);
      }
    }
  }

  Future<void> _addToCart() async {
    if (_menuItem == null) return;
    final authService = context.read<AuthService>();
    if (authService.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    setState(() => _isAddingToCart = true);
    try {
      var userCart = await _cartService.getUserCart(authService.userId!);
      if (userCart == null) {
        final cartId = await _cartService.createCart(
          userId: authService.userId!,
          items: [],
          totalPrice: 0,
        );
        if (cartId == null) throw Exception('Gagal membuat keranjang');
        userCart = await _cartService.getCart(cartId);
      }
      if (userCart != null) {
        final newItem = CartItem(
          menuId: _menuItem!.id,
          menuName: _menuItem!.name,
          price: _menuItem!.price,
          quantity: _quantity,
        );
        final totalPrice = userCart.totalPrice + _menuItem!.price * _quantity;
        await _cartService.addItemToCart(userCart.id, newItem, totalPrice);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${_menuItem!.name} (x$_quantity) ditambahkan ke keranjang'),
              action: SnackBarAction(
                label: 'Lihat',
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.userCart),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan ke keranjang: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isAddingToCart = false);
    }
  }

  String _getEmoji(String category) {
    const map = {
      'makanan': '🍽️',
      'minuman': '🥤',
      'snack': '🍪',
      'dessert': '🍰',
      'kopi': '☕',
      'juice': '🧃',
      'nasi': '🍚',
      'roti': '🥖',
    };
    return map[category.toLowerCase()] ?? '🍽️';
  }

  @override
  Widget build(BuildContext context) {
    if (_menuItem == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Menu')),
        body: const Center(child: Text('Menu tidak ditemukan')),
      );
    }
    final item = _menuItem!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero image / emoji ──
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF3E8FF), Color(0xFFDDD6FE)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7C3AED).withOpacity(0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getEmoji(item.category),
                        style: const TextStyle(fontSize: 84),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + availability
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      if (!item.available)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Tidak Tersedia',
                              style:
                                  TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Category chip
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C3AED).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.category.toUpperCase(),
                      style: const TextStyle(
                          color: Color(0xFF7C3AED),
                          fontSize: 11,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Rating row — live from Firestore
                  StreamBuilder<List<Rating>>(
                    stream: _ratingService.streamRatingsForMenu(item.id),
                    builder: (context, snap) {
                      final ratings = snap.data ?? [];
                      final avg = ratings.isEmpty
                          ? item.rating
                          : ratings.fold(0.0, (s, r) => s + r.stars) /
                              ratings.length;
                      final count = ratings.isEmpty ? null : ratings.length;

                      return Row(
                        children: [
                          StarRatingWidget(
                            rating: avg,
                            size: 22,
                            interactive: false,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            avg.toStringAsFixed(1),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (count != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '($count ulasan)',
                              style: const TextStyle(
                                  color: Color(0xFF6B7280), fontSize: 13),
                            ),
                          ],
                          const Spacer(),
                          const Icon(Icons.shopping_bag_outlined,
                              color: Color(0xFF9CA3AF), size: 18),
                          const SizedBox(width: 4),
                          Text('${item.sold} terjual',
                              style: const TextStyle(
                                  color: Color(0xFF4B5563), fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),

                  // Price
                  Text(
                    'Rp ${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Description
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description.isNotEmpty
                        ? item.description
                        : 'Tidak ada deskripsi untuk menu ini.',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey[600], height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // Quantity selector
                  const Text(
                    'Jumlah',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _qtyBtn(Icons.remove, () {
                        if (_quantity > 1) setState(() => _quantity--);
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      _qtyBtn(Icons.add, () => setState(() => _quantity++)),
                      const Spacer(),
                      Text(
                        'Total: Rp ${(item.price * _quantity).toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Reviews section ──────────────────────────────────
                  const Text(
                    'Ulasan Pelanggan',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937)),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Rating>>(
                    stream: _ratingService.streamRatingsForMenu(item.id),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final ratings = snap.data ?? [];
                      if (ratings.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.rate_review_outlined,
                                  size: 40, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'Belum ada ulasan',
                                style: TextStyle(
                                    color: Colors.grey[500], fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Jadilah yang pertama memberi rating!',
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }
                      return Column(
                        children: ratings
                            .take(5)
                            .map((r) => _ReviewCard(rating: r))
                            .toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
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
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.userCart),
                icon: const Icon(Icons.shopping_cart_outlined),
                label: const Text('Keranjang'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed:
                    item.available && !_isAddingToCart ? _addToCart : null,
                icon: _isAddingToCart
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.add_shopping_cart),
                label: Text(
                    _isAddingToCart ? 'Menambahkan...' : 'Tambah ke Keranjang'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withOpacity(0.06),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF7C3AED).withOpacity(0.25),
            width: 1.2,
          ),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
      ),
    );
  }
}

// ── Single review card ────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final Rating rating;
  const _ReviewCard({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer header
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                child: Text(
                  rating.userName.isNotEmpty
                      ? rating.userName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rating.userName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      _formatDate(rating.createdAt),
                      style: TextStyle(color: Colors.grey[400], fontSize: 11),
                    ),
                  ],
                ),
              ),
              StarRatingWidget(
                rating: rating.stars,
                size: 16,
                interactive: false,
              ),
            ],
          ),

          // Review text
          if (rating.review.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rating.review,
              style:
                  TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
