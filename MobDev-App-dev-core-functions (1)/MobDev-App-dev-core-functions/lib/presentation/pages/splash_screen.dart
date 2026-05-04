import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final AudioPlayer _sfxPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    // On attend la fin du premier build pour lancer l'authentification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  @override
  void dispose() {
    _sfxPlayer.dispose();
    super.dispose();
  }

  Future<void> _playSuccessSound() async {
    try {
      // Assure-toi que le fichier existe dans assets/sounds/success.mp3
      await _sfxPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      debugPrint("Erreur audio : $e");
    }
  }

  Future<void> _authenticate() async {
    try {
      // 1. Vérification de la compatibilité du matériel
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      final bool isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics && !isDeviceSupported) {
        debugPrint("Biométrie non supportée sur cet appareil.");
        _handleNavigation();
        return;
      }

      // 2. Authentification avec la syntaxe universelle
      // Si 'options' ou 'AuthenticationOptions' ne sont pas reconnus par ton IDE,
      // c'est cette ligne que tu dois utiliser pour compiler sans erreur :
      final bool authenticated = await auth.authenticate(
        localizedReason: 'Scannez votre empreinte pour déverrouiller SecuAudio',
      );

      if (authenticated) {
        await _playSuccessSound();
        // Pause pour l'effet sonore
        await Future.delayed(const Duration(milliseconds: 600));
        _handleNavigation();
      } else {
        // Optionnel : Gérer l'échec ou laisser l'utilisateur réessayer
        debugPrint("Authentification annulée ou échouée.");
      }
    } catch (e) {
      debugPrint("Erreur lors de l'authentification : $e");
      _handleNavigation();
    }
  }

  void _handleNavigation() {
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Design inspiré par ton projet de sécurité à l'USTHB
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [Colors.grey.shade900, Colors.black],
            center: Alignment.center,
            radius: 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Empreinte Doré
            const Icon(
              Icons.fingerprint,
              size: 100,
              color: Color(0xFFD4AF37), // Couleur Or
            ),
            const SizedBox(height: 40),
            const Text(
              "SECUAUDIO",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "SYSTÈME SÉCURISÉ",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 50),
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                color: Color(0xFFD4AF37),
                strokeWidth: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}