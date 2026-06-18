import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/order_service.dart';
import '../../../../features/admin/data/admin_models.dart' as models;

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage>
    with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  late TabController _tabController;

  final _tabs = const [
    Tab(text: 'Semua'),
    Tab(text: 'Menunggu'),
    Tab(text: 'Diproses'),
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
        return orders.where((o) => o.status == 'pending').toList();
      case 2:
        return orders.where((o) => o.status == 'processing').toList();
      case 3:
        return orders.where((o) => o.status == 'ready').toList();
      case 4:
        return orders.where((o) => o.status == 'completed').toList();
      default:
        return orders;
    }
  }

  Future<void> _updateStatus(models.Order order, String newStatus) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah Status Pesanan'),
        content: Text(
            'Ubah status pesanan #${order.id.substring(0, 8)} ke "${_statusLabel(newStatus)}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ya, Ubah')),
        ],
      ),
    );
    if (confirm != true) return;

    final success = await _orderService.updateOrderStatus(order.id, newStatus);

    if (success) {
      // 🔔 Kirim notifikasi ke user
      final shortId = order.id.length >= 8
          ? order.id.substring(0, 8).toUpperCase()
          : order.id.toUpperCase();
      unawaited(
        NotificationService().sendOrderStatusNotification(
          userId: order.userId,
          orderId: order.id,
          orderShortId: shortId,
          newStatus: newStatus,
        ),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(success ? 'Status berhasil diubah' : 'Gagal mengubah status'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'processing':
        return 'Diproses';
      case 'ready':
        return 'Siap';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Kelola Pesanan',
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
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
          labelColor: const Color(0xFF7C3AED),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelColor: const Color(0xFF9CA3AF),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          indicatorColor: const Color(0xFF7C3AED),
          indicatorWeight: 3,
          isScrollable: true,
        ),
      ),
      body: StreamBuilder<List<models.Order>>(
        stream: _orderService.streamAllOrders(),
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
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Tidak ada pesanan',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, index) => _AdminOrderCard(
                  order: orders[index],
                  onUpdateStatus: _updateStatus,
                  statusLabel: _statusLabel,
                  onTap: () => _showOrderDetail(context, orders[index]),
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
      builder: (_) => _AdminOrderDetailSheet(
        order: order,
        onUpdateStatus: _updateStatus,
        statusLabel: _statusLabel,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
class _AdminOrderCard extends StatelessWidget {
  final models.Order order;
  final Future<void> Function(models.Order, String) onUpdateStatus;
  final String Function(String) statusLabel;
  final VoidCallback onTap;

  const _AdminOrderCard({
    required this.order,
    required this.onUpdateStatus,
    required this.statusLabel,
    required this.onTap,
  });

  Color _statusTextColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFD97706);
      case 'processing':
        return const Color(0xFF2563EB);
      case 'ready':
        return const Color(0xFF059669);
      case 'completed':
        return const Color(0xFF4B5563);
      case 'cancelled':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF4B5563);
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFEF3C7);
      case 'processing':
        return const Color(0xFFDBEAFE);
      case 'ready':
        return const Color(0xFFD1FAE5);
      case 'completed':
        return const Color(0xFFF3F4F6);
      case 'cancelled':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  String? _nextStatus(String current) {
    switch (current) {
      case 'pending':
        return 'processing';
      case 'processing':
        return 'ready';
      case 'ready':
        return 'completed';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _statusTextColor(order.status);
    final bgColor = _statusBgColor(order.status);
    final next = _nextStatus(order.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '#${order.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        if (order.paymentVerified) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Color(0xFF059669), size: 10),
                                SizedBox(width: 2),
                                Text(
                                  'Lunas',
                                  style: TextStyle(
                                      color: Color(0xFF059669),
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.userName,
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    statusLabel(order.status),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              order.items.map((i) => '${i.quantity}x ${i.menuName}').join(', '),
              style: const TextStyle(color: Color(0xFF4B5563), fontSize: 13, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(order.orderDate),
                  style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11, fontWeight: FontWeight.w500),
                ),
                Text(
                  'Rp ${order.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF7C3AED),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            if (next != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => onUpdateStatus(order, next),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _statusTextColor(next),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Ubah ke ${_statusName(next)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusName(String status) {
    switch (status) {
      case 'processing':
        return 'Diproses';
      case 'ready':
        return 'Siap';
      case 'completed':
        return 'Selesai';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────
class _AdminOrderDetailSheet extends StatefulWidget {
  final models.Order order;
  final Future<void> Function(models.Order, String) onUpdateStatus;
  final String Function(String) statusLabel;

  const _AdminOrderDetailSheet({
    required this.order,
    required this.onUpdateStatus,
    required this.statusLabel,
  });

  @override
  State<_AdminOrderDetailSheet> createState() => _AdminOrderDetailSheetState();
}

class _AdminOrderDetailSheetState extends State<_AdminOrderDetailSheet> {
  final OrderService _orderService = OrderService();
  late bool _paymentVerified;
  bool _isUpdatingPayment = false;

  @override
  void initState() {
    super.initState();
    _paymentVerified = widget.order.paymentVerified;
  }

  String? _nextStatus(String current) {
    switch (current) {
      case 'pending':
        return 'processing';
      case 'processing':
        return 'ready';
      case 'ready':
        return 'completed';
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final next = _nextStatus(widget.order.status);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          controller: ctrl,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Center(
              child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5))),
            ),
            const SizedBox(height: 20),
            Text(
              'Detail Pesanan #${widget.order.id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2937), letterSpacing: -0.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3F4F6), width: 1.2),
              ),
              child: Column(
                children: [
                  _infoRow('Pelanggan', widget.order.userName),
                  const SizedBox(height: 8),
                  _infoRow('Telepon', widget.order.userPhone),
                  const SizedBox(height: 8),
                  _infoRow('Status', widget.statusLabel(widget.order.status)),
                  const SizedBox(height: 8),
                  _infoRow('Tanggal',
                      '${widget.order.orderDate.day}/${widget.order.orderDate.month}/${widget.order.orderDate.year}'),
                  if (widget.order.notes != null && widget.order.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _infoRow('Catatan', widget.order.notes!),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Payment Verification Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _paymentVerified
                    ? const Color(0xFFD1FAE5).withOpacity(0.3)
                    : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: _paymentVerified
                        ? const Color(0xFF10B981).withOpacity(0.2)
                        : const Color(0xFFE5E7EB),
                    width: 1.2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Verifikasi Pembayaran',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF374151)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _paymentVerified
                              ? 'Pembayaran Terverifikasi (Lunas)'
                              : 'Tandai jika pembayaran telah diterima',
                          style: TextStyle(
                              color: _paymentVerified ? const Color(0xFF059669) : const Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: _paymentVerified
                                  ? FontWeight.bold
                                  : FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  if (_isUpdatingPayment)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7C3AED)),
                      ),
                    )
                  else
                    Checkbox(
                      value: _paymentVerified,
                      activeColor: const Color(0xFF7C3AED),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) async {
                        if (val == null) return;
                        setState(() => _isUpdatingPayment = true);
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await _orderService.updatePaymentVerification(
                            widget.order.id, val);
                        if (mounted) {
                          setState(() {
                            _isUpdatingPayment = false;
                            if (success) {
                              _paymentVerified = val;
                            }
                          });
                          if (success) {
                            messenger.showSnackBar(SnackBar(
                              content: Text(val
                                  ? 'Pembayaran berhasil diverifikasi!'
                                  : 'Verifikasi pembayaran dibatalkan.'),
                              backgroundColor: Colors.green,
                            ));
                          } else {
                            messenger.showSnackBar(const SnackBar(
                              content: Text('Gagal mengubah verifikasi pembayaran'),
                              backgroundColor: Colors.red,
                            ));
                          }
                        }
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Item Pesanan',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF3F4F6), width: 1.2),
              ),
              child: Column(
                children: [
                  ...widget.order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Text(
                              '${item.quantity}x ',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                            ),
                            Expanded(
                              child: Text(
                                item.menuName,
                                style: const TextStyle(fontWeight: FontWeight.w500, color: Color(0xFF374151)),
                              ),
                            ),
                            Text(
                              'Rp ${(item.price * item.quantity).toStringAsFixed(0)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
                            ),
                          ],
                        ),
                      )),
                  const Divider(height: 20, thickness: 1),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Transaksi',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4B5563)),
                      ),
                      Text(
                        'Rp ${widget.order.totalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF7C3AED),
                            fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (next != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onUpdateStatus(widget.order, next);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Ubah ke "${widget.statusLabel(next)}"',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
            if (widget.order.status == 'pending') ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onUpdateStatus(widget.order, 'cancelled');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Batalkan Pesanan',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
    return Row(
      children: [
        SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13, fontWeight: FontWeight.w600),
            )),
        Expanded(
            child: Text(
          value,
          style: const TextStyle(
              fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF374151)),
        )),
      ],
    );
  }
}
