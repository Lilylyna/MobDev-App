import 'package:audio_service/audio_service.dart';

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
      audioUrl: json['audio'] ?? 'https://server10.mp3quran.net/minsh/001.mp3',
      duration: Duration.zero,
    );
  }

  AudioTrack copyWith({
    String? id,
    String? title,
    String? category,
    String? audioUrl,
    Duration? duration,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      audioUrl: audioUrl ?? this.audioUrl,
      duration: duration ?? this.duration,
    );
  }

  MediaItem toMediaItem() {
    return MediaItem(
      id: audioUrl,
      album: category,
      title: title,
      duration: duration,
      extras: {'trackId': id},
    );
  }
}
