/// Goal types supported by the app.
enum GoalType {
  savings,
  noSpend,
  budget,
}

/// A single savings/budget/no-spend goal stored in the Supabase `goals` table.
class GoalRecord {
  const GoalRecord({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.type,
    required this.createdAt,
    this.deadline,
  });

  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final GoalType type;
  final DateTime createdAt;

  /// Progress from 0.0 to 1.0.
  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);

  /// Whether the goal has been fully achieved.
  bool get isCompleted => progress >= 1.0;

  /// How many days remain until the deadline, or `null` if no deadline is set.
  int? get daysRemaining {
    if (deadline == null) return null;
    final diff = deadline!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  factory GoalRecord.fromJson(Map<String, dynamic> json) {
    return GoalRecord(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled goal',
      targetAmount: (json['target_amount'] as num?)?.toDouble() ?? 0,
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
      type: _parseGoalType(json['type'] as String?),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  static GoalType _parseGoalType(String? value) {
    switch (value) {
      case 'no_spend':
        return GoalType.noSpend;
      case 'budget':
        return GoalType.budget;
      case 'savings':
      default:
        return GoalType.savings;
    }
  }

  static String goalTypeToString(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return 'savings';
      case GoalType.noSpend:
        return 'no_spend';
      case GoalType.budget:
        return 'budget';
    }
  }
}
