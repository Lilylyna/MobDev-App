class AudioTrack {
  final String id;
  final String title;
  final String category;
  final String audioUrl;
  final Duration duration;

  AudioTrack({
    required this.id,
    required this.title,
    required this.category,
    required this.audioUrl,
    required this.duration,
  });

  factory AudioTrack.fromJson(Map<String, dynamic> json, String categoryName) {
    return AudioTrack(
      id: json['number'].toString(),
      title: json['name_en'] ?? json['englishName'] ?? 'Unknown',
      category: categoryName,
      audioUrl: json['audio'] ?? 'https://server10.mp3quran.net/minsh/001.mp3', // Sample fallback
      duration: Duration.zero, // API usually doesn't provide this directly
    );
  }
}
