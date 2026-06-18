import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/recommendation_service.dart';
import '../../../../features/admin/data/admin_models.dart';
import '../widgets/menu_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/loading_skeleton.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../features/user/data/user_models.dart';

class UserRecommendationPage extends StatefulWidget {
  const UserRecommendationPage({super.key});

  @override
  State<UserRecommendationPage> createState() => _UserRecommendationPageState();
}

class _UserRecommendationPageState extends State<UserRecommendationPage> {
  final RecommendationService _recommendationService = RecommendationService();
  final CartService _cartService = CartService();

  List<MenuItem> _recommendations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = context.read<AuthService>().userId;
      if (userId == null) {
        setState(() {
          _error = 'Silakan login untuk melihat rekomendasi';
          _isLoading = false;
        });
        return;
      }

      final recs = await _recommendationService.getRecommendations(userId);
      if (mounted) {
        setState(() {
          _recommendations = recs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Gagal memuat rekomendasi';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleAddToCart(MenuItem item) async {
    final authService = context.read<AuthService>();
    if (authService.userId == null) return;

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
          menuId: item.id,
          menuName: item.name,
          price: item.price,
          quantity: 1,
        );
        await _cartService.addItemToCart(
          userCart.id,
          newItem,
          userCart.totalPrice + item.price,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} ditambahkan ke keranjang'),
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
          SnackBar(content: Text('Gagal menambahkan: $e')),
        );
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekomendasi Untuk Anda'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final userId = context.read<AuthService>().userId;
              if (userId != null) {
                await _recommendationService.invalidateCache(userId);
              }
              _loadRecommendations();
            },
            tooltip: 'Refresh rekomendasi',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: List.generate(
            5,
            (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LoadingSkeleton(type: 'card'),
                )),
      );
    }

    if (_error != null) {
      return EmptyStateWidget(
        icon: Icons.error_outline,
        title: 'Terjadi Kesalahan',
        message: _error!,
        actionLabel: 'Coba Lagi',
        onAction: _loadRecommendations,
      );
    }

    if (_recommendations.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.restaurant_menu_outlined,
        title: 'Belum Ada Rekomendasi',
        message:
            'Buat pesanan atau beri rating makanan untuk mendapatkan rekomendasi yang personal.',
        actionLabel: 'Lihat Menu',
        onAction: () => Navigator.pushNamed(context, AppRoutes.userHome),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final userId = context.read<AuthService>().userId;
        if (userId != null) {
          await _recommendationService.invalidateCache(userId);
        }
        await _loadRecommendations();
      },
      child: Column(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF7C3AED).withOpacity(0.06),
                  const Color(0xFFEC4899).withOpacity(0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF7C3AED).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('🤖', style: TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rekomendasi AI Pintar',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7C3AED)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Menu pilihan yang disesuaikan dengan seleramu',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF7C3AED).withOpacity(0.15)),
                  ),
                  child: Text(
                    '${_recommendations.length} Menu',
                    style: const TextStyle(color: Color(0xFF7C3AED), fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: _recommendations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _recommendations[index];
                return Stack(
                  children: [
                    MenuCard(
                      name: item.name,
                      price: item.price,
                      rating: item.rating,
                      sold: item.sold,
                      image: _getEmoji(item.category),
                      available: item.available,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.userMenuDetail,
                        arguments: item,
                      ),
                      onAddToCart: () => _handleAddToCart(item),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: index == 0
                              ? const Color(0xFFF59E0B) // Gold
                              : index == 1
                                  ? const Color(0xFF9CA3AF) // Silver
                                  : index == 2
                                      ? const Color(0xFFB45309) // Bronze
                                      : const Color(0xFF7C3AED),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Text(
                          '#${index + 1}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
