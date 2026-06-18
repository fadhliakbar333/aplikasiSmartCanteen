import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/order_service.dart';
import '../../../../core/services/menu_service.dart';
import '../widgets/admin_stats_card.dart';
import '../widgets/admin_chart_widget.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  late final OrderService _orderService;
  late final MenuService _menuService;
  int totalOrders = 0;
  int totalMenus = 0;
  double totalRevenue = 0;
  int pendingOrders = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _orderService = OrderService();
    _menuService = MenuService();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      setState(() => isLoading = true);

      // Get all orders
      final orders = await _orderService.getAllOrders();
      final menus = await _menuService.getAllMenus();

      // Calculate stats
      double revenue = 0;
      int pending = 0;

      for (var order in orders) {
        revenue += order.totalPrice;
        if (order.status == 'pending') {
          pending++;
        }
      }

      setState(() {
        totalOrders = orders.length;
        totalMenus = menus.length;
        totalRevenue = revenue;
        pendingOrders = pending;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Dashboard Admin',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.adminNotification);
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.adminProfile);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Consumer<AuthService>(
              builder: (context, authService, _) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang, ${authService.userName} 👋',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Kelola operasional kantin dan pantau performa bisnis Anda secara real-time.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            // Stats Cards
            const Text(
              'Statistik Kantin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                ),
              )
            else
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AdminStatsCard(
                          icon: Icons.shopping_bag_outlined,
                          label: 'Total Pesanan',
                          value: totalOrders.toString(),
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AdminStatsCard(
                          icon: Icons.local_dining_outlined,
                          label: 'Total Menu',
                          value: totalMenus.toString(),
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AdminStatsCard(
                          icon: Icons.schedule_outlined,
                          label: 'Menunggu',
                          value: pendingOrders.toString(),
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AdminStatsCard(
                          icon: Icons.trending_up,
                          label: 'Total Pendapatan',
                          value: 'Rp ${(totalRevenue / 1000).toStringAsFixed(0)}K',
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            const SizedBox(height: 24),
            // Chart Section
            const Text(
              'Penjualan Mingguan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3F4F6), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const AdminChartWidget(),
            ),
            const SizedBox(height: 24),
            // Quick Actions
            const Text(
              'Menu Pintasan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1F2937),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildQuickActionButton(
                  context,
                  Icons.restaurant_menu,
                  'Kelola Menu',
                  () {
                    Navigator.pushNamed(context, AppRoutes.adminMenu);
                  },
                ),
                _buildQuickActionButton(
                  context,
                  Icons.shopping_cart_checkout,
                  'Pesanan',
                  () {
                    Navigator.pushNamed(context, AppRoutes.adminOrders);
                  },
                ),
                _buildQuickActionButton(
                  context,
                  Icons.category,
                  'Kategori',
                  () {
                    Navigator.pushNamed(context, AppRoutes.adminCategory);
                  },
                ),
                _buildQuickActionButton(
                  context,
                  Icons.chat_bubble_outline,
                  'Chat CS',
                  () {
                    Navigator.pushNamed(context, AppRoutes.adminChat);
                  },
                ),
                _buildQuickActionButton(
                  context,
                  Icons.bar_chart,
                  'Statistik',
                  () {
                    Navigator.pushNamed(context, AppRoutes.adminStatistics);
                  },
                ),
                _buildQuickActionButton(
                  context,
                  Icons.settings_outlined,
                  'Pengaturan',
                  () {
                    Navigator.pushNamed(context, AppRoutes.adminSettings);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.admin_panel_settings,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SmartCanteen',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              'Panel Administrator',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Consumer<AuthService>(
                    builder: (context, authService, _) {
                      return Text(
                        authService.userEmail ?? 'admin@smartcanteen.com',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildDrawerTile(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              isSelected: true,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            _buildDrawerTile(
              icon: Icons.restaurant_menu_outlined,
              title: 'Kelola Menu',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminMenu);
              },
            ),
            _buildDrawerTile(
              icon: Icons.shopping_cart_checkout_outlined,
              title: 'Pesanan',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminOrders);
              },
            ),
            _buildDrawerTile(
              icon: Icons.category_outlined,
              title: 'Kategori',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminCategory);
              },
            ),
            _buildDrawerTile(
              icon: Icons.chat_bubble_outline_outlined,
              title: 'Chat Customer Service',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminChat);
              },
            ),
            const Divider(indent: 16, endIndent: 16, height: 32),
            _buildDrawerTile(
              icon: Icons.account_circle_outlined,
              title: 'Profil',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.adminProfile);
              },
            ),
            _buildDrawerTile(
              icon: Icons.logout_outlined,
              title: 'Logout',
              iconColor: Colors.red,
              textColor: Colors.red,
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
    Color? iconColor,
    Color? textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? const Color(0xFF7C3AED)
              : (iconColor ?? const Color(0xFF4B5563)),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF7C3AED)
                : (textColor ?? const Color(0xFF1F2937)),
            fontSize: 14,
          ),
        ),
        selected: isSelected,
        selectedTileColor: const Color(0xFF7C3AED).withOpacity(0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF3F4F6), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari panel admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<AuthService>().logout();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.auth, (_) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
