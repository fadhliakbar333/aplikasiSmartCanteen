import 'package:flutter/material.dart';

class MenuCard extends StatelessWidget {
  final String name;
  final double price;
  final double rating;
  final int sold;
  final String image;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final bool available;

  const MenuCard({
    super.key,
    required this.name,
    required this.price,
    required this.rating,
    required this.sold,
    required this.image,
    required this.onTap,
    required this.onAddToCart,
    this.available = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: available ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: available ? Colors.white : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: available ? const Color(0xFFE5E7EB) : const Color(0xFFF3F4F6),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(available ? 0.04 : 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Image (Emoji inside a beautiful circular background)
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: available 
                        ? const Color(0xFFF3E8FF) // Light lavender primary accent
                        : const Color(0xFFE5E7EB),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Opacity(
                      opacity: available ? 1.0 : 0.5,
                      child: Text(
                        image,
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: available
                              ? const Color(0xFF1F2937)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFF59E0B), size: 18), // Premium Amber/Gold
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: available
                                  ? const Color(0xFF374151)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '($sold terjual)',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Rp ${price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: available
                                  ? const Color(0xFF7C3AED) // Primary color for price
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                          GestureDetector(
                            onTap: available ? onAddToCart : null,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: available
                                    ? const Color(0xFF7C3AED)
                                    : const Color(0xFFE5E7EB),
                                shape: BoxShape.circle,
                                boxShadow: available
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF7C3AED).withOpacity(0.25),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                Icons.add,
                                color: available ? Colors.white : const Color(0xFF9CA3AF),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!available)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Tidak Tersedia',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

