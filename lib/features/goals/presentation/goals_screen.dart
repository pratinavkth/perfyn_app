import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfyn_app/core/theme/app_colors.dart';
import 'package:perfyn_app/features/goals/domain/entities/goal_record.dart';
import 'package:perfyn_app/features/goals/presentation/add_goal_sheet.dart';
import 'package:perfyn_app/features/goals/providers/goal_provider.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  static const routePath = '/goals';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final goalsAsync = ref.watch(goalsProvider);

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
            ref.invalidate(goalsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Goals',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Track savings goals, budgets, and no-spend challenges.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      return IconButton.filledTonal(
                        onPressed: () {
                          Scaffold.of(context).openEndDrawer();
                        },
                        icon: const Icon(Icons.person_outline_rounded),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 22),
              // Add goal action card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF4E7), Color(0xFFF0FAFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppColors.ink.withValues(alpha: 0.05),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set a new goal',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create savings targets, monthly budgets, or no-spend challenges and watch your progress here.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () {
                        AddGoalSheet.show(context);
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create goal'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              // Goals list
              goalsAsync.when(
                data: (goals) => _GoalsList(goals: goals),
                loading: () => const _StatusCard(
                  title: 'Loading goals...',
                  subtitle: 'Fetching from Supabase.',
                  icon: Icons.sync_rounded,
                ),
                error: (error, _) => _StatusCard(
                  title: 'Could not load goals',
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

class _GoalsList extends StatelessWidget {
  const _GoalsList({required this.goals});

  final List<GoalRecord> goals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (goals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140A2538),
              blurRadius: 24,
              offset: Offset(0, 14),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.coral.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.flag_rounded, color: AppColors.coral),
            ),
            const SizedBox(height: 16),
            Text(
              'No goals yet',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first goal and start tracking your progress.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.slate,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your goals',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 14),
        ...goals.map((goal) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _GoalCard(goal: goal),
            )),
      ],
    );
  }
}

class _GoalCard extends ConsumerWidget {
  const _GoalCard({required this.goal});

  final GoalRecord goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = _accentForType(goal.type);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140A2538),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_iconForType(goal.type), color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _subtitleForGoal(goal),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.slate,
                      ),
                    ),
                  ],
                ),
              ),
              if (goal.isCompleted)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '✓ Done',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'delete') {
                    final error = await ref
                        .read(goalControllerProvider.notifier)
                        .deleteGoal(goal.id);
                    if (error != null && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error)),
                      );
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            color: AppColors.danger, size: 18),
                        SizedBox(width: 8),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rs ${goal.currentAmount.toStringAsFixed(0)}',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'of Rs ${goal.targetAmount.toStringAsFixed(0)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: goal.progress,
                        minHeight: 10,
                        backgroundColor: accent.withValues(alpha: 0.12),
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(goal.progress * 100).toStringAsFixed(0)}% complete',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.slate,
                            fontSize: 12,
                          ),
                        ),
                        if (goal.daysRemaining != null)
                          Text(
                            '${goal.daysRemaining} days left',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.slate,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _accentForType(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return AppColors.success;
      case GoalType.budget:
        return AppColors.ocean;
      case GoalType.noSpend:
        return AppColors.coral;
    }
  }

  IconData _iconForType(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return Icons.savings_rounded;
      case GoalType.budget:
        return Icons.account_balance_wallet_rounded;
      case GoalType.noSpend:
        return Icons.block_rounded;
    }
  }

  String _subtitleForGoal(GoalRecord goal) {
    switch (goal.type) {
      case GoalType.savings:
        return 'Savings goal';
      case GoalType.budget:
        return 'Budget limit';
      case GoalType.noSpend:
        return 'No-spend challenge';
    }
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
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
