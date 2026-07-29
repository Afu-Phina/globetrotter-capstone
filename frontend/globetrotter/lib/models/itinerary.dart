class Itinerary {
  final String id;
  final String ownerId;
  final String title;
  final String? startDate;
  final String? endDate;
  final List<String> destinationIds;
  final String notes;
  final List<String> sharedWith;
  final String createdAt;

  Itinerary({
    required this.id,
    required this.ownerId,
    required this.title,
    this.startDate,
    this.endDate,
    required this.destinationIds,
    required this.notes,
    required this.sharedWith,
    required this.createdAt,
  });

  factory Itinerary.fromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: json['id'],
      ownerId: json['owner_id'],
      title: json['title'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      destinationIds: List<String>.from(json['destination_ids'] ?? []),
      notes: json['notes'] ?? '',
      sharedWith: List<String>.from(json['shared_with'] ?? []),
      createdAt: json['created_at'],
    );
  }
}
