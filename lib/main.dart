import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:audio_service/audio_service.dart';
import 'core/theme/app_theme.dart';
import 'core/services/audio_handler.dart';
import 'core/services/local_storage_service.dart';
import 'core/providers/app_providers.dart';
import 'presentation/pages/splash_screen.dart';
import 'presentation/pages/login_screen.dart';
import 'presentation/pages/home_screen.dart';

late MyAudioHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp();
  
  final storage = LocalStorageService();
  _audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(storage),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.secuaudio.app.audio',
      androidNotificationChannelName: 'Audio Playback',
      androidNotificationOngoing: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(_audioHandler),
      ],
      child: const SecuAudioApp(),
    ),
  );
}

class SecuAudioApp extends ConsumerWidget {
  const SecuAudioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'SecuAudio',
      theme: AppTheme.darkTheme,
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const SplashScreen(nextPage: LoginScreen());
          } else {
            return const SplashScreen(nextPage: HomeScreen());
          }
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
