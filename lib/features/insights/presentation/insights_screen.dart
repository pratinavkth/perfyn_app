import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfyn_app/core/theme/app_colors.dart';
import 'package:perfyn_app/features/insights/providers/insights_provider.dart';
import 'package:perfyn_app/features/transactions/providers/transaction_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  static const routePath = '/insights';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final insightsAsync = ref.watch(insightsProvider);

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
            ref.invalidate(insightsProvider);
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
                          'Insights',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'See where your money goes this month.',
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
              insightsAsync.when(
                data: (data) => _InsightsContent(data: data),
                loading: () => const _StatusCard(
                  title: 'Crunching numbers...',
                  subtitle: 'Analyzing your transactions.',
                  icon: Icons.sync_rounded,
                ),
                error: (error, _) => _StatusCard(
                  title: 'Could not load insights',
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

class _InsightsContent extends StatelessWidget {
  const _InsightsContent({required this.data});

  final InsightsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (data.monthTransactionCount == 0) {
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
                color: AppColors.mint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child:
                  const Icon(Icons.insights_rounded, color: AppColors.mint),
            ),
            const SizedBox(height: 16),
            Text(
              'No data this month',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add some transactions and insights will appear here automatically.',
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
      children: [
        // Monthly overview
        _MonthlyOverviewCard(data: data),
        const SizedBox(height: 18),
        // Weekly comparison
        _WeeklyComparisonCard(data: data),
        const SizedBox(height: 18),
        // Top category callout
        if (data.topCategory != null) ...[
          _TopCategoryCard(category: data.topCategory!),
          const SizedBox(height: 18),
        ],
        // Category breakdown
        _CategoryBreakdownCard(categories: data.categoryBreakdown),
      ],
    );
  }
}

class _MonthlyOverviewCard extends StatelessWidget {
  const _MonthlyOverviewCard({required this.data});

  final InsightsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10324A), Color(0xFF1A6D86)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2210324A),
            blurRadius: 28,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This month',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Income',
                  value: 'Rs ${data.monthlyIncome.toStringAsFixed(0)}',
                  accent: AppColors.mint,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStat(
                  label: 'Expense',
                  value: 'Rs ${data.monthlyExpense.toStringAsFixed(0)}',
                  accent: const Color(0xFFFFC07A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.receipt_long_rounded,
                  color: Colors.white.withValues(alpha: 0.6), size: 16),
              const SizedBox(width: 8),
              Text(
                '${data.monthTransactionCount} transactions this month',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyComparisonCard extends StatelessWidget {
  const _WeeklyComparisonCard({required this.data});

  final InsightsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changePercent = (data.weeklyChange * 100).abs().toStringAsFixed(0);
    final isUp = data.weeklyChange > 0;
    final isFlat = data.weeklyChange == 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120A2538),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly comparison',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'How this week stacks up against last week.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _WeekColumn(
                  label: 'Last week',
                  amount: data.lastWeekSpending,
                  maxAmount: _maxOfBoth(),
                  color: AppColors.slate.withValues(alpha: 0.3),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _WeekColumn(
                  label: 'This week',
                  amount: data.thisWeekSpending,
                  maxAmount: _maxOfBoth(),
                  color: AppColors.ocean,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isFlat
                  ? AppColors.slate.withValues(alpha: 0.08)
                  : isUp
                      ? AppColors.coral.withValues(alpha: 0.08)
                      : AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFlat
                      ? Icons.remove_rounded
                      : isUp
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                  size: 18,
                  color: isFlat
                      ? AppColors.slate
                      : isUp
                          ? AppColors.coral
                          : AppColors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  isFlat
                      ? 'Same as last week'
                      : isUp
                          ? '$changePercent% more than last week'
                          : '$changePercent% less than last week',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isFlat
                        ? AppColors.slate
                        : isUp
                            ? AppColors.coral
                            : AppColors.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _maxOfBoth() {
    final m = data.thisWeekSpending > data.lastWeekSpending
        ? data.thisWeekSpending
        : data.lastWeekSpending;
    return m <= 0 ? 1 : m;
  }
}

class _WeekColumn extends StatelessWidget {
  const _WeekColumn({
    required this.label,
    required this.amount,
    required this.maxAmount,
    required this.color,
  });

  final String label;
  final double amount;
  final double maxAmount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = (amount / maxAmount).clamp(0.0, 1.0);

    return Column(
      children: [
        Text(
          'Rs ${amount.toStringAsFixed(0)}',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 90,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: fraction < 0.05 && amount > 0 ? 0.05 : fraction,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.slate,
          ),
        ),
      ],
    );
  }
}

class _TopCategoryCard extends StatelessWidget {
  const _TopCategoryCard({required this.category});

  final CategorySpend category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF4E7), Color(0xFFF0FAFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.local_fire_department_rounded,
                color: AppColors.coral),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biggest spend driver',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.slate,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category.category,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.ink,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Rs ${category.amount.toStringAsFixed(0)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.coral,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${(category.percentage * 100).toStringAsFixed(0)}% of total',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.slate,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.categories});

  final List<CategorySpend> categories;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (categories.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120A2538),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category breakdown',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Where the money went this month.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 18),
          ...categories.map(
            (cat) => _CategoryRow(category: cat),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category});

  final CategorySpend category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      AppColors.ocean,
      AppColors.coral,
      AppColors.mint,
      const Color(0xFF7986CB),
      const Color(0xFFFFB74D),
      AppColors.success,
      const Color(0xFFF06292),
      const Color(0xFF8D6E63),
    ];

    // Pick a consistent color based on the category name hash
    final colorIndex = category.category.hashCode.abs() % colors.length;
    final barColor = colors[colorIndex];

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.category,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Rs ${category.amount.toStringAsFixed(0)}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(category.percentage * 100).toStringAsFixed(0)}%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.slate,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: category.percentage,
              minHeight: 8,
              backgroundColor: barColor.withValues(alpha: 0.12),
              color: barColor,
            ),
          ),
        ],
      ),
    );
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
