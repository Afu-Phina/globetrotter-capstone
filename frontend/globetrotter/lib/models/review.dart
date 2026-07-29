class Review {
  final String id;
  final String destinationId;
  final String authorName;
  final int rating;
  final String comment;
  final String createdAt;

  Review({
    required this.id,
    required this.destinationId,
    required this.authorName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      destinationId: json['destination_id'],
      authorName: json['author_name'],
      rating: json['rating'],
      comment: json['comment'],
      createdAt: json['created_at'],
    );
  }
}
