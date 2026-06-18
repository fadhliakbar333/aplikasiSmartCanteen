import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/order_service.dart';
import '../../../../core/services/rating_service.dart';
import '../../../../features/admin/data/admin_models.dart' as models;
import '../widgets/empty_state_widget.dart';
import '../widgets/rating_dialog.dart';

class UserOrdersPage extends StatefulWidget {
  const UserOrdersPage({super.key});

  @override
  State<UserOrdersPage> createState() => _UserOrdersPageState();
}

class _UserOrdersPageState extends State<UserOrdersPage>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;

  final _tabs = const [
    Tab(text: 'Semua'),
    Tab(text: 'Proses'),
    Tab(text: 'Siap'),
    Tab(text: 'Selesai'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<models.Order> _filterOrders(List<models.Order> orders, int tabIndex) {
    switch (tabIndex) {
      case 1:
        return orders
            .where((o) => o.status == 'pending' || o.status == 'processing')
            .toList();
      case 2:
        return orders.where((o) => o.status == 'ready').toList();
      case 3:
        return orders.where((o) => o.status == 'completed').toList();
      default:
        return orders;
    }
  }

  void _openRatingSheet(models.Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => RatingOrderSheet(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().userId ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Saya'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          labelColor: const Color(0xFF7C3AED),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF7C3AED),
        ),
      ),
      body: StreamBuilder<List<models.Order>>(
        stream: _orderService.streamUserOrders(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final allOrders = List<models.Order>.from(snapshot.data ?? []);
          allOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

          return TabBarView(
            controller: _tabController,
            children: List.generate(_tabs.length, (tabIndex) {
              final orders = _filterOrders(allOrders, tabIndex);
              if (orders.isEmpty) {
                return EmptyStateWidget(
                  icon: Icons.receipt_long_outlined,
                  title: 'Tidak ada pesanan',
                  message: tabIndex == 0
                      ? 'Anda belum pernah memesan'
                      : 'Tidak ada pesanan di kategori ini',
                );
              }
              return RefreshIndicator(
                onRefresh: () async {},
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _OrderCard(
                      order: orders[index],
                      userId: userId,
                      onTap: () => _showOrderDetail(context, orders[index]),
                      onRate: () => _openRatingSheet(orders[index]),
                    );
                  },
                ),
              );
            }),
          );
        },
      ),
    );
  }

  void _showOrderDetail(BuildContext context, models.Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _OrderDetailSheet(
        order: order,
        onRate: () {
          Navigator.pop(context);
          _openRatingSheet(order);
        },
      ),
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────

class _OrderCard extends StatefulWidget {
  final models.Order order;
  final String userId;
  final VoidCallback onTap;
  final VoidCallback onRate;

  const _OrderCard({
    required this.order,
    required this.userId,
    required this.onTap,
    required this.onRate,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  final RatingService _ratingService = RatingService();
  bool _allRated = false;

  @override
  void initState() {
    super.initState();
    if (widget.order.status == 'completed') {
      _checkRatingStatus();
    }
  }

  Future<void> _checkRatingStatus() async {
    final rated = await _ratingService.getRatedMenuIdsForOrder(
      orderId: widget.order.id,
      userId: widget.userId,
    );
    if (mounted) {
      setState(() {
        _allRated =
            widget.order.items.every((item) => rated.contains(item.menuId));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ID & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      '#${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    if (order.paymentVerified) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Colors.green.withOpacity(0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle,
                                color: Colors.green, size: 10),
                            SizedBox(width: 2),
                            Text(
                              'Lunas',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 8),

            // Items
            Text(
              order.items.map((i) => '${i.quantity}x ${i.menuName}').join(', '),
              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Date & Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(order.orderDate),
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                ),
                Text(
                  'Rp ${order.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                      fontSize: 15),
                ),
              ],
            ),

            // Ready banner
            if (order.status == 'ready') ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_active,
                        color: Color(0xFF059669), size: 16),
                    SizedBox(width: 4),
                    Text('Pesanan siap diambil!',
                        style: TextStyle(color: Color(0xFF059669), fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],

            // ── Rating button (completed orders only) ──
            if (order.status == 'completed') ...[
              const SizedBox(height: 10),
              _allRated
                  ? Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Color(0xFFF59E0B), size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'Sudah dinilai',
                          style: TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 12,
                              fontStyle: FontStyle.italic),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: widget.onRate,
                          child: Text(
                            'Edit Rating',
                            style: TextStyle(
                              color: const Color(0xFF7C3AED)
                                  .withOpacity(0.7),
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: widget.onRate,
                        icon: const Icon(Icons.star_outline_rounded, size: 18),
                        label: const Text('Beri Rating Makanan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF59E0B),
                          side: const BorderSide(color: Color(0xFFF59E0B)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'pending':
        bgColor = const Color(0xFFFEF3C7); // Pastel amber
        textColor = const Color(0xFFD97706);
        label = 'Menunggu';
        break;
      case 'processing':
        bgColor = const Color(0xFFDBEAFE); // Pastel blue
        textColor = const Color(0xFF2563EB);
        label = 'Diproses';
        break;
      case 'ready':
        bgColor = const Color(0xFFD1FAE5); // Pastel green
        textColor = const Color(0xFF059669);
        label = 'Siap Diambil';
        break;
      case 'completed':
        bgColor = const Color(0xFFF3F4F6); // Pastel grey
        textColor = const Color(0xFF4B5563);
        label = 'Selesai';
        break;
      case 'cancelled':
        bgColor = const Color(0xFFFEE2E2); // Pastel red
        textColor = const Color(0xFFDC2626);
        label = 'Dibatalkan';
        break;
      default:
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF4B5563);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withOpacity(0.15)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Order Detail Sheet ────────────────────────────────────────────────────────

class _OrderDetailSheet extends StatelessWidget {
  final models.Order order;
  final VoidCallback onRate;
  const _OrderDetailSheet({required this.order, required this.onRate});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Detail Pesanan',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                _StatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 16),
            _OrderTimeline(status: order.status),
            const SizedBox(height: 20),

            const Text('Item Pesanan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Text('${item.quantity}x ',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(item.menuName)),
                      Text(
                          'Rp ${(item.price * item.quantity).toStringAsFixed(0)}'),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Rp ${order.totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF7C3AED),
                        fontSize: 16)),
              ],
            ),

            const Divider(height: 20),
            _infoRow('Penerima', order.userName),
            if (order.userPhone.isNotEmpty)
              _infoRow('Telepon', order.userPhone),
            _infoRow('Pembayaran', order.paymentVerified ? 'Terverifikasi (Lunas) ✅' : 'Belum Diverifikasi ⏳'),

            // Rating CTA for completed orders
            if (order.status == 'completed') ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('⭐', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 8),
                        Text(
                          'Bagaimana pesanan Anda?',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bantu pengguna lain dengan memberi rating',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onRate,
                        icon: const Icon(Icons.star_rounded, size: 18),
                        label: const Text('Beri Rating', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
              width: 80,
              child: Text(label,
                  style: const TextStyle(color: Colors.grey, fontSize: 13))),
          Expanded(
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }
}

// ── Timeline ──────────────────────────────────────────────────────────────────

class _OrderTimeline extends StatelessWidget {
  final String status;
  const _OrderTimeline({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled') {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFCA5A5).withOpacity(0.5)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text(
              'Pesanan Telah Dibatalkan',
              style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ],
        ),
      );
    }

    final steps = [
      {'label': 'Diterima', 'status': 'pending'},
      {'label': 'Diproses', 'status': 'processing'},
      {'label': 'Siap', 'status': 'ready'},
      {'label': 'Selesai', 'status': 'completed'},
    ];

    int activeIndex = steps.indexWhere((s) => s['status'] == status);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIndex = i ~/ 2;
            final isPassed = activeIndex > stepIndex;
            return Expanded(
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: isPassed ? const Color(0xFF7C3AED) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final isDone = activeIndex >= stepIndex;
          final isCurrent = activeIndex == stepIndex;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone ? const Color(0xFF7C3AED) : Colors.white,
                  border: Border.all(
                    color: isDone 
                        ? const Color(0xFF7C3AED) 
                        : const Color(0xFFD1D5DB),
                    width: isCurrent ? 2.5 : 1.5,
                  ),
                  boxShadow: isCurrent ? [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ] : null,
                ),
                child: Center(
                  child: Icon(
                    isDone ? Icons.check_rounded : Icons.radio_button_off_rounded,
                    color: isDone ? Colors.white : const Color(0xFF9CA3AF),
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                steps[stepIndex]['label']!,
                style: TextStyle(
                    fontSize: 10,
                    color: isDone ? const Color(0xFF7C3AED) : const Color(0xFF6B7280),
                    fontWeight: isDone ? FontWeight.bold : FontWeight.normal),
              ),
            ],
          );
        }),
      ),
    );
  }
}
