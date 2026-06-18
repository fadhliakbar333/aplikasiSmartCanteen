import 'package:flutter/material.dart';

/// Interactive star rating bar — tap or drag to pick 1–5 stars.
class StarRatingWidget extends StatelessWidget {
  final double rating; // current value
  final double maxRating; // default 5
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool interactive; // false = display only
  final ValueChanged<double>? onChanged;

  const StarRatingWidget({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 32,
    this.activeColor = const Color(0xFFFF8C42),
    this.inactiveColor = const Color(0xFFE5E7EB),
    this.interactive = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxRating.toInt(), (index) {
        final starValue = index + 1.0;
        IconData icon;
        if (rating >= starValue) {
          icon = Icons.star_rounded;
        } else if (rating >= starValue - 0.5) {
          icon = Icons.star_half_rounded;
        } else {
          icon = Icons.star_outline_rounded;
        }
        final color = rating >= starValue - 0.5 ? activeColor : inactiveColor;

        if (!interactive) {
          return Icon(icon, color: color, size: size);
        }

        return GestureDetector(
          onTap: () => onChanged?.call(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(icon, color: color, size: size),
          ),
        );
      }),
    );
  }
}

/// Compact read-only rating display used in list cards.
class RatingDisplay extends StatelessWidget {
  final double rating;
  final int? count;
  final double size;

  const RatingDisplay({
    super.key,
    required this.rating,
    this.count,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, color: const Color(0xFFFF8C42), size: size),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: size - 1,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: size - 2,
              color: Colors.grey[500],
            ),
          ),
        ],
      ],
    );
  }
}
