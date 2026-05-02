import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/audio_track.dart';

class ApiService {
  static const String baseUrl = 'https://quran.yousefheiba.com/api';

  Future<List<Map<String, dynamic>>> getCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/surahs'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Erreur lors du chargement des catégories');
    }
  }

  Future<AudioTrack> getTrackDetail(String id, String categoryName) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/surahs/$id'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return AudioTrack.fromJson(data, categoryName);
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
    throw Exception('Erreur lors du chargement du morceau');
  }
}
