
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/audio_track.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> addFavorite(AudioTrack track) async {
    if (uid.isEmpty) return;
    try {
      await _db.collection('users').doc(uid).collection('favorites').doc(track.id).set({
        'trackId': track.id,
        'title': track.title,
        'category': track.category,
        'audioUrl': track.audioUrl,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout aux favoris: $e');
    }
  }

  Future<void> removeFavorite(String trackId) async {
    if (uid.isEmpty) return;
    try {
      await _db.collection('users').doc(uid).collection('favorites').doc(trackId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression des favoris: $e');
    }
  }

  Stream<List<AudioTrack>> getFavorites() {
    if (uid.isEmpty) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('favorites')
        // Suppression de l'orderBy temporairement pour éviter les erreurs d'index API
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return AudioTrack(
          id: data['trackId'],
          title: data['title'],
          category: data['category'],
          audioUrl: data['audioUrl'],
          duration: Duration.zero,
        );
      }).toList();
    });
  }

  Future<bool> isFavorite(String trackId) async {
    if (uid.isEmpty) return false;
    final doc = await _db.collection('users').doc(uid).collection('favorites').doc(trackId).get();
    return doc.exists;
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (uid.isEmpty) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }
}
