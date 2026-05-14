import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/audio_track.dart';
import 'player_screen.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(listeningStatsProvider);
    final goalAsync = ref.watch(monthlyGoalProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STATISTICS',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  letterSpacing: 2,
                  color: AppTheme.accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Listening Progress',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Summary Card
              _buildSummaryCard(context, ref, stats, goalAsync),
              const SizedBox(height: 32),

              // Main Graph
              Text(
                'Listening Time (Last 30 Days)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildListeningChart(stats),
              const SizedBox(height: 32),

              // Recently Played
              Text(
                'Recently Played',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildRecentlyPlayed(ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<QuerySnapshot> stats,
    AsyncValue<int> goalAsync,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Goal',
                    style: TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${goalAsync.value ?? 10} Tracks/Day',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppTheme.accentColor,
                ),
                onPressed: () =>
                    _showGoalEditor(context, ref, goalAsync.value ?? 10),
              ),
            ],
          ),
          const SizedBox(height: 24),
          stats.when(
            data: (snapshot) {
              final totalMinutes = snapshot.docs.fold(
                0,
                (int sum, doc) => sum + (doc['minutes'] as int? ?? 0),
              );
              final goal = goalAsync.value ?? 10;
              final targetMinutes = goal * 60;
              final progress = (totalMinutes / targetMinutes).clamp(0.0, 1.0);

              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: Colors.white10,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.accentColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$totalMinutes / $targetMinutes mins',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}% achieved',
                        style: const TextStyle(
                          color: AppTheme.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox(),
          ),
        ],
      ),
    );
  }

  void _showGoalEditor(BuildContext context, WidgetRef ref, int currentGoal) {
    showDialog(
      context: context,
      builder: (context) {
        int selected = currentGoal;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceColor,
              title: const Text('Modify Daily Goal'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select number of tracks per day:'),
                  const SizedBox(height: 20),
                  DropdownButton<int>(
                    value: selected,
                    dropdownColor: AppTheme.surfaceColor,
                    isExpanded: true,
                    items: [5, 10, 15, 20, 25, 30]
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text('$v Tracks'),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selected = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ref
                        .read(localStorageServiceProvider)
                        .setMonthlyGoal(selected);
                    ref.invalidate(monthlyGoalProvider);
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildListeningChart(AsyncValue<QuerySnapshot> stats) {
    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 20, right: 20, left: 10, bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: stats.when(
        data: (snapshot) {
          final dataMap = <String, int>{};
          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['date'] != null) {
              final date = (data['date'] as Timestamp).toDate();
              final key = DateFormat('yyyy-MM-dd').format(date);
              dataMap[key] =
                  (dataMap[key] ?? 0) + (data['minutes'] as int? ?? 0);
            }
          }

          final last30Days = List.generate(30, (i) {
            return DateTime.now().subtract(Duration(days: 29 - i));
          });

          final barGroups = last30Days.asMap().entries.map((entry) {
            final date = entry.value;
            final key = DateFormat('yyyy-MM-dd').format(date);
            final mins = dataMap[key] ?? 0;

            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: mins.toDouble(),
                  color: mins > 0
                      ? AppTheme.accentColor
                      : Colors.white.withOpacity(0.05),
                  width: 6,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
              ],
            );
          }).toList();

          return BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 60, // 1 hour max for scale
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) =>
                    const FlLine(color: Colors.white10, strokeWidth: 1),
              ),
              titlesData: FlTitlesData(
                show: true,
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) => Text(
                      '${value.toInt()}m',
                      style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index % 5 == 0 && index >= 0 && index < 30) {
                        final date = last30Days[index];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('dd/M').format(date),
                            style: const TextStyle(
                              color: Colors.white24,
                              fontSize: 8,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.accentColor),
        ),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildRecentlyPlayed(WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    return historyAsync.when(
      data: (list) => list.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'No records yet',
                  style: TextStyle(color: Colors.white24),
                ),
              ),
            )
          : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final item = list[index];
                final track = AudioTrack(
                  id: item['id'] ?? '',
                  title: item['title'] ?? 'Unknown',
                  category: item['category'] ?? 'Coran',
                  audioUrl: item['audioUrl'] ?? '',
                  duration: Duration.zero,
                );

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    final handler = ref.read(audioHandlerProvider);
                    handler.playMediaItem(track.toMediaItem());
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlayerScreen(track: track),
                      ),
                    );
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  title: Text(track.title),
                  subtitle: Text(
                    track.category,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  trailing: const Icon(
                    Icons.play_circle_outline,
                    color: Colors.white24,
                  ),
                );
              },
            ),
      loading: () => const SizedBox(),
      error: (_, _) => const SizedBox(),
    );
  }
}
