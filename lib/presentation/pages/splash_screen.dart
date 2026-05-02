import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final Widget nextPage;
  const SplashScreen({super.key, required this.nextPage});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final prefs = await SharedPreferences.getInstance();
    final hasCompletedSetup = prefs.getBool('hasCompletedBiometricSetup') ?? false;

    if (hasCompletedSetup) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => widget.nextPage),
        );
      }
      return;
    }

    final bioService = ref.read(biometricServiceProvider);
    
    final available = await bioService.isBiometricAvailable();
    
    if (!available) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Sécurité requise'),
            content: const Text('Cette application nécessite la configuration d\'une empreinte digitale ou de FaceID dans les paramètres de votre système.'),
            actions: [
              TextButton(
                onPressed: () => bioService.openBiometricSettings(),
                child: const Text('Ouvrir les Paramètres'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final success = await bioService.authenticate(
      reason: 'Veuillez vous authentifier pour accéder à vos audios sécurisés.',
    );

    if (success) {
      await prefs.setBool('hasCompletedBiometricSetup', true);
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => widget.nextPage),
        );
      }
    } else {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0C7C5C), Color(0xFF121212)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person, size: 80, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'SecuAudio',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: _checkBiometrics,
                icon: const Icon(Icons.fingerprint),
                label: const Text('S\'authentifier'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
