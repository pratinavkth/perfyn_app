import 'package:flutter/material.dart';
import 'package:perfyn_app/core/theme/app_colors.dart';
import 'package:perfyn_app/features/dashboard/providers/dashboard_provider.dart';

class RecentTransactions extends StatelessWidget {
  const RecentTransactions({
    super.key,
    required this.items,
  });

  final List<DashboardTransaction> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            'Recent transactions',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The latest money moves at a glance.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              'No transactions yet. Use Quick add to create your first one.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.slate,
              ),
            )
          else
            ...items.map((item) => _TransactionRow(item: item)),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({required this.item});

  final DashboardTransaction item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = item.isExpense ? AppColors.coral : AppColors.success;
    final amountPrefix = item.isExpense ? '- ' : '+ ';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              item.isExpense ? Icons.south_east_rounded : Icons.north_east_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.category,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.slate,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${amountPrefix}Rs ${item.amount.toStringAsFixed(0)}',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
