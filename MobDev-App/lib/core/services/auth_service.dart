import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // validation email
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  // validation age 13+
  bool isAtLeast13(DateTime birthDate) {
    final DateTime now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age >= 13;
  }

  Future<UserCredential?> signup({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required DateTime birthDate,
  }) async {
    if (!isAtLeast13(birthDate)) {
      throw Exception('Vous devez avoir au moins 13 ans pour vous inscrire.');
    }

    try {
      final UserCredential credential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (credential.user != null) {
        final String uid = credential.user!.uid;

        // Liaison profil
        await _db.collection('users').doc(uid).set({
          'firstName': firstName,
          'lastName': lastName,
          'dob': birthDate.toIso8601String(),
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'monthlyGoalHours': 20,
          'favorites': [],
          'listenTimeMinutes': 0,
        });

        // Liaison Stats
        final DateTime now = DateTime.now();
        String today =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        await _db
            .collection('users')
            .doc(uid)
            .collection('listening_stats')
            .doc(today)
            .set({'minutes': 0, 'date': FieldValue.serverTimestamp()});
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e.code));
    }
  }

  /// Met à jour le temps d'écoute (en minutes, peut être fractionnaire)
  Future<void> updateListeningTime(String uid, double minutesAdded) async {
    String today = DateTime.now().toString().split(' ')[0];

    // Met à jour le total global
    await _db.collection('users').doc(uid).update({
      'listenTimeMinutes': FieldValue.increment(minutesAdded),
    });

    // Met à jour le document du jour pour le graphique
    await _db
        .collection('users')
        .doc(uid)
        .collection('listening_stats')
        .doc(today)
        .set({
          'minutes': FieldValue.increment(minutesAdded),
          'date': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e.code));
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthError(e.code));
    }
  }

  Future<void> signOut() async => await _auth.signOut();

  String _handleAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Aucun utilisateur trouvé avec cet email.';
      case 'wrong-password':
        return 'Mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Cet email est déjà associé à un compte.';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères.';
      case 'invalid-email':
        return 'L\'adresse email n\'est pas valide.';
      default:
        return 'Une erreur d\'authentification est survenue : $code';
    }
  }
}
