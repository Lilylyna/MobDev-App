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
  Reciter? _selectedReciter;

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
                      onTap: () => setState(() {
                        _currentView = 'reciters';
                        _searchQuery = '';
                        _searchController.clear();
                      }),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSquareTab(
                      icon: Icons.book,
                      label: 'Surahs',
                      onTap: () => setState(() {
                        _currentView = 'surahs';
                        _selectedReciter = null; // Default reciter
                        _searchQuery = '';
                        _searchController.clear();
                      }),
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
            ? Center(
                child: Text(
                  'No favorites yet',
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
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
                            backgroundColor: Theme.of(context).cardColor,
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
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: AppTheme.accentColor),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecitersList() {
    final reciters = ref.watch(recitersProvider);

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
                  final name = (r['reciter_name'] ?? r['name'] ?? '').toString().toLowerCase();
                  final shortName = (r['reciter_short_name'] ?? r['shortName'] ?? '').toString().toLowerCase();
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
                          r.name.isNotEmpty ? r.name[0] : '?',
                          style: const TextStyle(color: AppTheme.accentColor),
                        ),
                      ),
                      title: Text(r.name),
                      subtitle: Text(
                        r.shortName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                      ),
                      onTap: () {
                        print('DEBUG: PlayPage - Reciter tapped: ${r.name} (shortName: ${r.shortName})');
                        setState(() {
                          _selectedReciter = r;
                          _currentView = 'surahs';
                          _searchQuery = '';
                          _searchController.clear();
                        });
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
    final surahs = ref.watch(surahsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() {
            _currentView = _selectedReciter != null ? 'reciters' : null;
            _searchQuery = '';
            _searchController.clear();
            if (_currentView == null) _selectedReciter = null;
          }),
        ),
        title: Text(_selectedReciter != null ? _selectedReciter!.name : 'Surahs'),
      ),
      body: Column(
        children: [
          _buildSearchBar('Search by surah...'),
          Expanded(
            child: surahs.when(
              data: (list) {
                print('DEBUG: PlayPage - Surahs loaded: ${list.length} items');
                final filtered = list.where((s) {
                  final name = (s['name_en'] ?? s['englishName'] ?? '').toString().toLowerCase();
                  final nameAr = (s['name_ar'] ?? s['name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery.toLowerCase()) ||
                      nameAr.contains(_searchQuery.toLowerCase());
                }).toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final s = filtered[index];
                    return ListTile(
                      leading: Text(
                        (s['number'] ?? s['id'] ?? (index + 1)).toString(),
                        style: const TextStyle(color: AppTheme.accentColor),
                      ),
                      title: Text(s['name_en'] ?? s['englishName'] ?? 'Unknown'),
                      subtitle: Text(
                        s['name_ar'] ?? s['name'] ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                      ),
                      onTap: () async {
                        final api = ref.read(apiServiceProvider);
                        final handler = ref.read(audioHandlerProvider);

                        // Current track
                        final track = await api.getTrackDetail(
                          (s['number'] ?? s['id'] ?? (index + 1)).toString(),
                          s['name_en'] ?? s['englishName'] ?? 'Unknown',
                          reciterShortName: _selectedReciter?.shortName,
                          reciterServer: _selectedReciter?.server,
                        );

                        // Set queue with all filtered surahs
                        final mediaItems = filtered
                            .map(
                              (surah) =>
                                  api.getTrackFromSurah(
                                    surah, 
                                    reciterShortName: _selectedReciter?.shortName,
                                    reciterServer: _selectedReciter?.server,
                                  ).toMediaItem(),
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
