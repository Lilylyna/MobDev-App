import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();

  factory LocalStorageService() {
    return _instance;
  }

  LocalStorageService._internal();

  static const String keyGoal = 'monthly_goal_hours';
  static const String keyTopTracks = 'top_tracks';
  static const String keyHistory = 'listening_history_list';

  final _historyChangeController = StreamController<void>.broadcast();
  Stream<void> get historyChanges => _historyChangeController.stream;

  String _getKey(String baseKey, String? uid) {
    final activeUid = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (activeUid == null || activeUid.isEmpty) {
      return baseKey;
    }
    return '${activeUid}_$baseKey';
  }

  Future<void> setMonthlyGoal(int hours, {String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_getKey(keyGoal, uid), hours);
  }

  Future<void> setThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_theme', isDark);
  }

  Future<bool> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to dark theme for this app
    return prefs.getBool('is_dark_theme') ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<int> getMonthlyGoal({String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_getKey(keyGoal, uid)) ?? 20;
  }

  Future<void> addMinutesForToday(int minutes, {String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final keyToday = 'listening_history_$today';
    final prefixedKey = _getKey(keyToday, uid);
    final current = prefs.getInt(prefixedKey) ?? 0;
    await prefs.setInt(prefixedKey, current + minutes);
  }

  Future<int> getMinutesForDate(DateTime date, {String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final keyDate = 'listening_history_$dateStr';
    return prefs.getInt(_getKey(keyDate, uid)) ?? 0;
  }

  Future<Map<String, int>> getMonthlyStats({String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final Map<String, int> stats = {};

    // Get days of the current month
    for (int i = 1; i <= now.day; i++) {
      final date = DateTime(now.year, now.month, i);
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final keyDate = 'listening_history_$dateStr';
      stats[dateStr] = prefs.getInt(_getKey(keyDate, uid)) ?? 0;
    }
    return stats;
  }

  Future<void> trackListened(String trackId, String title, {String? uid}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Top Tracks (Counts)
    final topTracksKey = _getKey(keyTopTracks, uid);
    final topTracksStr = prefs.getString(topTracksKey) ?? '{}';
    final Map<String, dynamic> topTracks = json.decode(topTracksStr);
    final currentCount = topTracks[trackId]?['count'] ?? 0;
    topTracks[trackId] = {'title': title, 'count': currentCount + 1};
    await prefs.setString(topTracksKey, json.encode(topTracks));

    // 2. History (Last 10 tracks)
    final historyKey = _getKey(keyHistory, uid);
    final historyStr = prefs.getString(historyKey) ?? '[]';
    final List<dynamic> history = json.decode(historyStr);

    // Remove if already exists to move to top
    history.removeWhere((item) => item['id'] == trackId);
    history.insert(0, {
      'id': trackId,
      'title': title,
      'category': 'Coran', // Default for now
      'audioUrl':
          'https://server10.mp3quran.net/minsh/${trackId.padLeft(3, '0')}.mp3',
      'timestamp': DateTime.now().toIso8601String(),
    });

    if (history.length > 5) history.removeLast();
    await prefs.setString(historyKey, json.encode(history));
    _historyChangeController.add(null);
  }

  Future<List<Map<String, dynamic>>> getHistory({String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    final historyKey = _getKey(keyHistory, uid);
    final historyStr = prefs.getString(historyKey) ?? '[]';
    final list = (json.decode(historyStr) as List).cast<Map<String, dynamic>>();
    return list.take(5).toList();
  }

  Future<List<Map<String, dynamic>>> getTopTracks({String? uid}) async {
    final prefs = await SharedPreferences.getInstance();
    final topTracksKey = _getKey(keyTopTracks, uid);
    final topTracksStr = prefs.getString(topTracksKey) ?? '{}';
    final Map<String, dynamic> topTracks = json.decode(topTracksStr);

    final list = topTracks.entries
        .map(
          (e) => {
            'id': e.key,
            'title': e.value['title'],
            'count': e.value['count'],
          },
        )
        .toList();

    list.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    return list.take(5).toList();
  }
}
