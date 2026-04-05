import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfyn_app/features/goals/domain/entities/goal_record.dart';
import 'package:perfyn_app/features/goals/providers/goal_provider.dart';
import 'package:perfyn_app/features/transactions/domain/entities/transaction_record.dart';
import 'package:perfyn_app/features/transactions/providers/transaction_provider.dart';

/// Computed insights derived from the user's transactions.
final insightsProvider = FutureProvider.autoDispose<InsightsData>((ref) async {
  final transactions = await ref.watch(transactionsProvider.future);
  final goals = await ref.watch(goalsProvider.future);

  final now = DateTime.now();

  // --- Category spending breakdown (current month expenses) ---
  final monthExpenses = transactions
      .where((t) =>
          t.isExpense &&
          t.date.year == now.year &&
          t.date.month == now.month)
      .toList();

  final categoryMap = <String, double>{};
  for (final t in monthExpenses) {
    categoryMap[t.category] = (categoryMap[t.category] ?? 0) + t.amount;
  }

  final totalMonthExpense =
      categoryMap.values.fold(0.0, (sum, val) => sum + val);

  final budgetGoals = goals.where((g) => g.type == GoalType.budget).toList();

  final categoryBreakdown = categoryMap.entries.map((entry) {
    // Try to find a budget goal with a title matching the category
    final matchingBudget = budgetGoals.where((g) => g.title.toLowerCase() == entry.key.toLowerCase()).firstOrNull;

    return CategorySpend(
      category: entry.key,
      amount: entry.value,
      percentage:
          totalMonthExpense > 0 ? entry.value / totalMonthExpense : 0,
      budgetLimit: matchingBudget?.targetAmount,
    );
  }).toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));

  // --- Top category ---
  final topCategory =
      categoryBreakdown.isNotEmpty ? categoryBreakdown.first : null;

  // --- Weekly comparison (this week vs last week) ---
  final weekday = now.weekday; // 1=Mon, 7=Sun
  final thisWeekStart =
      DateTime(now.year, now.month, now.day).subtract(Duration(days: weekday - 1));
  final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
  final lastWeekEnd = thisWeekStart;

  double thisWeekTotal = 0;
  double lastWeekTotal = 0;

  for (final t in transactions) {
    if (!t.isExpense) continue;
    if (!t.date.isBefore(thisWeekStart) && !t.date.isAfter(now)) {
      thisWeekTotal += t.amount;
    } else if (!t.date.isBefore(lastWeekStart) &&
        t.date.isBefore(lastWeekEnd)) {
      lastWeekTotal += t.amount;
    }
  }

  // --- Monthly totals ---
  double monthlyIncome = 0;
  double monthlyExpense = totalMonthExpense;
  for (final t in transactions) {
    if (t.date.year == now.year && t.date.month == now.month) {
      if (t.type == TransactionType.income) {
        monthlyIncome += t.amount;
      }
    }
  }

  // --- Transaction count ---
  final monthTxnCount = transactions
      .where((t) => t.date.year == now.year && t.date.month == now.month)
      .length;

  return InsightsData(
    categoryBreakdown: categoryBreakdown,
    topCategory: topCategory,
    thisWeekSpending: thisWeekTotal,
    lastWeekSpending: lastWeekTotal,
    monthlyIncome: monthlyIncome,
    monthlyExpense: monthlyExpense,
    monthTransactionCount: monthTxnCount,
  );
});

/// Holds all computed insight values for the current month.
class InsightsData {
  const InsightsData({
    required this.categoryBreakdown,
    required this.topCategory,
    required this.thisWeekSpending,
    required this.lastWeekSpending,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.monthTransactionCount,
  });

  final List<CategorySpend> categoryBreakdown;
  final CategorySpend? topCategory;
  final double thisWeekSpending;
  final double lastWeekSpending;
  final double monthlyIncome;
  final double monthlyExpense;
  final int monthTransactionCount;

  /// Whether there is any spending data from last week to compare against.
  bool get hasPriorWeekSpend => lastWeekSpending > 0;

  /// Percentage change from last week to this week.
  /// Positive = spending more, Negative = spending less.
  /// Returns `null` when there is no prior-week spend (zero baseline).
  double? get weeklyChange {
    if (lastWeekSpending <= 0) return null;
    return ((thisWeekSpending - lastWeekSpending) / lastWeekSpending);
  }
}

/// Spending in a single category.
class CategorySpend {
  const CategorySpend({
    required this.category,
    required this.amount,
    required this.percentage,
    this.budgetLimit,
  });

  final String category;
  final double amount;

  /// Fraction from 0.0 to 1.0 of total monthly expense.
  final double percentage;
  
  /// The target budget limit for this category, if any.
  final double? budgetLimit;
}
