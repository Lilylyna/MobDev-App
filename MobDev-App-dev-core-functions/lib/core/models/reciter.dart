class Reciter {
  final String id;
  final String name;
  final String shortName;

  Reciter({required this.id, required this.name, required this.shortName});

  factory Reciter.fromJson(Map<String, dynamic> json) {
    return Reciter(
      id: json['reciter_id'].toString(),
      name: json['reciter_name'] ?? 'Unknown',
      shortName: json['reciter_short_name'] ?? '',
    );
  }
}
