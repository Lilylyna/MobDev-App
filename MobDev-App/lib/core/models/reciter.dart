class Reciter {
  final String id;
  final String name;
  final String shortName;
  final String server;

  Reciter({
    required this.id, 
    required this.name, 
    required this.shortName, 
    required this.server
  });

  factory Reciter.fromJson(Map<String, dynamic> json) {
    String serverUrl = '';
    if (json['moshaf'] != null && (json['moshaf'] as List).isNotEmpty) {
      serverUrl = json['moshaf'][0]['server'] ?? '';
    }

    return Reciter(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? 'Unknown',
      shortName: serverUrl.split('/').where((s) => s.isNotEmpty).last,
      server: serverUrl,
    );
  }
}
