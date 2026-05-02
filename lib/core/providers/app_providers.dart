import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/biometric_service.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import 'package:audio_service/audio_service.dart';
import '../services/audio_handler.dart';

final authServiceProvider = Provider((ref) => AuthService());
final firestoreServiceProvider = Provider((ref) => FirestoreService());
final biometricServiceProvider = Provider((ref) => BiometricService());
final apiServiceProvider = Provider((ref) => ApiService());
final localStorageServiceProvider = Provider((ref) => LocalStorageService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  return ref.watch(firestoreServiceProvider).getUserProfile();
});

final favoritesProvider = StreamProvider<List>((ref) {
  return ref.watch(firestoreServiceProvider).getFavorites();
});

final audioHandlerProvider = Provider<MyAudioHandler>((ref) {
  throw UnimplementedError();
});

final listeningStatsProvider = FutureProvider<Map<String, int>>((ref) {
  return ref.watch(localStorageServiceProvider).getMonthlyStats();
});

final monthlyGoalProvider = FutureProvider<int>((ref) {
  return ref.watch(localStorageServiceProvider).getMonthlyGoal();
});

final topTracksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(localStorageServiceProvider).getTopTracks();
});
