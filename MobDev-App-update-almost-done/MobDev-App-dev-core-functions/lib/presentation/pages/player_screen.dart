import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/audio_track.dart';
import 'package:audio_service/audio_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/audio_handler.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  final AudioTrack? track;
  const PlayerScreen({super.key, this.track});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  int _rewindClickCount = 0;
  DateTime? _lastRewindClick;

  @override
  void initState() {
    super.initState();
    if (widget.track != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final handler = ref.read(audioHandlerProvider);
        if (handler.mediaItem.value?.id != widget.track!.audioUrl) {
          handler.playMediaItem(widget.track!.toMediaItem());
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.watch(audioHandlerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'LOCKTUNE',
          style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<MediaItem?>(
        stream: handler.mediaItem,
        builder: (context, snapshot) {
          final item = snapshot.data;
          if (item == null) {
            return const Center(child: Text('No track playing'));
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Album Cover
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                          ? AppTheme.primaryColor.withOpacity(0.2)
                          : Colors.black.withOpacity(0.05),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                    border: isDark ? null : Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    size: 100,
                    color: AppTheme.accentColor,
                  ),
                ),
                const SizedBox(height: 48),

                // Surah Name (Arabic)
                Text(
                  item.extras?['name_ar'] ?? item.title,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.headlineMedium?.color,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  item.title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 48),

                // Progress Bar
                _buildProgressBar(handler),
                const SizedBox(height: 40),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLoopButton(handler),
                    _buildPlaybackControls(handler),
                    _buildFavoriteButton(handler, item),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressBar(MyAudioHandler handler) {
    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      builder: (context, mediaSnapshot) {
        final duration = mediaSnapshot.data?.duration ?? Duration.zero;

        return StreamBuilder<Duration>(
          stream: handler.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;

            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppTheme.accentColor,
                    inactiveTrackColor: Theme.of(context).dividerColor,
                    thumbColor: Theme.of(context).colorScheme.onSurface,
                    overlayColor: AppTheme.accentColor.withOpacity(0.2),
                    trackHeight: 4,
                  ),
                  child: Slider(
                    max: duration.inMilliseconds.toDouble() > 0
                        ? duration.inMilliseconds.toDouble()
                        : 1.0,
                    value: position.inMilliseconds.toDouble().clamp(
                      0.0,
                      duration.inMilliseconds.toDouble() > 0
                          ? duration.inMilliseconds.toDouble()
                          : 1.0,
                    ),
                    onChanged: (val) =>
                        handler.seek(Duration(milliseconds: val.toInt())),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        _formatDuration(duration),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPlaybackControls(MyAudioHandler handler) {
    return StreamBuilder<PlaybackState>(
      stream: handler.playbackState,
      builder: (context, snapshot) {
        final playing = snapshot.data?.playing ?? false;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rewind / Previous
            IconButton(
              iconSize: 40,
              icon: const Icon(Icons.fast_rewind),
              onPressed: () {
                final now = DateTime.now();
                if (_lastRewindClick != null &&
                    now.difference(_lastRewindClick!) <
                        const Duration(seconds: 1)) {
                  _rewindClickCount++;
                } else {
                  _rewindClickCount = 1;
                }
                _lastRewindClick = now;

                if (_rewindClickCount >= 2) {
                  handler.skipToPrevious();
                  _rewindClickCount = 0;
                } else {
                  handler.seek(
                    handler.playbackState.value.position -
                        const Duration(seconds: 10),
                  );
                }
              },
            ),
            const SizedBox(width: 16),
            // Play / Pause
            Container(
              height: 80,
              width: 80,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                iconSize: 48,
                icon: Icon(
                  playing ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () => playing ? handler.pause() : handler.play(),
              ),
            ),
            const SizedBox(width: 16),
            // Skip
            IconButton(
              iconSize: 40,
              icon: const Icon(Icons.fast_forward),
              onPressed: () => handler.skipToNext(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoopButton(MyAudioHandler handler) {
    return StreamBuilder<PlaybackState>(
      stream: handler.playbackState,
      builder: (context, snapshot) {
        final repeatMode =
            snapshot.data?.repeatMode ?? AudioServiceRepeatMode.none;
        final isLooping = repeatMode == AudioServiceRepeatMode.one;

        return IconButton(
          icon: Icon(
            isLooping ? Icons.repeat_one : Icons.repeat,
            color: isLooping ? AppTheme.accentColor : Theme.of(context).iconTheme.color?.withOpacity(0.5),
          ),
          onPressed: () {
            handler.setRepeatMode(
              isLooping
                  ? AudioServiceRepeatMode.none
                  : AudioServiceRepeatMode.one,
            );
          },
        );
      },
    );
  }

  Widget _buildFavoriteButton(MyAudioHandler handler, MediaItem item) {
    final favs = ref.watch(favoritesProvider);
    final trackId = item.extras?['trackId'] ?? '';

    return favs.when(
      data: (list) {
        final isFav = list.any((t) => t.id == trackId);
        return IconButton(
          icon: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            color: isFav ? Colors.redAccent : Theme.of(context).iconTheme.color,
          ),
          onPressed: () async {
            final fs = ref.read(firestoreServiceProvider);
            if (isFav) {
              // Confirmation biométrique requise pour retirer des favoris
              final bioService = ref.read(biometricServiceProvider);
              final success = await bioService.authenticate(
                reason: 'Confirmation biométrique requise pour retirer des favoris',
              );
              if (success) {
                fs.removeFavorite(trackId);
              }
            } else {
              // Pas de biométrie pour ajouter
              final track = AudioTrack(
                id: trackId,
                title: item.title,
                category: item.album ?? 'Coran',
                audioUrl: item.id,
                nameAr: item.extras?['name_ar'],
                duration: item.duration ?? Duration.zero,
              );
              fs.addFavorite(track);
            }
          },
        );
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, _) => Icon(Icons.favorite_border, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
