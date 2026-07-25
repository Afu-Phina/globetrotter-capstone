class Visit {
  final String id;
  final String destinationId;
  final String destinationName;
  final String date;
  final String time;
  final int numPeople;
  final String status;
  final String createdAt;

  Visit({
    required this.id,
    required this.destinationId,
    required this.destinationName,
    required this.date,
    required this.time,
    required this.numPeople,
    required this.status,
    required this.createdAt,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['id'],
      destinationId: json['destination_id'],
      destinationName: json['destination_name'],
      date: json['date'],
      time: json['time'],
      numPeople: json['num_people'],
      status: json['status'],
      createdAt: json['created_at'],
    );
  }
}
