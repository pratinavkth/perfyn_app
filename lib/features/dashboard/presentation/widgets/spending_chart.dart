import 'package:flutter/material.dart';
import 'package:perfyn_app/core/theme/app_colors.dart';
import 'package:perfyn_app/features/dashboard/providers/dashboard_provider.dart';

class SpendingChart extends StatelessWidget {
  const SpendingChart({
    super.key,
    required this.weeklySpending,
  });

  final List<WeeklySpend> weeklySpending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxAmount = weeklySpending
        .map((item) => item.amount)
        .fold<double>(0, (previous, value) => value > previous ? value : previous);

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
            'Weekly spending',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A quick look at where your week felt heavier.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.slate,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 170,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklySpending.map((entry) {
                final heightFactor = maxAmount == 0 ? 0.0 : entry.amount / maxAmount;
                final clampedHeight = heightFactor.clamp(0.08, 1.0).toDouble();
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          entry.amount.toStringAsFixed(0),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.ink.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: clampedHeight,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      AppColors.ocean,
                                      entry.amount == maxAmount
                                          ? AppColors.coral
                                          : AppColors.mint,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          entry.day,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.slate,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
