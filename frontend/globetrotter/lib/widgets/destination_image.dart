import 'package:flutter/material.dart';

/// Renders a destination's photo from either a network URL or a bundled
/// local asset (e.g. a photo the user provided directly rather than one
/// sourced from the web). Local assets are declared with an "assets/"
/// prefix in destinations.json; anything else is treated as a network
/// image. [fallback] is shown on any load failure so a bad URL never
/// breaks the layout.
class DestinationImage extends StatelessWidget {
  final String source;
  final BoxFit fit;
  final Widget fallback;
  final String? debugLabel;

  const DestinationImage({
    super.key,
    required this.source,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.debugLabel,
  });

  bool get _isLocalAsset => source.startsWith('assets/');

  @override
  Widget build(BuildContext context) {
    if (_isLocalAsset) {
      return Image.asset(
        source,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // ignore: avoid_print
          print('[asset image load failed] ${debugLabel ?? ''}: $source -> $error');
          return fallback;
        },
      );
    }

    return Image.network(
      source,
      fit: fit,
      loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
      errorBuilder: (context, error, stackTrace) {
        // ignore: avoid_print
        print('[network image load failed] ${debugLabel ?? ''}: $source -> $error');
        return fallback;
      },
    );
  }
}
