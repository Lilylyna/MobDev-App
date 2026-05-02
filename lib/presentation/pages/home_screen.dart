import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../core/providers/app_providers.dart';
import 'player_screen.dart';
import 'favorites_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final stats = ref.watch(listeningStatsProvider);
    final goal = ref.watch(monthlyGoalProvider);

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Lecteur'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favoris'),
        ],
      ),
      body: _selectedIndex == 0 
        ? _buildDashboard(userProfile, stats, goal)
        : _selectedIndex == 1 
          ? const PlayerScreen()
          : const FavoritesScreen(),
    );
  }

  Widget _buildDashboard(AsyncValue<Map<String, dynamic>?> profile, AsyncValue<Map<String, int>> stats, AsyncValue<int> goal) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            profile.when(
              data: (data) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bienvenue,', style: TextStyle(fontSize: 18, color: Colors.white70)),
                  Text(
                    '${data?['firstName'] ?? ''} ${data?['lastName'] ?? ''}'.toUpperCase(),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Erreur profil'),
            ),
            const SizedBox(height: 32),
            _buildListeningOverview(stats, goal),
            const SizedBox(height: 24),
            _buildListeningChart(stats),
            const SizedBox(height: 24),
            _buildTopTracks(),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningOverview(AsyncValue<Map<String, int>> stats, AsyncValue<int> goal) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Écoute totale (mois)', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 4),
                  stats.when(
                    data: (map) {
                      final totalMinutes = map.values.fold(0, (sum, val) => sum + val);
                      final hours = totalMinutes ~/ 60;
                      final minutes = totalMinutes % 60;
                      return Text('${hours}h ${minutes}m', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
                    },
                    loading: () => const Text('--h --m'),
                    error: (_, __) => const Text('Erreur'),
                  ),
                ],
              ),
              DropdownButton<int>(
                value: goal.value ?? 20,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF1E1E1E),
                items: [10, 20, 30, 40, 50].map((h) => DropdownMenuItem(value: h, child: Text('$h h/mois'))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(localStorageServiceProvider).setMonthlyGoal(val);
                    ref.refresh(monthlyGoalProvider);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          stats.when(
            data: (map) {
              final totalMinutes = map.values.fold(0, (sum, val) => sum + val);
              final targetMinutes = (goal.value ?? 20) * 60;
              final progress = (totalMinutes / targetMinutes).clamp(0.0, 1.0);
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0C7C5C)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight, 
                    child: Text('${(progress * 100).toInt()}% de l\'objectif', style: const TextStyle(fontSize: 12))
                  ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningChart(AsyncValue<Map<String, int>> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activité du mois', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: stats.when(
            data: (map) {
              final entries = map.entries.toList();
              return BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (int i = 0; i < entries.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: entries[i].value.toDouble(),
                            color: const Color(0xFF0C7C5C),
                            width: 8,
                            borderRadius: BorderRadius.circular(2),
                          )
                        ],
                      ),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Erreur graphique')),
          ),
        ),
      ],
    );
  }

  Widget _buildTopTracks() {
    final topTracks = ref.watch(topTracksProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Meilleurs Morceaux', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        topTracks.when(
          data: (list) => list.isEmpty 
            ? const Text('Aucune écoute enregistrée', style: TextStyle(color: Colors.white54))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final track = list[index];
                  return ListTile(
                    leading: Text('#${index + 1}', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
                    title: Text(track['title']),
                    subtitle: Text('${track['count']} écoutes'),
                    trailing: const Icon(Icons.play_circle_outline),
                  );
                },
              ),
          loading: () => const LinearProgressIndicator(),
          error: (_, __) => const Text('Erreur top morceaux'),
        ),
      ],
    );
  }
}
