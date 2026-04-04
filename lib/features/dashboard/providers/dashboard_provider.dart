import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfyn_app/features/auth/providers/auth_provider.dart';

final dashboardOverviewProvider = Provider<DashboardOverview>((ref) {
  final session = ref.watch(currentSessionProvider);
  final email = session?.user.email ?? 'friend@perfyn.app';
  final name = email.split('@').first;

  return DashboardOverview(
    userLabel: _toDisplayName(name),
    totalBalance: 48750,
    monthlyIncome: 72000,
    monthlyExpense: 23250,
    savingsRate: 0.68,
    weeklySpending: const [
      WeeklySpend(day: 'Mon', amount: 1200),
      WeeklySpend(day: 'Tue', amount: 850),
      WeeklySpend(day: 'Wed', amount: 1450),
      WeeklySpend(day: 'Thu', amount: 640),
      WeeklySpend(day: 'Fri', amount: 1725),
      WeeklySpend(day: 'Sat', amount: 980),
      WeeklySpend(day: 'Sun', amount: 430),
    ],
    recentTransactions: const [
      DashboardTransaction(
        title: 'Groceries',
        category: 'Food',
        amount: 1850,
        isExpense: true,
      ),
      DashboardTransaction(
        title: 'Salary',
        category: 'Income',
        amount: 72000,
        isExpense: false,
      ),
      DashboardTransaction(
        title: 'Metro Card',
        category: 'Travel',
        amount: 600,
        isExpense: true,
      ),
      DashboardTransaction(
        title: 'Coffee',
        category: 'Lifestyle',
        amount: 240,
        isExpense: true,
      ),
    ],
  );
});

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
