import 'package:flutter/material.dart';

/// Clips a container's bottom edge into a silhouette of seven overlapping
/// hills — Yaoundé's nickname ("la ville aux sept collines") made literal.
/// This is the app's one signature shape: used on hero headers so the
/// motif carries real meaning rather than being a generic decorative wave.
class HillClipper extends CustomClipper<Path> {
  const HillClipper();

  static const _hillCount = 7;
  // Fraction of height for each peak (smaller = taller hill). Irregular
  // heights read as a real skyline rather than a mechanical repeat.
  static const _peakFractions = [0.55, 0.64, 0.48, 0.68, 0.52, 0.62, 0.46];
  static const _baselineFraction = 0.84;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final baseline = h * _baselineFraction;
    final segment = w / _hillCount;

    final path = Path()..moveTo(0, baseline);

    for (int i = 0; i < _hillCount; i++) {
      final peakX = (i + 0.5) * segment;
      final peakY = h * _peakFractions[i];
      final endX = (i + 1) * segment;
      path.quadraticBezierTo(peakX, peakY, endX, baseline);
    }

    path.lineTo(w, 0);
    path.lineTo(0, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Convenience wrapper: a gradient hero panel clipped to the hill shape.
class HillHero extends StatelessWidget {
  final double height;
  final Widget child;
  final List<Color> gradientColors;

  const HillHero({
    super.key,
    required this.height,
    required this.child,
    required this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: const HillClipper(),
      child: Container(
        width: double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: child,
      ),
    );
  }
}
