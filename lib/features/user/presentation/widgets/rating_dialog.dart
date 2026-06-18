import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/rating_service.dart';
import '../../../../core/services/recommendation_service.dart';
import '../../../../features/admin/data/admin_models.dart' as models;
import 'star_rating_widget.dart';

/// Bottom-sheet dialog to rate all items in a completed order.
/// Shows one rating form per menu item, user can submit one at a time.
class RatingOrderSheet extends StatefulWidget {
  final models.Order order;

  const RatingOrderSheet({super.key, required this.order});

  @override
  State<RatingOrderSheet> createState() => _RatingOrderSheetState();
}

class _RatingOrderSheetState extends State<RatingOrderSheet> {
  final RatingService _ratingService = RatingService();

  // Per-item state: stars & review
  late List<double> _stars;
  late List<TextEditingController> _reviewCtrls;
  late List<bool> _submitted;
  Set<String> _alreadyRated = {};
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final count = widget.order.items.length;
    _stars = List.filled(count, 5.0);
    _reviewCtrls = List.generate(count, (_) => TextEditingController());
    _submitted = List.filled(count, false);
    _loadExistingRatings();
  }

  Future<void> _loadExistingRatings() async {
    final auth = context.read<AuthService>();
    if (auth.userId == null) return;

    final rated = await _ratingService.getRatedMenuIdsForOrder(
      orderId: widget.order.id,
      userId: auth.userId!,
    );
    if (mounted) {
      setState(() {
        _alreadyRated = rated;
        // Mark already-rated items as submitted
        for (int i = 0; i < widget.order.items.length; i++) {
          if (rated.contains(widget.order.items[i].menuId)) {
            _submitted[i] = true;
          }
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _submitRating(int index) async {
    final auth = context.read<AuthService>();
    if (auth.userId == null) return;

    final item = widget.order.items[index];
    setState(() => _isSubmitting = true);

    final ok = await _ratingService.submitRating(
      menuId: item.menuId,
      menuName: item.menuName,
      userId: auth.userId!,
      userName: auth.userName ?? 'User',
      orderId: widget.order.id,
      stars: _stars[index],
      review: _reviewCtrls[index].text.trim(),
    );

    if (ok) {
      // Invalidate recommendation cache on rating submission
      await RecommendationService().invalidateCache(auth.userId!);
    }

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        if (ok) {
          _submitted[index] = true;
          _alreadyRated.add(item.menuId);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok
              ? '⭐ Rating untuk ${item.menuName} berhasil disimpan!'
              : 'Gagal menyimpan rating. Coba lagi.'),
          backgroundColor: ok ? Colors.green : Colors.red,
        ),
      );
    }
  }

  bool get _allRated =>
      widget.order.items.every((item) => _alreadyRated.contains(item.menuId));

  @override
  void dispose() {
    for (final c in _reviewCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Beri Rating',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Bagaimana pengalaman makanan Anda?',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (_allRated)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.green, size: 14),
                          SizedBox(width: 4),
                          Text('Semua Dinilai',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      controller: ctrl,
                      padding: const EdgeInsets.all(16),
                      itemCount: widget.order.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, i) => _RatingItemCard(
                        item: widget.order.items[i],
                        stars: _stars[i],
                        controller: _reviewCtrls[i],
                        isSubmitted: _submitted[i],
                        isSubmitting: _isSubmitting,
                        onStarChanged: (v) => setState(() => _stars[i] = v),
                        onSubmit: () => _submitRating(i),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Per-item rating card ──────────────────────────────────────────────────────

class _RatingItemCard extends StatelessWidget {
  final dynamic item; // models.OrderItem
  final double stars;
  final TextEditingController controller;
  final bool isSubmitted;
  final bool isSubmitting;
  final ValueChanged<double> onStarChanged;
  final VoidCallback onSubmit;

  const _RatingItemCard({
    required this.item,
    required this.stars,
    required this.controller,
    required this.isSubmitted,
    required this.isSubmitting,
    required this.onStarChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isSubmitted ? Colors.green.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSubmitted
              ? Colors.green.withValues(alpha: 0.3)
              : Colors.grey[200]!,
          width: isSubmitted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                    child: Text('🍽️', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.menuName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '${item.quantity}x • Rp ${(item.price * item.quantity).toStringAsFixed(0)}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isSubmitted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text('Dinilai',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          ),

          if (!isSubmitted) ...[
            const SizedBox(height: 16),
            const Text(
              'Nilai Makanan',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),

            // Star selector
            Center(
              child: StarRatingWidget(
                rating: stars,
                size: 40,
                onChanged: onStarChanged,
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                _starLabel(stars),
                style: TextStyle(
                  color: _starColor(stars),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Review input
            TextField(
              controller: controller,
              maxLines: 3,
              maxLength: 200,
              decoration: InputDecoration(
                hintText: 'Tulis ulasan (opsional)...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                counterStyle: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
            ),
            const SizedBox(height: 12),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, size: 18),
                label: Text(isSubmitting ? 'Menyimpan...' : 'Kirim Rating'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ] else ...[
            // Already submitted — show summary
            const SizedBox(height: 12),
            Center(
              child: StarRatingWidget(
                rating: stars,
                size: 28,
                interactive: false,
              ),
            ),
            const SizedBox(height: 4),
            if (controller.text.isNotEmpty)
              Center(
                child: Text(
                  '"${controller.text}"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _starLabel(double s) {
    if (s >= 5) return 'Luar Biasa! ✨';
    if (s >= 4) return 'Sangat Enak 😋';
    if (s >= 3) return 'Cukup Enak 👍';
    if (s >= 2) return 'Kurang Memuaskan 😕';
    return 'Mengecewakan 😞';
  }

  Color _starColor(double s) {
    if (s >= 4) return Colors.green;
    if (s >= 3) return Colors.orange;
    return Colors.red;
  }
}
