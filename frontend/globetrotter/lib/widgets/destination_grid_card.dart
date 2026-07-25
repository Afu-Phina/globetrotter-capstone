import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/destination.dart';
import 'rating_stars.dart';

/// Category -> (icon, cover gradient). Since Phase 1 has no image hosting,
/// this stands in for a photo: a rich, category-specific gradient tile
/// with a large icon, rather than a generic placeholder or a fabricated
/// stock photo.
class _CoverStyle {
  final IconData icon;
  final List<Color> gradient;
  const _CoverStyle(this.icon, this.gradient);
}

const Map<String, _CoverStyle> _coverStyles = {
  'Nature & Wildlife': _CoverStyle(Icons.pets_rounded, [Color(0xFF2F6B4F), Color(0xFF63A181)]),
  'History & Culture': _CoverStyle(Icons.account_balance_rounded, [Color(0xFF6B4B2F), Color(0xFFA07C4C)]),
  'Markets & Shopping': _CoverStyle(Icons.storefront_rounded, [Color(0xFFE4573F), Color(0xFFF0805E)]),
  'Nature & Views': _CoverStyle(Icons.terrain_rounded, [Color(0xFF15352A), Color(0xFF3E7A61)]),
  'Nightlife & Dining': _CoverStyle(Icons.local_bar_rounded, [Color(0xFF6A2F5B), Color(0xFFA35C90)]),
  'Local Life': _CoverStyle(Icons.groups_rounded, [Color(0xFFC97F1E), Color(0xFFF0A93D)]),
};

_CoverStyle _styleFor(String category) =>
    _coverStyles[category] ?? const _CoverStyle(Icons.place_rounded, [AppColors.forest, AppColors.forestMid]);

class DestinationGridCard extends StatefulWidget {
  final Destination destination;
  final VoidCallback? onTap;

  const DestinationGridCard({super.key, required this.destination, this.onTap});

  @override
  State<DestinationGridCard> createState() => _DestinationGridCardState();
}

class _DestinationGridCardState extends State<DestinationGridCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(widget.destination.category);

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.3,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: style.gradient,
                        ),
                      ),
                      child: Center(
                        child: Icon(style.icon, color: Colors.white.withOpacity(0.85), size: 44),
                      ),
                    ),
                    if (widget.destination.popularity >= 85)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.marigold,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.local_fire_department, size: 12, color: AppColors.forestDeep),
                              SizedBox(width: 2),
                              Text(
                                'Popular',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.forestDeep,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.destination.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.destination.neighborhood,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    RatingStars(
                      averageRating: widget.destination.averageRating,
                      reviewCount: widget.destination.reviewCount,
                      size: 11,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
