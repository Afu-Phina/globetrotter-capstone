import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Displays a star rating from real review data. Shows nothing decorative
/// when there are no reviews yet, rather than inventing a placeholder score.
class RatingStars extends StatelessWidget {
  final double? averageRating;
  final int reviewCount;
  final double size;

  const RatingStars({
    super.key,
    required this.averageRating,
    required this.reviewCount,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (averageRating == null || reviewCount == 0) {
      return Text(
        'No reviews yet',
        style: TextStyle(fontSize: size - 1, color: AppColors.inkMuted),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: size + 2, color: AppColors.marigold),
        const SizedBox(width: 2),
        Text(
          averageRating!.toStringAsFixed(1),
          style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const SizedBox(width: 3),
        Text(
          '($reviewCount)',
          style: TextStyle(fontSize: size - 1, color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

/// Interactive 1-5 star picker, used when writing a review.
class RatingPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const RatingPicker({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starIndex = i + 1;
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          icon: Icon(
            starIndex <= value ? Icons.star_rounded : Icons.star_border_rounded,
            color: AppColors.marigold,
            size: 30,
          ),
          onPressed: () => onChanged(starIndex),
        );
      }),
    );
  }
}
