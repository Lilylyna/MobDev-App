import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
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
                    final bool? confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Theme.of(context).cardColor,
                        title: Text(
                          'Confirmation',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        content: Text(
                          'Voulez-vous vraiment supprimer ce favori ?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              'ANNULER',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                                  ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                            ),
                            onPressed: () async {
                              final bioService = ref.read(
                                biometricServiceProvider,
                              );
                              final success = await bioService.authenticate(
                                reason:
                                    'Confirmation biométrique requise pour la suppression',
                              );
                              if (context.mounted) {
                                Navigator.pop(context, success);
                              }
                            },
                            child: const Text(
                              'CONFIRMER (BIO)',
                              style: TextStyle(color: Colors.white),
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
