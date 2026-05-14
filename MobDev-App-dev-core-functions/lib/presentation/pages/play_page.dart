import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/audio_track.dart';
import '../../core/models/reciter.dart';
import 'player_screen.dart';

class PlayPage extends ConsumerStatefulWidget {
  const PlayPage({super.key});

  @override
  ConsumerState<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends ConsumerState<PlayPage> {
  String? _currentView; // 'reciters' or 'surahs' or null (main)
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    if (_currentView == 'reciters') {
      return _buildRecitersList();
    } else if (_currentView == 'surahs') {
      return _buildSurahsList();
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Favorites', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _buildFavoritesBar(),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: _buildSquareTab(
                      icon: Icons.mic,
                      label: 'Reciters',
                      onTap: () => setState(() => _currentView = 'reciters'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSquareTab(
                      icon: Icons.book,
                      label: 'Surahs',
                      onTap: () => setState(() => _currentView = 'surahs'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesBar() {
    final favoritesAsync = ref.watch(favoritesProvider);
    return SizedBox(
      height: 120,
      child: favoritesAsync.when(
        data: (list) => list.isEmpty
            ? const Center(
                child: Text(
                  'No favorites yet',
                  style: TextStyle(color: Colors.white30),
                ),
              )
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final track = list[index];
                  return GestureDetector(
                    onTap: () {
                      final handler = ref.read(audioHandlerProvider);
                      handler.addQueueItems(
                        list.map((t) => t.toMediaItem()).toList(),
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlayerScreen(track: track),
                        ),
                      );
                    },
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: AppTheme.surfaceColor,
                            child: const Icon(
                              Icons.music_note,
                              color: AppTheme.accentColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            track.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Error')),
      ),
    );
  }

  Widget _buildSquareTab({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppTheme.accentColor),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecitersList() {
    final recitersAsync = FutureProvider(
      (ref) => ref.read(apiServiceProvider).getReciters(),
    );
    final reciters = ref.watch(recitersAsync);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() {
            _currentView = null;
            _searchQuery = '';
            _searchController.clear();
          }),
        ),
        title: const Text('Reciters'),
      ),
      body: Column(
        children: [
          _buildSearchBar('Search by reciter...'),
          Expanded(
            child: reciters.when(
              data: (list) {
                final filtered = list.where((r) {
                  final name = r['reciter_name'].toString().toLowerCase();
                  final shortName = r['reciter_short_name']
                      .toString()
                      .toLowerCase();
                  return name.contains(_searchQuery.toLowerCase()) ||
                      shortName.contains(_searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final r = Reciter.fromJson(filtered[index]);
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                        child: Text(
                          r.name[0],
                          style: const TextStyle(color: AppTheme.accentColor),
                        ),
                      ),
                      title: Text(r.name),
                      subtitle: Text(
                        r.shortName, // Using shortName as placeholder for "arabic name" if not available or just showing it
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        // For now, selecting a reciter might just filter surahs or something.
                        // But the request says "click on surah a music player opens".
                        // So maybe clicking reciter opens their surahs.
                        // I'll skip this depth for now or just show a message.
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurahsList() {
    final surahsAsync = FutureProvider(
      (ref) => ref.read(apiServiceProvider).getSurahs(),
    );
    final surahs = ref.watch(surahsAsync);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() {
            _currentView = null;
            _searchQuery = '';
            _searchController.clear();
          }),
        ),
        title: const Text('Surahs'),
      ),
      body: Column(
        children: [
          _buildSearchBar('Search by surah...'),
          Expanded(
            child: surahs.when(
              data: (list) {
                final filtered = list.where((s) {
                  final name = s['name_en'].toString().toLowerCase();
                  final nameAr = s['name_ar'].toString().toLowerCase();
                  return name.contains(_searchQuery.toLowerCase()) ||
                      nameAr.contains(_searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final s = filtered[index];
                    return ListTile(
                      leading: Text(
                        s['number'].toString(),
                        style: const TextStyle(color: AppTheme.accentColor),
                      ),
                      title: Text(s['name_en']),
                      subtitle: Text(
                        s['name_ar'],
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () async {
                        final api = ref.read(apiServiceProvider);
                        final handler = ref.read(audioHandlerProvider);

                        // Current track
                        final track = await api.getTrackDetail(
                          s['number'].toString(),
                          s['name_en'],
                        );

                        // Set queue with all filtered surahs using the fast constructor
                        final mediaItems = filtered
                            .map(
                              (surah) =>
                                  api.getTrackFromSurah(surah).toMediaItem(),
                            )
                            .toList();
                        handler.addQueueItems(mediaItems);

                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(track: track),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(String hint) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
        ),
      ),
    );
  }
}
