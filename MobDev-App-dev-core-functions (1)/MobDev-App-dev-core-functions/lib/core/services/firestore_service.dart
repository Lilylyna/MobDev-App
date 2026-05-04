
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/audio_track.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String get uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> addFavorite(AudioTrack track) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).collection('favorites').doc(track.id).set({
      'trackId': track.id,
      'title': track.title,
      'category': track.category,
      'audioUrl': track.audioUrl,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeFavorite(String trackId) async {
    if (uid.isEmpty) return;
    await _firestore.collection('users').doc(uid).collection('favorites').doc(trackId).delete();
  }

  Stream<List<AudioTrack>> getFavorites() {
    if (uid.isEmpty) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .orderBy('addedAt', descending: true)
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

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (uid.isEmpty) return null;
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data();
  }
}
