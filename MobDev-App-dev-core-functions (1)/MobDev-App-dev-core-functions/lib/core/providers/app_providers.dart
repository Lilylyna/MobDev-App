import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/biometric_service.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';
import '../services/audio_handler.dart';

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

// 4. Liaison avec les favoris synchronisés en ligne
final favoritesProvider = StreamProvider<List<dynamic>>((ref) {
  final userProfile = ref.watch(userProfileProvider).value;
  if (userProfile == null || !userProfile.exists) return Stream.value([]);

  final data = userProfile.data() as Map<String, dynamic>;
  return Stream.value(data['favorites'] ?? []);
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

// 7. Liaison avec l'objectif mensuel spécifique (20h par défaut)
final monthlyGoalProvider = Provider<int>((ref) {
  final userProfile = ref.watch(userProfileProvider).value;
  if (userProfile == null || !userProfile.exists) return 20; // Valeur imposée

  final data = userProfile.data() as Map<String, dynamic>;
  return data['monthlyGoal'] ?? 20;
});
// À ajouter tout en bas de app_providers.dart
final topTracksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  // Liaison temporaire avec le stockage local en attendant la logique Firestore
  return await ref.watch(localStorageServiceProvider).getTopTracks();
});