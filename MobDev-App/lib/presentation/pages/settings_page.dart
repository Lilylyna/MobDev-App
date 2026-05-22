import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('Account'),
          _buildSettingTile(
            context,
            icon: Icons.person_outline,
            title: 'Profile Details',
            onTap: () {
              _showProfileDialog(context, ref);
            },
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Preferences'),
          _buildSettingTile(
            context,
            icon: Icons.notifications_none,
            title: 'Notifications',
            trailingText: ref.watch(notificationsProvider) ? 'On' : 'Off',
            onTap: () {
              ref.read(notificationsProvider.notifier).toggleNotifications();
            },
          ),
          _buildSettingTile(
            context,
            icon: Icons.color_lens_outlined,
            title: ref.watch(themeProvider) == ThemeMode.dark ? 'Dark Theme' : 'Light Theme',
            onTap: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.withOpacity(0.8),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.accentColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSettingTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, String? trailingText}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppTheme.accentColor),
        title: Text(title),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (trailingText != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  trailingText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color?.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Profile Details'),
          content: Consumer(
            builder: (context, ref, _) {
              final profileAsync = ref.watch(userProfileProvider);
              return profileAsync.when(
                data: (doc) {
                  final data = doc?.data() as Map<String, dynamic>?;
                  if (data == null) return const Text('No profile data found.');
                  
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.person),
                        title: const Text('First Name'),
                        subtitle: Text(data['firstName'] ?? 'N/A'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      ListTile(
                        leading: const Icon(Icons.badge),
                        title: const Text('Last Name'),
                        subtitle: Text(data['lastName'] ?? 'N/A'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: const Text('Email'),
                        subtitle: Text(data['email'] ?? 'N/A'),
                        contentPadding: EdgeInsets.zero,
                      ),
                      ListTile(
                        leading: const Icon(Icons.timer),
                        title: const Text('Monthly Goal'),
                        subtitle: Text('${data['monthlyGoalHours'] ?? 20} hours'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  );
                },
                loading: () => const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Error loading profile: $e'),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
