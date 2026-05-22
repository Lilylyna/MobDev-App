import 'package:local_auth/local_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:permission_handler/permission_handler.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<bool> isBiometricAvailable() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool canAuthenticate =
        canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
    return canAuthenticate;
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
      );

      if (didAuthenticate) {
        await _playSuccessSound();
      }
      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  Future<void> _playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
    }
  }

  Future<void> openBiometricSettings() async {
    await openAppSettings();
  }
}
