import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfyn_app/core/theme/app_colors.dart';
import 'package:perfyn_app/features/dashboard/presentation/widgets/balance_card.dart';
import 'package:perfyn_app/features/dashboard/presentation/widgets/recent_transactions.dart';
import 'package:perfyn_app/features/dashboard/presentation/widgets/spending_chart.dart';
import 'package:perfyn_app/features/dashboard/providers/dashboard_provider.dart';
import 'package:perfyn_app/features/transactions/providers/transaction_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routeName = 'home';
  static const routePath = '/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(dashboardOverviewProvider);
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF5FBFF), Color(0xFFFFF6F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(transactionsProvider);
            ref.invalidate(dashboardOverviewProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              overviewAsync.when(
                skipLoadingOnRefresh: true,
                skipLoadingOnReload: true,
                data: (overview) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${overview.userLabel}',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Here is your money snapshot for today.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.slate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Builder(
                            builder: (context) {
                              return Row(
                                children: [
                                  IconButton.filledTonal(
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      GoRouter.of(context).pushNamed('notifications');
                                    },
                                    icon: const Icon(Icons.notifications_none_rounded),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filledTonal(
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      Scaffold.of(context).openEndDrawer();
                                    },
                                    icon: const Icon(Icons.person_outline_rounded),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      BalanceCard(
                        totalBalance: overview.totalBalance,
                        monthlyIncome: overview.monthlyIncome,
                        monthlyExpense: overview.monthlyExpense,
                        savingsRate: overview.savingsRate,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.go('/transactions');
                        },
                      ),
                      const SizedBox(height: 18),
                      SpendingChart(
                        weeklySpending: overview.weeklySpending,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.go('/insights');
                        },
                      ),
                      const SizedBox(height: 18),
                      RecentTransactions(
                        items: overview.recentTransactions,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          context.go('/transactions');
                        },
                      ),
                    ],
                  );
                },
                loading: () => const _DashboardStatusCard(
                  title: 'Loading your latest snapshot...',
                  subtitle: 'Fetching transactions from Supabase.',
                  icon: Icons.sync_rounded,
                ),
                error: (error, _) => _DashboardStatusCard(
                  title: 'Could not load dashboard data',
                  subtitle: error.toString(),
                  icon: Icons.cloud_off_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardStatusCard extends StatelessWidget {
  const _DashboardStatusCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Icon(icon, size: 34, color: AppColors.ocean),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.slate,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
