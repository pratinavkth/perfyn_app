import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:perfyn_app/core/theme/app_colors.dart';
import 'package:perfyn_app/features/auth/presentation/login_screen.dart';
import 'package:perfyn_app/features/auth/providers/auth_provider.dart';
import 'package:perfyn_app/features/dashboard/presentation/home_screen.dart';
import 'package:perfyn_app/features/goals/presentation/goals_screen.dart';
import 'package:perfyn_app/features/insights/presentation/insights_screen.dart';
import 'package:perfyn_app/features/transactions/presentation/quick_add_sheet.dart';
import 'package:perfyn_app/features/transactions/presentation/transactions_screen.dart';

class MainShellScreen extends ConsumerWidget {
  const MainShellScreen({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  static const tabs = <_TabItem>[
    _TabItem(
      label: 'Home',
      icon: Icons.home_rounded,
      location: HomeScreen.routePath,
    ),
    _TabItem(
      label: 'Txn',
      icon: Icons.receipt_long_rounded,
      location: TransactionsScreen.routePath,
    ),
    _TabItem(
      label: 'Goals',
      icon: Icons.flag_rounded,
      location: GoalsScreen.routePath,
    ),
    _TabItem(
      label: 'Insights',
      icon: Icons.insights_rounded,
      location: InsightsScreen.routePath,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final session = ref.watch(currentSessionProvider);

    return Scaffold(
      endDrawer: _AppDrawer(
        email: session?.user.email ?? 'profile@perfyn.app',
        isLoading: authState.isLoading,
        onLogout: () async {
          await ref.read(authControllerProvider.notifier).signOut();
          if (context.mounted) {
            context.go(LoginScreen.routePath);
          }
        },
      ),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        height: 72,
        destinations: tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                label: tab.label,
              ),
            )
            .toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          QuickAddSheet.show(context);
        },
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Quick add'),
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer({
    required this.email,
    required this.isLoading,
    required this.onLogout,
  });

  final String email;
  final bool isLoading;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10324A), Color(0xFF1A6D86)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Your profile',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _DrawerTile(
                icon: Icons.account_circle_outlined,
                title: 'Profile',
                subtitle: 'View and edit your account details',
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile/settings screen will be connected next.'),
                    ),
                  );
                },
              ),
              _DrawerTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Budget alerts and reminders',
                onTap: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications screen will be connected next.'),
                    ),
                  );
                },
              ),
              _DrawerTile(
                icon: Icons.info_outline_rounded,
                title: 'About us',
                subtitle: 'Learn more about Perfyn',
                onTap: () {
                  Navigator.of(context).pop();
                  showAboutDialog(
                    context: context,
                    applicationName: 'Perfyn',
                    applicationVersion: '1.0.0',
                    applicationLegalese: 'Personal finance companion',
                  );
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          Navigator.of(context).pop();
                          await onLogout();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ink,
                    foregroundColor: Colors.white,
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.logout_rounded),
                  label: Text(isLoading ? 'Signing out...' : 'Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.ocean.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: AppColors.ocean),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: AppColors.ink,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppColors.slate,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.location,
  });

  final String label;
  final IconData icon;
  final String location;
}
