import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/biometric_service.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/audio_handler.dart';
import '../models/audio_track.dart';

// 1. Services de base
final authServiceProvider = Provider((ref) => AuthService());
final firestoreServiceProvider = Provider((ref) => FirestoreService());
final biometricServiceProvider = Provider((ref) => BiometricService());
final apiServiceProvider = Provider((ref) => ApiService());
final localStorageServiceProvider = Provider((ref) => LocalStorageService());

// 2. État de l'authentification (Liaison Auth)
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Gestion du thème
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.dark;
  }

  Future<void> _loadTheme() async {
    final storageService = ref.read(localStorageServiceProvider);
    final isDark = await storageService.getThemeMode();
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    final storageService = ref.read(localStorageServiceProvider);
    final isDark = state != ThemeMode.dark;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    storageService.setThemeMode(isDark);
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});

// Notifications toggle
class NotificationsNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadState();
    return true; // default
  }

  Future<void> _loadState() async {
    final storage = ref.read(localStorageServiceProvider);
    state = await storage.getNotificationsEnabled();
  }

  void toggleNotifications() {
    state = !state;
    ref.read(localStorageServiceProvider).setNotificationsEnabled(state);
  }
}

final notificationsProvider = NotifierProvider<NotificationsNotifier, bool>(() {
  return NotificationsNotifier();
});

// 3. Liaison avec le profil utilisateur (Nom en gras, objectif 20h)
// Changé en StreamProvider pour une mise à jour en temps réel
final userProfileProvider = StreamProvider<DocumentSnapshot?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .snapshots();
});

// 4. Liaison avec les favoris synchronisés en ligne (Subcollection)
final favoritesProvider = StreamProvider<List<AudioTrack>>((ref) {
  // Watch authStateProvider so that it resets and updates when the user logs in/out/switches
  ref.watch(authStateProvider);
  return ref.watch(firestoreServiceProvider).getFavorites();
});

// 5. Liaison avec les statistiques (Pour l'histogramme mensuel)
final listeningStatsProvider = StreamProvider<QuerySnapshot>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return const Stream.empty();

  return FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('listening_stats')
      .orderBy('date', descending: false)
      .snapshots();
});

// 6. Provider pour l'Audio (Overridé dans le main.dart)
final audioHandlerProvider = Provider<MyAudioHandler>((ref) {
  throw UnimplementedError();
});

// 7. Liaison avec l'objectif mensuel spécifique (Sauvegardé LOCALEMENT)
final monthlyGoalProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authStateProvider).value;
  return await ref.watch(localStorageServiceProvider).getMonthlyGoal(uid: user?.uid);
});

final topTracksProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final user = ref.watch(authStateProvider).value;
  final storage = ref.watch(localStorageServiceProvider);

  // Yield the initial value
  yield await storage.getTopTracks(uid: user?.uid);

  // Yield updated values when local history changes
  await for (final _ in storage.historyChanges) {
    yield await storage.getTopTracks(uid: user?.uid);
  }
});

final historyProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final user = ref.watch(authStateProvider).value;
  final storage = ref.watch(localStorageServiceProvider);

  // Yield the initial value
  yield await storage.getHistory(uid: user?.uid);

  // Yield updated values when local history changes
  await for (final _ in storage.historyChanges) {
    yield await storage.getHistory(uid: user?.uid);
  }
});

final surahsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.watch(apiServiceProvider).getSurahs();
});

final recitersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await ref.watch(apiServiceProvider).getReciters();
});