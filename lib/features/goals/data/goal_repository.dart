import 'package:perfyn_app/features/goals/domain/entities/goal_record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for CRUD operations on the Supabase `goals` table.
class GoalRepository {
  const GoalRepository(this._client);

  final SupabaseClient _client;

  /// Fetch all goals for the given user, newest first.
  Future<List<GoalRecord>> fetchGoals(String userId) async {
    final response = await _client
        .from('goals')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response
        .map<GoalRecord>(
          (item) => GoalRecord.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  /// Insert a new goal.
  Future<void> addGoal({
    required String userId,
    required String title,
    required double targetAmount,
    required GoalType type,
    DateTime? deadline,
  }) async {
    await _client.from('goals').insert({
      'user_id': userId,
      'title': title.trim(),
      'target_amount': targetAmount,
      'current_amount': 0,
      'type': GoalRecord.goalTypeToString(type),
      'deadline': deadline != null ? _formatDate(deadline) : null,
    });
  }

  /// Update the current amount saved towards a goal.
  Future<void> updateGoalProgress({
    required String goalId,
    required String userId,
    required double currentAmount,
  }) async {
    await _client
        .from('goals')
        .update({'current_amount': currentAmount})
        .eq('id', goalId)
        .eq('user_id', userId);
  }

  /// Delete a goal by its ID, scoped to the owning user.
  Future<void> deleteGoal({
    required String goalId,
    required String userId,
  }) async {
    await _client
        .from('goals')
        .delete()
        .eq('id', goalId)
        .eq('user_id', userId);
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
