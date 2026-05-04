import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:audio_service/audio_service.dart';

import 'core/theme/app_theme.dart';
import 'core/services/audio_handler.dart';
import 'core/services/local_storage_service.dart';
import 'core/providers/app_providers.dart';
import 'presentation/pages/splash_screen.dart';

// 1. SUPPRESSION DU 'late' : On utilise un nullable pour éviter le crash au démarrage
MyAudioHandler? _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 2. Initialisation Firebase
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDw4mOWcQcmiQ1lzj4NlR8aYkcD8eNriZk",
        appId: "1:196028770043:android:f52b4ace4b570268d9b25e",
        messagingSenderId: "196028770043",
        projectId: "secu-mobile",
        storageBucket: "secu-mobile.firebasestorage.app",
      ),
    );


    // 3. Initialisation AudioService
    final storage = LocalStorageService();
    _audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(storage),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.secuaudio.app.audio',
        androidNotificationChannelName: 'Audio Playback',
        androidNotificationOngoing: true,
      ),
    );
  } catch (e) {
    // Si ça échoue, on log l'erreur mais on ne laisse pas 'late' faire planter l'app
    debugPrint("ERREUR INITIALISATION : $e");
  }

  runApp(
    ProviderScope(
      overrides: [
        // 4. Vérification de sécurité avant l'override
        if (_audioHandler != null)
          audioHandlerProvider.overrideWithValue(_audioHandler!),
      ],
      child: const SecuAudioApp(),
    ),
  );
}

class SecuAudioApp extends ConsumerWidget {
  const SecuAudioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'SecuAudio',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      // Si l'audio n'est pas prêt, on affiche un message d'erreur propre au lieu d'un écran noir
      home: _audioHandler == null
          ? const Scaffold(body: Center(child: Text("Erreur de configuration Audio/Firebase")))
          : const SplashScreen(),
    );
  }
}