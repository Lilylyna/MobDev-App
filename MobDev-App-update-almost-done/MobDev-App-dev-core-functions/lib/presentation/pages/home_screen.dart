import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/providers/app_providers.dart';
import 'favorites_screen.dart';

import 'statistics_page.dart';
import 'play_page.dart';
import 'settings_page.dart';
import '../widgets/mini_player.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const StatisticsPage(),
    const PlayPage(),
    const FavoritesScreen(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              title: Consumer(
                builder: (context, ref, _) {
                  final profile = ref.watch(userProfileProvider);
                  return profile.when(
                    data: (doc) {
                      final data = doc?.data() as Map<String, dynamic>?;
                      final firstName = data?['firstName'] ?? '';
                      return Text('HELLO ${firstName.toUpperCase()}');
                    },
                    loading: () => const Text('HELLO...'),
                    error: (_, __) => const Text('HELLO'),
                  );
                },
              ),
              centerTitle: false,
              elevation: 0,
              backgroundColor: Colors.transparent,
            )
          : null,
      body: _pages[_selectedIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart),
                label: 'Statistics',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.play_circle_outline),
                label: 'Play',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_outline),
                label: 'Favorites',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                label: 'Settings',
              ),
            ],
          ),
          const MiniPlayer(),
        ],
      ),
    );
  }
}
