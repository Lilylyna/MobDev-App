import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class LocalStorageService {
  static const String keyGoal = 'monthly_goal_hours';
  static const String keyTopTracks = 'top_tracks';

  Future<void> setMonthlyGoal(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyGoal, hours);
  }

  Future<int> getMonthlyGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(keyGoal) ?? 20;
  }

  Future<void> addMinutesForToday(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final keyToday = 'listening_history_$today';
    final current = prefs.getInt(keyToday) ?? 0;
    await prefs.setInt(keyToday, current + minutes);
  }

  Future<int> getMinutesForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    return prefs.getInt('listening_history_$dateStr') ?? 0;
  }

  Future<Map<String, int>> getMonthlyStats() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final Map<String, int> stats = {};
    
    // Get days of the current month
    for (int i = 1; i <= now.day; i++) {
        final date = DateTime(now.year, now.month, i);
        final dateStr = DateFormat('yyyy-MM-dd').format(date);
        stats[dateStr] = prefs.getInt('listening_history_$dateStr') ?? 0;
    }
    return stats;
  }

  Future<void> trackListened(String trackId, String title) async {
    final prefs = await SharedPreferences.getInstance();
    final topTracksStr = prefs.getString(keyTopTracks) ?? '{}';
    final Map<String, dynamic> topTracks = json.decode(topTracksStr);
    
    final currentCount = topTracks[trackId]?['count'] ?? 0;
    topTracks[trackId] = {
      'title': title,
      'count': currentCount + 1,
    };
    
    await prefs.setString(keyTopTracks, json.encode(topTracks));
  }

  Future<List<Map<String, dynamic>>> getTopTracks() async {
    final prefs = await SharedPreferences.getInstance();
    final topTracksStr = prefs.getString(keyTopTracks) ?? '{}';
    final Map<String, dynamic> topTracks = json.decode(topTracksStr);
    
    final list = topTracks.entries.map((e) => {
      'id': e.key,
      'title': e.value['title'],
      'count': e.value['count'],
    }).toList();
    
    list.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return list.take(5).toList();
  }
}
