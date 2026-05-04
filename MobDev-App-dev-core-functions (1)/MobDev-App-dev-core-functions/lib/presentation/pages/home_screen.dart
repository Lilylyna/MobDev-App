import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    // Liaison avec les flux de données Firestore via Riverpod
    final userProfile = ref.watch(userProfileProvider);
    final statsStream = ref.watch(listeningStatsProvider);
    final goalValue = ref.watch(monthlyGoalProvider);

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
          ? _buildDashboard(userProfile, statsStream, goalValue)
          : _selectedIndex == 1
          ? const PlayerScreen()
          : const FavoritesScreen(),
    );
  }

  Widget _buildDashboard(AsyncValue<DocumentSnapshot?> profile, AsyncValue<QuerySnapshot> stats, int goal) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SECTION ENTÊTE : NOM ET PRÉNOM EN GRAS
            profile.when(
              data: (doc) {
                final data = doc?.data() as Map<String, dynamic>?;
                final firstName = data?['firstName'] ?? '';
                final lastName = data?['lastName'] ?? '';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                        'BIENVENUE,',
                        style: TextStyle(fontSize: 14, color: Colors.white70, letterSpacing: 1.2)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$firstName $lastName'.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold, // PRÉNOM + NOM EN GRAS
                        color: Colors.white,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, __) => Text('Erreur profil : $e'),
            ),
            const SizedBox(height: 32),

            // SECTION RÉCAPITULATIF (Objectif 20h)
            _buildListeningOverview(stats, goal),
            const SizedBox(height: 24),

            // SECTION GRAPHIQUE (Histogramme)
            _buildListeningChart(stats),
            const SizedBox(height: 24),

            // SECTION MEILLEURS MORCEAUX
            _buildTopTracks(),
          ],
        ),
      ),
    );
  }

  Widget _buildListeningOverview(AsyncValue<QuerySnapshot> stats, int goal) {
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
                    data: (snapshot) {
                      final totalMinutes = snapshot.docs.fold(0, (int sum, doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return sum + (data['minutes'] as int? ?? 0);
                      });
                      final hours = totalMinutes ~/ 60;
                      final minutes = totalMinutes % 60;
                      return Text('${hours}h ${minutes}m', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold));
                    },
                    loading: () => const Text('--h --m'),
                    error: (_, __) => const Text('Erreur'),
                  ),
                ],
              ),
              // Sélecteur d'objectif lié à Firebase
              DropdownButton<int>(
                value: goal,
                underline: const SizedBox(),
                dropdownColor: const Color(0xFF1E1E1E),
                items: [10, 20, 30, 40, 50].map((h) => DropdownMenuItem(value: h, child: Text('$h h/mois'))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    if (uid != null) {
                      ref.read(authServiceProvider).updateMonthlyGoal(uid, val);
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Barre de progression vers l'objectif
          stats.when(
            data: (snapshot) {
              final totalMinutes = snapshot.docs.fold(0, (int sum, doc) => sum + (doc['minutes'] as int? ?? 0));
              final targetMinutes = goal * 60;
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
                      child: Text('${(progress * 100).toInt()}% de l\'objectif ($goal h)', style: const TextStyle(fontSize: 12))
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

  Widget _buildListeningChart(AsyncValue<QuerySnapshot> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Activité du mois', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: stats.when(
            data: (snapshot) {
              final docs = snapshot.docs;
              if (docs.isEmpty) return const Center(child: Text("Aucune donnée d'écoute"));

              return BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: docs.asMap().entries.map((entry) {
                    final data = entry.value.data() as Map<String, dynamic>;
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: (data['minutes'] as int? ?? 0).toDouble(),
                          color: const Color(0xFF0C7C5C),
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        )
                      ],
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Center(child: Text('Erreur graphique : $e')),
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