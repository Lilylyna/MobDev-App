package com.secuaudio.app.secured_audio_player

import io.flutter.embedding.android.FlutterFragmentActivity
import com.ryanheise.audioservice.AudioServiceFragmentActivity

class MainActivity: AudioServiceFragmentActivity() {
    // Cette classe permet de supporter local_auth (via FragmentActivity)
    // et audio_service simultanément.
}