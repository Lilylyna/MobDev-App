import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_theme.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  Future<void> _authenticate() async {
    try {
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      final bool isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        _showBypassDialog('Biometrics not supported on this device.');
        return;
      }

      final bool authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to unlock LockTune',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allows PIN/Pattern fallback
        ),
      );

      if (authenticated) {
        _handleNavigation();
      }
    } catch (e) {
      debugPrint("Authentication error: $e");
      _showBypassDialog('An error occurred during authentication.');
    }
  }

  void _showBypassDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Security Required'),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Retry'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _handleNavigation();
            },
            child: const Text(
              'BYPASS (DEBUG)',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
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
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF161616), Colors.black],
            center: Alignment.center,
            radius: 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.fingerprint,
              size: 100,
              color: AppTheme.accentColor,
            ),
            const SizedBox(height: 40),
            const Text(
              "LOCKTUNE",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                letterSpacing: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "PREMIUM SECURITY SYSTEM",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 60),
            const CircularProgressIndicator(
              color: AppTheme.accentColor,
              strokeWidth: 2,
            ),
            const SizedBox(height: 40),
            TextButton.icon(
              onPressed: _authenticate,
              icon: const Icon(Icons.refresh, color: AppTheme.accentColor),
              label: const Text(
                "Retry Authentication",
                style: TextStyle(color: AppTheme.accentColor),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _handleNavigation,
              child: Text(
                "DEBUG BYPASS",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.2),
                  fontSize: 10,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
