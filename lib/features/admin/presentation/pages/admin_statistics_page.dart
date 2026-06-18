import 'package:flutter/material.dart';
import '../../../../core/services/order_service.dart';
import '../../../../features/admin/data/admin_models.dart' as models;

class AdminStatisticsPage extends StatefulWidget {
  const AdminStatisticsPage({super.key});

  @override
  State<AdminStatisticsPage> createState() => _AdminStatisticsPageState();
}

class _AdminStatisticsPageState extends State<AdminStatisticsPage> {
  final OrderService _orderService = OrderService();

  List<models.Order> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final orders = await _orderService.getAllOrders();
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  // ── derived stats ──────────────────────────────────────────
  List<models.Order> get _completedOrders =>
      _orders.where((o) => o.status == 'completed').toList();

  double get _totalRevenue =>
      _completedOrders.fold(0.0, (s, o) => s + o.totalPrice);

  int get _pendingOrders => _orders.where((o) => o.status == 'pending').length;

  double get _completionRate =>
      _orders.isEmpty ? 0 : (_completedOrders.length / _orders.length * 100);

  List<MapEntry<String, int>> get _topMenus {
    final map = <String, int>{};
    for (final order in _orders) {
      for (final item in order.items) {
        map[item.menuName] = (map[item.menuName] ?? 0) + item.quantity;
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  List<_DayData> get _weeklyData {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final count = _orders.where((o) {
        return o.orderDate.year == day.year &&
            o.orderDate.month == day.month &&
            o.orderDate.day == day.day;
      }).length;
      const labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
      final label = labels[(day.weekday - 1).clamp(0, 6)];
      return _DayData(label: label, count: count);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Statistik Laporan',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Color(0xFF1F2937),
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF7C3AED),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionTitle('Ringkasan Bisnis'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                        icon: Icons.shopping_bag_outlined,
                        label: 'Total Pesanan',
                        value: '${_orders.length}',
                        color: const Color(0xFF7C3AED),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Selesai',
                        value: '${_completedOrders.length}',
                        color: const Color(0xFF10B981),
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                          child: _StatCard(
                        icon: Icons.pending_outlined,
                        label: 'Menunggu',
                        value: '$_pendingOrders',
                        color: const Color(0xFFF59E0B),
                      )),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _StatCard(
                        icon: Icons.trending_up_rounded,
                        label: 'Pendapatan',
                        value:
                            'Rp ${(_totalRevenue / 1000).toStringAsFixed(0)}K',
                        color: const Color(0xFF3B82F6),
                      )),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sectionTitle('Tingkat Penyelesaian'),
                  const SizedBox(height: 12),
                  _CompletionRateCard(rate: _completionRate),
                  const SizedBox(height: 24),
                  _sectionTitle('Pesanan 7 Hari Terakhir'),
                  const SizedBox(height: 12),
                  _WeeklyBarChart(data: _weeklyData),
                  const SizedBox(height: 24),
                  if (_topMenus.isNotEmpty) ...[
                    _sectionTitle('Menu Terlaris'),
                    const SizedBox(height: 12),
                    _TopMenusList(items: _topMenus),
                    const SizedBox(height: 24),
                  ],
                  _sectionTitle('Distribusi Status Pesanan'),
                  const SizedBox(height: 12),
                  _StatusBreakdown(orders: _orders),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) => Text(
        title,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1F2937),
            letterSpacing: -0.3),
      );
}

// ── Reusable Widgets ──────────────────────────────────────────────────────────

class _DayData {
  final String label;
  final int count;
  _DayData({required this.label, required this.count});
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionRateCard extends StatelessWidget {
  final double rate;
  const _CompletionRateCard({required this.rate});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Rasio Pesanan Sukses',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4B5563))),
              Text('${rate.toStringAsFixed(1)}%',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF10B981))),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 8,
              backgroundColor: const Color(0xFFF3F4F6),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  final List<_DayData> data;
  const _WeeklyBarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxCount = data.map((d) => d.count).fold(0, (a, b) => a > b ? a : b);
    const maxHeight = 120.0;

    return Container(
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
      child: SizedBox(
        height: maxHeight + 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.map((d) {
            final barH = maxCount == 0 ? 0.0 : (d.count / maxCount) * maxHeight;
            return Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (d.count > 0)
                  Text(
                    '${d.count}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                  ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 600),
                  width: 24,
                  height: barH.clamp(4, maxHeight),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(d.label,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TopMenusList extends StatelessWidget {
  final List<MapEntry<String, int>> items;
  const _TopMenusList({required this.items});

  @override
  Widget build(BuildContext context) {
    final maxSold = items.isNotEmpty ? items.first.value : 1;
    return Container(
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
      child: Column(
        children: List.generate(items.length, (i) {
          final entry = items[i];
          final ratio = entry.value / maxSold;
          final medalColor = i == 0
              ? const Color(0xFFF59E0B)
              : i == 1
                  ? const Color(0xFF9CA3AF)
                  : i == 2
                      ? const Color(0xFFCD7F32)
                      : const Color(0xFF7C3AED).withOpacity(0.6);
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                          color: medalColor, shape: BoxShape.circle),
                      child: Center(
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(
                      entry.key,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151)),
                    )),
                    Text(
                      '${entry.value} terjual',
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF3F4F6),
                    valueColor: AlwaysStoppedAnimation<Color>(medalColor),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StatusBreakdown extends StatelessWidget {
  final List<models.Order> orders;
  const _StatusBreakdown({required this.orders});

  @override
  Widget build(BuildContext context) {
    final statuses = {
      'pending': 'Menunggu',
      'processing': 'Diproses',
      'ready': 'Siap',
      'completed': 'Selesai',
      'cancelled': 'Dibatalkan',
    };
    final colors = {
      'pending': const Color(0xFFF59E0B),
      'processing': const Color(0xFF3B82F6),
      'ready': const Color(0xFF10B981),
      'completed': const Color(0xFF6B7280),
      'cancelled': const Color(0xFFEF4444),
    };
    return Container(
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
      child: Column(
        children: statuses.entries.map((entry) {
          final count = orders.where((o) => o.status == entry.key).length;
          final pct = orders.isEmpty ? 0.0 : count / orders.length;
          final color = colors[entry.key]!;
          return ListTile(
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            title: Text(
              entry.value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF374151)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$count',
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2937)),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${(pct * 100).toStringAsFixed(0)}%)',
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
