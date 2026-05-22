import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:audio_service/audio_service.dart';

import 'core/theme/app_theme.dart';
import 'core/services/audio_handler.dart';
import 'core/services/local_storage_service.dart';
import 'core/providers/app_providers.dart';
import 'presentation/pages/splash_screen.dart';

MyAudioHandler? _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyDw4mOWcQcmiQ1lzj4NlR8aYkcD8eNriZk",
        appId: "1:196028770043:android:f52b4ace4b570268d9b25e",
        messagingSenderId: "196028770043",
        projectId: "secu-mobile",
        storageBucket: "secu-mobile.firebasestorage.app",
      ),
    );

    final storage = LocalStorageService();
    _audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(storage),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.locktune.app.audio',
        androidNotificationChannelName: 'LockTune Audio',
        androidNotificationOngoing: true,
      ),
    );
  } catch (e) {
    debugPrint("INITIALIZATION ERROR : $e");
  }

  runApp(
    ProviderScope(
      overrides: [
        if (_audioHandler != null)
          audioHandlerProvider.overrideWithValue(_audioHandler!),
      ],
      child: const LockTuneApp(),
    ),
  );
}

class LockTuneApp extends ConsumerWidget {
  const LockTuneApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'LockTune',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeProvider),
      debugShowCheckedModeBanner: false,
      home: _audioHandler == null
          ? const Scaffold(body: Center(child: Text("Configuration Error")))
          : const SplashScreen(),
    );
  }
}