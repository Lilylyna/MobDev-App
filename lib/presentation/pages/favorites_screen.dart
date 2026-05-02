import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import 'package:audio_service/audio_service.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes Favoris')),
      body: favorites.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aucun favori sauvegardé.'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final track = list[index];
              return ListTile(
                onTap: () {
                  ref.read(audioHandlerProvider).playMediaItem(
                    MediaItem(
                      id: track.audioUrl,
                      album: track.category,
                      title: track.title,
                    ),
                  );
                },
                leading: const Icon(Icons.music_note, color: Color(0xFFD4AF37)),
                title: Text(track.title),
                subtitle: Text(track.category),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () async {
                    final bioService = ref.read(biometricServiceProvider);
                    final success = await bioService.authenticate(
                      reason: 'Veuillez confirmer votre identité pour supprimer ce favori.',
                    );
                    if (success) {
                      await ref.read(firestoreServiceProvider).removeFavorite(track.id);
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      ),
    );
  }
}
