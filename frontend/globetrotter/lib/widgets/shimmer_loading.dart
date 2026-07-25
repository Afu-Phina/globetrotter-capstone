import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A sweeping-gradient shimmer, built with just AnimationController + Shader
/// (no external package -- keeps dependencies minimal and avoids pulling in
/// something unverifiable in this environment). Used for loading states so
/// the app never shows a bare spinner where a content-shaped placeholder
/// would feel more finished.
class ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: widget.borderRadius,
          child: ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment(-1.5 + _controller.value * 3, 0),
                end: Alignment(-0.5 + _controller.value * 3, 0),
                colors: const [
                  Color(0xFF1B2820),
                  Color(0xFF283B2F),
                  Color(0xFF1B2820),
                ],
              ).createShader(bounds);
            },
            child: Container(
              height: widget.height,
              width: widget.width ?? double.infinity,
              color: const Color(0xFF1B2820),
            ),
          ),
        );
      },
    );
  }
}

/// Shimmer placeholder shaped like a DestinationCard, shown while lists load.
class DestinationCardShimmer extends StatelessWidget {
  const DestinationCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerBox(height: 56, width: 56, borderRadius: BorderRadius.circular(14)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerBox(height: 16, width: 140),
                  const SizedBox(height: 8),
                  const ShimmerBox(height: 12, width: 100),
                  const SizedBox(height: 10),
                  const ShimmerBox(height: 12),
                  const SizedBox(height: 4),
                  ShimmerBox(height: 12, width: MediaQuery.of(context).size.width * 0.4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
