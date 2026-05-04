import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/audio_track.dart';

class ApiService {
  static const String baseUrl = 'https://quran.yousefheiba.com/api';

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/surahs'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des catégories: $e');
    }
  }

  Future<AudioTrack> getTrackDetail(String id, String categoryName) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/surahs/$id'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AudioTrack.fromJson(data, categoryName);
      } else {
        // Si l'API répond mais avec une erreur, on force le passage au mode fallback
        throw Exception('API status error');
      }
    } catch (e) {
      // MODE FALLBACK : Si l'API échoue (réseau, 404, ou erreur serveur),
      // on génère manuellement l'URL du fichier audio pour que l'app fonctionne quand même.
      final paddedId = id.padLeft(3, '0');

      return AudioTrack(
        id: id,
        title: categoryName,
        category: 'Coran',
        // Utilisation du serveur MP3Quran en secours
        audioUrl: 'https://server10.mp3quran.net/minsh/$paddedId.mp3',
        duration: Duration.zero,
      );
    }
  }
}