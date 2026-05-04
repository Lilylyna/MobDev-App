import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/models/audio_track.dart';
import 'package:audio_service/audio_service.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  final FutureProvider<List<Map<String, dynamic>>> categoriesProvider = FutureProvider((ref) {
    return ref.read(apiServiceProvider).getCategories();
  });

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lecteur Audio')),
      body: Column(
        children: [
          Expanded(
            child: categories.when(
              data: (list) => ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final cat = list[index];
                  return ExpansionTile(
                    title: Text(cat['name_en'] ?? 'Catégorie'),
                    subtitle: Text('${cat['ayat_count']} versets'),
                    leading: const Icon(Icons.folder),
                    children: [
                      _buildTrackList(cat['id'], cat['name_en']),
                    ],
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Erreur: $e')),
            ),
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }

  Widget _buildTrackList(String catId, String catName) {
    return FutureBuilder<AudioTrack>(
      future: ref.read(apiServiceProvider).getTrackDetail(catId, catName),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (snapshot.hasError) return const ListTile(title: Text('Erreur chargement'));
        
        final track = snapshot.data!;
        return ListTile(
          onTap: () {
            ref.read(audioHandlerProvider).playMediaItem(
              MediaItem(
                id: track.audioUrl,
                album: track.category,
                title: track.title,
                duration: track.duration,
              ),
            );
            ref.read(localStorageServiceProvider).trackListened(track.id, track.title);
          },
          title: Text(track.title),
          trailing: IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () => ref.read(firestoreServiceProvider).addFavorite(track),
          ),
        );
      },
    );
  }
}

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    
    return StreamBuilder<MediaItem?>(
      stream: handler.mediaItem,
      builder: (context, snapshot) {
        final item = snapshot.data;
        if (item == null) return const SizedBox.shrink();

        return StreamBuilder<PlaybackState>(
          stream: handler.playbackState,
          builder: (context, stateSnapshot) {
            final state = stateSnapshot.data;
            final playing = state?.playing ?? false;
            final repeatMode = state?.repeatMode ?? AudioServiceRepeatMode.none;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                border: Border(top: BorderSide(color: Colors.white10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(item.album ?? '', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (playing) {
                        handler.pause();
                      } else {
                        handler.play();
                      }
                    }, 
                    icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: const Color(0xFF0C7C5C))
                  ),
                  IconButton(
                    onPressed: () {
                      final nextMode = repeatMode == AudioServiceRepeatMode.none 
                        ? AudioServiceRepeatMode.one 
                        : repeatMode == AudioServiceRepeatMode.one 
                          ? AudioServiceRepeatMode.all 
                          : AudioServiceRepeatMode.none;
                      handler.setRepeatMode(nextMode);
                    }, 
                    icon: Icon(
                      repeatMode == AudioServiceRepeatMode.one 
                        ? Icons.repeat_one 
                        : Icons.repeat, 
                      color: repeatMode == AudioServiceRepeatMode.none ? Colors.white54 : const Color(0xFFD4AF37)
                    )
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }
}
