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
          .get(Uri.parse('$baseUrl/reciters'))
          .timeout(const Duration(seconds: 10));
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
  }) async {
    try {
      // Si on a un récitateur spécifique, on construit l'URL directement (Pattern courant MP3Quran)
      if (reciterShortName != null) {
        final paddedId = id.padLeft(3, '0');
        return AudioTrack(
          id: id,
          title: categoryName,
          category: 'Coran',
          audioUrl:
              'https://server10.mp3quran.net/$reciterShortName/$paddedId.mp3',
          duration: Duration.zero,
        );
      }

      final response = await http
          .get(Uri.parse('$baseUrl/surahs/$id'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AudioTrack.fromJson(data, categoryName);
      } else {
        throw Exception('API status error');
      }
    } catch (e) {
      final paddedId = id.padLeft(3, '0');
      return AudioTrack(
        id: id,
        title: categoryName,
        category: 'Coran',
        audioUrl: 'https://server10.mp3quran.net/minsh/$paddedId.mp3',
        duration: Duration.zero,
      );
    }
  }

  AudioTrack getTrackFromSurah(
    Map<String, dynamic> surah, {
    String? reciterShortName,
  }) {
    final id = surah['number'].toString();
    final name = surah['name_en'] ?? 'Unknown';
    final paddedId = id.padLeft(3, '0');
    final reciter = reciterShortName ?? 'minsh';
    return AudioTrack(
      id: id,
      title: name,
      category: 'Coran',
      audioUrl: 'https://server10.mp3quran.net/$reciter/$paddedId.mp3',
      duration: Duration.zero,
    );
  }
}
