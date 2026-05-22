import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/audio_track.dart';

class ApiService {
  static const String baseUrl = 'https://quran.yousefheiba.com/api';

  Future<List<Map<String, dynamic>>> getSurahs() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/surahs'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des sourates: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getReciters() async {
    try {
      final response = await http
          .get(Uri.parse('https://mp3quran.net/api/v3/reciters?language=ar'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> reciters = data['reciters'] ?? [];
        return List<Map<String, dynamic>>.from(reciters);
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des récitateurs: $e');
    }
  }

  Future<AudioTrack> getTrackDetail(
    String id,
    String categoryName, {
    String? reciterShortName,
    String? reciterServer,
  }) async {
    final paddedId = id.padLeft(3, '0');

    if (reciterServer != null && reciterServer.isNotEmpty) {
      final String baseUrl = reciterServer.endsWith('/')
          ? reciterServer
          : '$reciterServer/';
      return AudioTrack(
        id: id,
        title: categoryName,
        category: 'Coran',
        audioUrl: '$baseUrl$paddedId.mp3',
        nameAr: null,
        duration: Duration.zero,
      );
    }

    final String fallbackReciter = reciterShortName ?? 'minsh';
    return AudioTrack(
      id: id,
      title: categoryName,
      category: 'Coran',
      audioUrl: 'https://server10.mp3quran.net/$fallbackReciter/$paddedId.mp3',
      nameAr: null,
      duration: Duration.zero,
    );
  }

  AudioTrack getTrackFromSurah(
    Map<String, dynamic> surah, {
    String? reciterShortName,
    String? reciterServer,
  }) {
    final id = surah['number']?.toString() ?? surah['id']?.toString() ?? '1';
    final name = surah['name_en'] ?? surah['title'] ?? 'Unknown';
    final nameAr = surah['name_ar'] ?? surah['name'];
    final paddedId = id.padLeft(3, '0');

    if (reciterServer != null && reciterServer.isNotEmpty) {
      final String baseUrl = reciterServer.endsWith('/')
          ? reciterServer
          : '$reciterServer/';
      return AudioTrack(
        id: id,
        title: name,
        category: 'Coran',
        audioUrl: '$baseUrl$paddedId.mp3',
        nameAr: nameAr,
        duration: Duration.zero,
      );
    }

    final String reciter = reciterShortName ?? 'minsh';
    return AudioTrack(
      id: id,
      title: name,
      category: 'Coran',
      audioUrl: 'https://server10.mp3quran.net/$reciter/$paddedId.mp3',
      nameAr: nameAr,
      duration: Duration.zero,
    );
  }
}
