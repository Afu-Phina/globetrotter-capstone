import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// Renders a destination's photo. The `source` string can be:
///  - A full network URL (e.g. a Wikimedia Commons photo) -> loaded directly.
///  - A path starting with "/static/" -> a photo the user provided, served
///    by our own Flask backend from app/static/images/. Prefixed with the
///    backend's host and loaded the same way as any other network image --
///    this reuses the exact code path already confirmed working for the
///    Wikimedia photos, instead of Flutter's separate asset-bundling system
///    (which requires a full rebuild + `flutter pub get` and was proving
///    unreliable to diagnose remotely).
/// [fallback] is shown on any load failure so a bad path never breaks
/// the layout.
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

  String get _resolvedUrl {
    if (source.startsWith('http')) return source;
    // Relative path served by our own backend (e.g. "/static/images/x.png").
    return '${ApiService.mediaBaseUrl}$source';
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolvedUrl;
    return Image.network(
      url,
      fit: fit,
      loadingBuilder: (context, child, progress) => progress == null ? child : fallback,
      errorBuilder: (context, error, stackTrace) {
        // ignore: avoid_print
        print('[image load failed] ${debugLabel ?? ''}: $url -> $error');
        return fallback;
      },
    );
  }
}
