import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfyn_app/features/auth/providers/auth_provider.dart';
import 'package:perfyn_app/features/transactions/domain/entities/transaction_record.dart';
import 'package:perfyn_app/features/transactions/providers/transaction_provider.dart';

final dashboardOverviewProvider = FutureProvider<DashboardOverview>((ref) async {
  final session = ref.watch(currentSessionProvider);
  final email = session?.user.email ?? 'friend@perfyn.app';
  final name = email.split('@').first;
  final transactions = await ref.watch(transactionsProvider.future);

  final now = DateTime.now();
  final monthTransactions = transactions
      .where((item) => item.date.year == now.year && item.date.month == now.month)
      .toList();
  final monthlyIncome = _sumForType(monthTransactions, TransactionType.income);
  final monthlyExpense = _sumForType(monthTransactions, TransactionType.expense);
  final totalIncome = _sumForType(transactions, TransactionType.income);
  final totalExpense = _sumForType(transactions, TransactionType.expense);
  final weeklySpending = _buildWeeklySpending(transactions, now);
  final recentTransactions = transactions.take(5).map(_toDashboardItem).toList();

  return DashboardOverview(
    userLabel: _toDisplayName(name),
    totalBalance: totalIncome - totalExpense,
    monthlyIncome: monthlyIncome,
    monthlyExpense: monthlyExpense,
    savingsRate: monthlyIncome <= 0
        ? 0
        : ((monthlyIncome - monthlyExpense) / monthlyIncome)
            .clamp(0.0, 1.0)
            .toDouble(),
    weeklySpending: weeklySpending,
    recentTransactions: recentTransactions,
  );
});

double _sumForType(List<TransactionRecord> items, TransactionType type) {
  return items
      .where((item) => item.type == type)
      .fold(0.0, (sum, item) => sum + item.amount);
}

List<WeeklySpend> _buildWeeklySpending(List<TransactionRecord> transactions, DateTime now) {
  final days = List.generate(7, (index) {
    final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - index));
    final total = transactions
        .where(
          (item) =>
              item.isExpense &&
              item.date.year == day.year &&
              item.date.month == day.month &&
              item.date.day == day.day,
        )
        .fold(0.0, (sum, item) => sum + item.amount);

    return WeeklySpend(day: _weekdayLabel(day.weekday), amount: total);
  });

  return days;
}

DashboardTransaction _toDashboardItem(TransactionRecord item) {
  final title = item.notes?.trim().isNotEmpty == true ? item.notes!.trim() : item.category;
  return DashboardTransaction(
    title: title,
    category: item.category,
    amount: item.amount,
    isExpense: item.isExpense,
  );
}

String _weekdayLabel(int weekday) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return labels[weekday - 1];
}

String _toDisplayName(String value) {
  if (value.isEmpty) return 'there';
  return value[0].toUpperCase() + value.substring(1);
}

class DashboardOverview {
  const DashboardOverview({
    required this.userLabel,
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.savingsRate,
    required this.weeklySpending,
    required this.recentTransactions,
  });

  final String userLabel;
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpense;
  final double savingsRate;
  final List<WeeklySpend> weeklySpending;
  final List<DashboardTransaction> recentTransactions;
}

class WeeklySpend {
  const WeeklySpend({
    required this.day,
    required this.amount,
  });

  final String day;
  final double amount;
}

class DashboardTransaction {
  const DashboardTransaction({
    required this.title,
    required this.category,
    required this.amount,
    required this.isExpense,
  });

  final String title;
  final String category;
  final double amount;
  final bool isExpense;
}
