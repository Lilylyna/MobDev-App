import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import 'package:audio_service/audio_service.dart';
import 'player_screen.dart';

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
                  final handler = ref.read(audioHandlerProvider);
                  handler.addQueueItems(
                    list.map((t) => t.toMediaItem()).toList(),
                  );
                  handler.playMediaItem(track.toMediaItem());
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(track: track),
                    ),
                  );
                },
                leading: const Icon(Icons.music_note, color: Color(0xFFD4AF37)),
                title: Text(track.title),
                subtitle: Text(track.category),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () async {
                    // Option de bypass rapide pour le test
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF1E1E1E),
                        title: const Text(
                          'Confirmation',
                          style: TextStyle(color: Colors.white),
                        ),
                        content: const Text(
                          'Voulez-vous vraiment supprimer ce favori ?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text(
                              'ANNULER',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text(
                              'BYPASS BIO (DEBUG)',
                              style: TextStyle(color: Color(0xFFD4AF37)),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37),
                            ),
                            onPressed: () async {
                              final bioService = ref.read(
                                biometricServiceProvider,
                              );
                              final success = await bioService.authenticate(
                                reason: 'Confirmation biométrique requise',
                              );
                              if (context.mounted) {
                                Navigator.pop(context, success);
                              }
                            },
                            child: const Text(
                              'BIOMÉTRIE',
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await ref
                          .read(firestoreServiceProvider)
                          .removeFavorite(track.id);
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
