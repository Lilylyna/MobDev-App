import 'package:audio_service/audio_service.dart';

class AudioTrack {
  final String id;
  final String title;
  final String category;
  final String audioUrl;
  final String? nameAr;
  final Duration duration;

  AudioTrack({
    required this.id,
    required this.title,
    required this.category,
    required this.audioUrl,
    this.nameAr,
    required this.duration,
  });

  factory AudioTrack.fromJson(Map<String, dynamic> json, String categoryName) {
    final idStr = json['number']?.toString() ?? json['id']?.toString() ?? '001';
    final paddedId = idStr.padLeft(3, '0');
    
    return AudioTrack(
      id: idStr,
      title: json['name_en'] ?? json['englishName'] ?? json['title'] ?? 'Unknown',
      category: categoryName,
      audioUrl: json['audio'] ?? json['audioUrl'] ?? 'https://server10.mp3quran.net/minsh/$paddedId.mp3',
      nameAr: json['name_ar'] ?? json['name'] ?? '',
      duration: Duration.zero,
    );
  }

  AudioTrack copyWith({
    String? id,
    String? title,
    String? category,
    String? audioUrl,
    String? nameAr,
    Duration? duration,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      audioUrl: audioUrl ?? this.audioUrl,
      nameAr: nameAr ?? this.nameAr,
      duration: duration ?? this.duration,
    );
  }

  MediaItem toMediaItem() {
    return MediaItem(
      id: audioUrl,
      album: category,
      title: title,
      duration: duration,
      extras: {
        'trackId': id,
        'name_ar': nameAr,
      },
    );
  }
}
