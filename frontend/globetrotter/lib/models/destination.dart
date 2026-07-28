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
    );
  }
}
