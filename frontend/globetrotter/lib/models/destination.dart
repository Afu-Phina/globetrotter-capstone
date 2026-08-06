class Destination {
  final String id;
  final String name;
  final String category;
  final String neighborhood;
  final String description;
  final List<String> tags;
  final int popularity;
  final double? averageRating;
  final int reviewCount;
  // Optional real photo URL. Null for every seeded destination right now
  // (Phase 1 has no image hosting) -- the UI falls back to a gradient
  // cover tile when this is absent, rather than showing a fake photo.
  // Set this in destinations.json to have a real photo appear instead.
  final String? imageUrl;
  // Required credit line when imageUrl is a real, licensed photo (e.g.
  // Wikimedia Commons under CC BY-SA, which requires attribution). Null
  // when there's no real photo.
  final String? imageAttribution;
  // Editorial estimate of how long a typical visit takes -- authored per
  // place (like a guidebook would give), not a live/computed value. Null
  // if we haven't estimated one yet.
  final int? estimatedVisitMinutes;
  // Only populated for destinations where real, verified facts were
  // found -- null for places we don't have confirmed history on, rather
  // than a guess.
  final String? history;
  final String? funFact;
  final List<String> travelTips;

  Destination({
    required this.id,
    required this.name,
    required this.category,
    required this.neighborhood,
    required this.description,
    required this.tags,
    required this.popularity,
    this.averageRating,
    this.reviewCount = 0,
    this.imageUrl,
    this.imageAttribution,
    this.estimatedVisitMinutes,
    this.history,
    this.funFact,
    this.travelTips = const [],
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      neighborhood: json['neighborhood'],
      description: json['description'],
      tags: List<String>.from(json['tags'] ?? []),
      popularity: json['popularity'] ?? 0,
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] ?? 0,
      imageUrl: json['image_url'],
      imageAttribution: json['image_attribution'],
      estimatedVisitMinutes: json['estimated_visit_minutes'],
      history: json['history'],
      funFact: json['fun_fact'],
      travelTips: List<String>.from(json['travel_tips'] ?? []),
    );
  }

  /// e.g. "~40 min" or "~1.5 hr" -- for display only.
  String? get formattedVisitDuration {
    final minutes = estimatedVisitMinutes;
    if (minutes == null) return null;
    if (minutes < 60) return '~$minutes min';
    final hours = minutes / 60;
    final rounded = (hours * 2).round() / 2; // nearest half hour
    final label = rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toString();
    return '~$label hr';
  }
}
