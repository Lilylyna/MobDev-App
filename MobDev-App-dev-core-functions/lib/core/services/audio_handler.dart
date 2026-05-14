import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_service.dart';
import 'local_storage_service.dart';

class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final LocalStorageService _storage;

  Stream<Duration> get positionStream => _player.positionStream;

  MyAudioHandler(this._storage) {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Listen to duration changes to update MediaItem
    _player.durationStream.listen((duration) {
      final item = mediaItem.value;
      if (item != null && duration != null) {
        mediaItem.add(item.copyWith(duration: duration));
      }
    });

    // Handle end of track (looping or next)
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        if (_player.loopMode == LoopMode.off) {
          skipToNext();
        }
      }
    });

    // Recording listening time every minute
    Stream.periodic(const Duration(minutes: 1)).listen((_) {
      if (_player.playing) {
        _storage.addMinutesForToday(1);
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          AuthService().updateListeningTime(uid, 1);
        }
      }
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    final currentIndex = queue.value.indexWhere(
      (t) => t.id == mediaItem.value?.id,
    );
    if (currentIndex != -1 && currentIndex < queue.value.length - 1) {
      playMediaItem(queue.value[currentIndex + 1]);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    final currentIndex = queue.value.indexWhere(
      (t) => t.id == mediaItem.value?.id,
    );
    if (currentIndex > 0) {
      playMediaItem(queue.value[currentIndex - 1]);
    } else {
      _player.seek(Duration.zero);
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> items) async {
    queue.add(items);
  }

  @override
  Future<void> playMediaItem(MediaItem item) async {
    mediaItem.add(item);
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(item.id)));
      _player.play();
      final surahNumber = item.extras?['trackId'] as String?;
      _storage.trackListened(surahNumber ?? item.id, item.title);
    } catch (e) {
      print("Error playing media: $e");
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;
      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToNext,
        MediaAction.skipToPrevious,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      repeatMode: const {
        LoopMode.off: AudioServiceRepeatMode.none,
        LoopMode.one: AudioServiceRepeatMode.one,
        LoopMode.all: AudioServiceRepeatMode.all,
      }[_player.loopMode]!,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}
