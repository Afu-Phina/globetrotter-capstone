import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/destination.dart';

/// Maps each destination category to an icon + gradient pair, so the app
/// reads as designed rather than every card using the same generic pin.
class _CategoryStyle {
  final IconData icon;
  final List<Color> gradient;
  const _CategoryStyle(this.icon, this.gradient);
}

const Map<String, _CategoryStyle> _categoryStyles = {
  'Nature & Wildlife': _CategoryStyle(
    Icons.pets_rounded,
    [Color(0xFF2F6B4F), Color(0xFF4C8A69)],
  ),
  'History & Culture': _CategoryStyle(
    Icons.account_balance_rounded,
    [Color(0xFF6B4B2F), Color(0xFF8A6A4C)],
  ),
  'Markets & Shopping': _CategoryStyle(
    Icons.storefront_rounded,
    [Color(0xFFE4573F), Color(0xFFF0805E)],
  ),
  'Nature & Views': _CategoryStyle(
    Icons.terrain_rounded,
    [Color(0xFF15352A), Color(0xFF285443)],
  ),
  'Nightlife & Dining': _CategoryStyle(
    Icons.local_bar_rounded,
    [Color(0xFF6A2F5B), Color(0xFF8A4C7A)],
  ),
  'Local Life': _CategoryStyle(
    Icons.groups_rounded,
    [Color(0xFFF0A93D), Color(0xFFF8D48A)],
  ),
  'Sports & Recreation': _CategoryStyle(
    Icons.sports_soccer_rounded,
    [Color(0xFF1F5C6B), Color(0xFF4D96A8)],
  ),
};

_CategoryStyle _styleFor(String category) =>
    _categoryStyles[category] ?? const _CategoryStyle(Icons.place_rounded, [
      AppColors.forestDeep,
      AppColors.forestMid,
    ]);

class DestinationCard extends StatefulWidget {
  final Destination destination;
  final VoidCallback? onTap;
  final Widget? trailing;

  const DestinationCard({
    super.key,
    required this.destination,
    this.onTap,
    this.trailing,
  });

  @override
  State<DestinationCard> createState() => _DestinationCardState();
}

class _DestinationCardState extends State<DestinationCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final style = _styleFor(widget.destination.category);

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: widget.onTap,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: style.gradient,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: style.gradient.first.withOpacity(0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(style.icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.destination.name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.place, size: 12, color: AppColors.inkMuted),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '${widget.destination.category} · ${widget.destination.neighborhood}',
                              style: Theme.of(context).textTheme.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        widget.destination.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.destination.tags
                            .map((tag) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.papaya.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    tag,
                                    style: const TextStyle(fontSize: 11, color: AppColors.papaya, fontWeight: FontWeight.w600),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
