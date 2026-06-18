import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/cart_service.dart';
import '../../../../core/services/menu_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/recommendation_service.dart';
import '../../../../features/admin/data/admin_models.dart';
import '../../../../features/user/data/user_models.dart';
import '../widgets/menu_card.dart';
import '../widgets/category_chip.dart';
import '../widgets/loading_skeleton.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/notification_badge_icon.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  late final MenuService _menuService;
  late final CartService _cartService;
  late final AuthService _authService;

  String selectedCategory = 'all';
  final TextEditingController searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<MenuItem> allMenuItems = [];
  List<MenuItem> displayedMenuItems = [];
  List<MenuCategory> categories = [];

  bool isLoading = true;
  bool isLoadingMore = false;
  int itemsPerPage = 8;
  int currentPage = 1;
  bool hasMoreItems = true;

  // AI Recommendations
  final RecommendationService _recommendationService = RecommendationService();
  List<MenuItem> _recommendations = [];

  bool canteenOpen = true;
  String canteenName = 'SmartCanteen';

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  void _initializeServices() {
    _menuService = MenuService();
    _cartService = CartService();
    _authService = Provider.of<AuthService>(context, listen: false);

    // Ensure FCM token is saved whenever user lands on home
    if (_authService.userId != null) {
      NotificationService().saveTokenForUser(_authService.userId!);
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final futures = await Future.wait([
        _menuService.getAllMenus(),
        _menuService.getAllCategories(),
        FirebaseFirestore.instance.collection('settings').doc('canteen_config').get(),
      ]);
      final menus = futures[0] as List<MenuItem>;
      final cats = futures[1] as List<MenuCategory>;
      final settingsDoc = futures[2] as DocumentSnapshot;

      bool open = true;
      String name = 'SmartCanteen';
      if (settingsDoc.exists) {
        final sData = settingsDoc.data() as Map<String, dynamic>;
        open = sData['isOpen'] ?? true;
        name = sData['canteenName'] ?? 'SmartCanteen';
      }

      if (mounted) {
        setState(() {
          allMenuItems = menus;
          categories = cats;
          canteenOpen = open;
          canteenName = name;
          currentPage = 1;
          _updateDisplayedItems();
          isLoading = false;
        });
      }

      // Load AI recommendations in background (non-blocking)
      _loadRecommendations();
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _loadRecommendations() async {
    final userId = _authService.userId;
    if (userId == null) return;
    try {
      final recs = await _recommendationService.getRecommendations(userId);
      if (mounted) {
        setState(() {
          _recommendations = recs;
        });
      }
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
    }
  }


  void _updateDisplayedItems() {
    final filtered = _getFilteredItems();
    const startIndex = 0;
    final endIndex = (currentPage * itemsPerPage).clamp(0, filtered.length);

    displayedMenuItems = filtered.sublist(startIndex, endIndex);
    hasMoreItems = endIndex < filtered.length;
  }

  List<MenuItem> _getFilteredItems() {
    return allMenuItems.where((item) {
      final matchesCategory =
          selectedCategory == 'all' || item.category == selectedCategory;
      final matchesSearch =
          item.name.toLowerCase().contains(searchController.text.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (hasMoreItems && !isLoadingMore) {
        _loadMoreItems();
      }
    }
  }

  Future<void> _loadMoreItems() async {
    if (!mounted) return;
    setState(() => isLoadingMore = true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        currentPage++;
        _updateDisplayedItems();
        isLoadingMore = false;
      });
    }
  }

  Future<void> _handleAddToCart(MenuItem item) async {
    if (!canteenOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maaf, saat ini kantin sedang tutup. Anda tidak dapat memesan makanan.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_authService.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    try {
      // Get or create user cart
      var userCart = await _cartService.getUserCart(_authService.userId!);

      if (userCart == null) {
        // Create new cart
        final cartId = await _cartService.createCart(
          userId: _authService.userId!,
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

        final totalPrice = userCart.totalPrice + item.price;
        await _cartService.addItemToCart(
          userCart.id,
          newItem,
          totalPrice,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} ditambahkan ke keranjang'),
              duration: const Duration(seconds: 2),
              action: SnackBarAction(
                label: 'Lihat',
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.userCart);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan ke keranjang: $e')),
        );
      }
    }
  }

  List<MenuItem> _getFeaturedItems() {
    return allMenuItems.where((item) => item.sold > 10).take(5).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          canteenName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            color: const Color(0xFF7C3AED),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.userCart);
            },
          ),
          const NotificationBadgeIcon(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: isLoading
            ? ListView(
                children: [
                  const SizedBox(height: 16),
                  const LoadingSkeleton(type: 'header'),
                  const SizedBox(height: 16),
                  const LoadingSkeleton(type: 'search'),
                  const SizedBox(height: 16),
                  const LoadingSkeleton(type: 'chips'),
                  const SizedBox(height: 16),
                  ...List.generate(
                      5, (_) => const LoadingSkeleton(type: 'card')),
                ],
              )
            : SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Consumer<AuthService>(
                      builder: (context, authService, _) {
                        return Container(
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF7C3AED), Color(0xFF9061F9), Color(0xFFEC4899)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hai, ${authService.userName ?? "Teman"} 👋',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Cari makanan lezat kesukaanmu hari ini di SmartCanteen!',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white70,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.lunch_dining_outlined,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Closed Canteen Alert
                    if (!canteenOpen)
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFF87171),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.storefront,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Kantin Tutup Sementara',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF991B1B),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Saat ini kantin tidak menerima pesanan. Silakan lihat menu saja.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF7F1D1D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: searchController,
                          onChanged: (_) {
                            setState(() {
                              currentPage = 1;
                              _updateDisplayedItems();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari makanan atau minuman...',
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF7C3AED)),
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.grey),
                                    onPressed: () {
                                      searchController.clear();
                                      setState(() {
                                        currentPage = 1;
                                        _updateDisplayedItems();
                                      });
                                    },
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Featured Items Section (if available)
                    if (_getFeaturedItems().isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '⭐ Menu Favorit Pelanggan',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                // Scroll down to available menu or category
                              },
                              child: const Text(
                                'Lihat Semua',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _getFeaturedItems().length,
                          itemBuilder: (context, index) {
                            final item = _getFeaturedItems()[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _buildFeaturedCard(item),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // AI Recommendations Section (if available)
                    if (_recommendations.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Text('🤖', style: TextStyle(fontSize: 18)),
                                SizedBox(width: 6),
                                Text(
                                  'Rekomendasi AI Untukmu',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                    context, AppRoutes.userRecommendation);
                              },
                              child: const Text(
                                'Lihat Semua',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 190,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _recommendations.length,
                          itemBuilder: (context, index) {
                            final item = _recommendations[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _buildRecommendationCard(item, index),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Category Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CategoryChip(
                              label: 'Semua',
                              isSelected: selectedCategory == 'all',
                              onTap: () {
                                setState(() {
                                  selectedCategory = 'all';
                                  currentPage = 1;
                                  _updateDisplayedItems();
                                });
                              },
                            ),
                          ),
                          ...categories.map((category) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CategoryChip(
                                label: category.name,
                                isSelected: selectedCategory == category.id,
                                onTap: () {
                                  setState(() {
                                    selectedCategory = category.id;
                                    currentPage = 1;
                                    _updateDisplayedItems();
                                  });
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Menu Items Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Menu Tersedia',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          Text(
                            '${_getFilteredItems().length} item',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Menu Items List or Empty State
                    if (displayedMenuItems.isEmpty)
                      EmptyStateWidget(
                        icon: Icons.restaurant_menu_outlined,
                        title: 'Tidak ada menu',
                        message: selectedCategory != 'all'
                            ? 'Tidak ada menu di kategori ini'
                            : 'Tidak ada menu yang sesuai dengan pencarian',
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: displayedMenuItems.length,
                        itemBuilder: (context, index) {
                          final item = displayedMenuItems[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MenuCard(
                              name: item.name,
                              price: item.price,
                              rating: item.rating,
                              sold: item.sold,
                              image: _getMenuEmoji(item.category),
                              available: item.available,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.userMenuDetail,
                                  arguments: item,
                                );
                              },
                              onAddToCart: () {
                                _handleAddToCart(item);
                              },
                            ),
                          );
                        },
                      ),

                    // Loading More Indicator
                    if (isLoadingMore)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF7C3AED).withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),

                    // End of list indicator
                    if (displayedMenuItems.isNotEmpty && !hasMoreItems)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Tidak ada menu lagi',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Keranjang',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Pesanan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profil',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: const Color(0xFF7C3AED),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          switch (index) {
            case 0:
              // Home
              break;
            case 1:
              Navigator.pushNamed(context, AppRoutes.userCart);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.userOrders);
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.userChat);
              break;
            case 4:
              Navigator.pushNamed(context, AppRoutes.userProfile);
              break;
          }
        },
      ),
    );
  }

  Widget _buildFeaturedCard(MenuItem item) {
    return Container(
      width: 148,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.userMenuDetail,
              arguments: item);
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFF3E8FF), // Primary-tint pastel background
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Text(
                  _getMenuEmoji(item.category),
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFF59E0B), size: 15),
                      const SizedBox(width: 2),
                      Text(
                        item.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rp ${item.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(MenuItem item, int index) {
    return Container(
      width: 148,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: index == 0
              ? const Color(0xFF7C3AED).withOpacity(0.4)
              : const Color(0xFFE5E7EB),
          width: index == 0 ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withOpacity(index == 0 ? 0.08 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.userMenuDetail,
              arguments: item);
        },
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withOpacity(0.05),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Center(
                    child: Text(
                      _getMenuEmoji(item.category),
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFF59E0B), size: 15),
                          const SizedBox(width: 2),
                          Text(
                            item.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4B5563),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rp ${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: index == 0
                      ? const Color(0xFFF59E0B) // Gold
                      : index == 1
                          ? const Color(0xFF9CA3AF) // Silver
                          : const Color(0xFF7C3AED), // Bronze/Brand
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Text(
                  '#${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMenuEmoji(String category) {
    final emojiMap = {
      'makanan': '🍽️',
      'minuman': '🥤',
      'snack': '🍪',
      'dessert': '🍰',
      'kopi': '☕',
      'juice': '🧃',
      'nasi': '🍚',
      'roti': '🥖',
    };
    return emojiMap[category.toLowerCase()] ?? '🍽️';
  }
}
