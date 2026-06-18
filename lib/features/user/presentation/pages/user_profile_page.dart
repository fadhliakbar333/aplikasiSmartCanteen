import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/order_service.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final OrderService _orderService = OrderService();
  int _totalOrders = 0;
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final userId = context.read<AuthService>().userId;
    if (userId == null) return;
    final orders = await _orderService.getUserOrders(userId);
    if (mounted) {
      setState(() {
        _totalOrders = orders.length;
        _statsLoaded = true;
      });
    }
  }

  void _showEditProfileDialog(BuildContext context, AuthService auth) {
    final nameCtrl = TextEditingController(text: auth.userName);
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Nama',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Nama tidak boleh kosong' : null,
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await auth.updateProfile(name: nameCtrl.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profil berhasil diperbarui')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Apakah Anda yakin ingin keluar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          TextButton(
            onPressed: () {
              auth.logout();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.auth, (_) => false);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAboutAppDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu,
                color: Color(0xFF7C3AED),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SmartCanteen',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
            const Text(
              'v1.0.0 (Build 2026)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sistem Pemesanan Makanan & Rekomendasi Menu Cerdas berbasis AI untuk kantin kampus.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4),
            ),
            const Divider(height: 32),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Developer', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('Kelompok 6', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Mata Kuliah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('Prog. Client-Server', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Platform', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                Text('Flutter & Firebase', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
              ],
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup', style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<AuthService>(
        builder: (context, auth, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 36),
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            (auth.userName ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        auth.userName ?? 'User',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        auth.userEmail ?? '',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 6),
                            Text(
                              'Pelanggan Setia',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Stats Row
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4)
                    ],
                  ),
                  child: Row(
                    children: [
                      _statItem(
                        icon: Icons.receipt_long_outlined,
                        value: _statsLoaded ? '$_totalOrders' : '-',
                        label: 'Pesanan',
                        color: const Color(0xFF7C3AED),
                      ),
                      _divider(),
                      _statItem(
                        icon: Icons.star_rounded,
                        value: '4.5',
                        label: 'Rating',
                        color: const Color(0xFFFF8C42),
                      ),
                      _divider(),
                      _statItem(
                        icon: Icons.favorite_outline,
                        value: '0',
                        label: 'Favorit',
                        color: Colors.pink,
                      ),
                    ],
                  ),
                ),

                // Menu Items
                _menuSection([
                  _menuItem(
                    icon: Icons.person_outline,
                    title: 'Edit Profil',
                    subtitle: 'Ubah nama dan informasi akun',
                    onTap: () => _showEditProfileDialog(context, auth),
                  ),
                  _menuItem(
                    icon: Icons.receipt_long_outlined,
                    title: 'Riwayat Pesanan',
                    subtitle: 'Lihat semua pesanan Anda',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.userOrders),
                  ),
                  _menuItem(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Rekomendasi AI',
                    subtitle: 'Menu spesial yang disesuaikan untuk Anda',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.userRecommendation),
                  ),
                  // Notifications menu item with live badge
                  _notificationMenuItem(context, auth),
                  _menuItem(
                    icon: Icons.chat_bubble_outline,
                    title: 'Bantuan',
                    subtitle: 'Chat dengan customer service',
                    onTap: () =>
                        Navigator.pushNamed(context, AppRoutes.userChat),
                  ),
                ]),

                const SizedBox(height: 8),

                _menuSection([
                  _menuItem(
                    icon: Icons.info_outline,
                    title: 'Tentang Aplikasi',
                    subtitle: 'SmartCanteen v1.0.0',
                    onTap: () => _showAboutAppDialog(context),
                  ),
                  _menuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle: 'Keluar dari akun',
                    color: Colors.red,
                    onTap: () => _showLogoutDialog(context, auth),
                  ),
                ]),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statItem(
      {required IconData icon,
      required String value,
      required String label,
      required Color color}) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(value,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 40, color: Colors.grey[200]);
  }

  Widget _menuSection(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? const Color(0xFF1F2937);
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: c, size: 20),
      ),
      title:
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: c)),
      subtitle: Text(subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  /// Notification menu item with live unread badge in the trailing area.
  Widget _notificationMenuItem(BuildContext context, AuthService auth) {
    final userId = auth.userId;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.notifications_outlined,
            color: Color(0xFF7C3AED), size: 20),
      ),
      title: const Text('Notifikasi',
          style: TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('Update status pesanan',
          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (userId != null)
            StreamBuilder<int>(
              stream: NotificationService().streamUnreadCount(userId),
              builder: (_, snap) {
                final count = snap.data ?? 0;
                if (count == 0) {
                  return Icon(Icons.chevron_right, color: Colors.grey[400]);
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                );
              },
            )
          else
            Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
      onTap: () => Navigator.pushNamed(context, AppRoutes.userNotification),
    );
  }
}
