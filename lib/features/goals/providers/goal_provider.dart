import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfyn_app/app/providers/app_providers.dart';
import 'package:perfyn_app/features/auth/providers/auth_provider.dart';
import 'package:perfyn_app/features/goals/data/goal_repository.dart';
import 'package:perfyn_app/features/goals/domain/entities/goal_record.dart';

/// Provides the [GoalRepository] instance.
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return GoalRepository(client);
});

/// Fetches all goals for the current user from Supabase.
final goalsProvider = FutureProvider.autoDispose<List<GoalRecord>>((ref) async {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return const [];

  final repository = ref.watch(goalRepositoryProvider);
  return repository.fetchGoals(session.user.id);
});

/// Controller for goal mutations (add, update progress, delete).
final goalControllerProvider =
    StateNotifierProvider.autoDispose<GoalController, AsyncValue<void>>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  return GoalController(ref, repository);
});

class GoalController extends StateNotifier<AsyncValue<void>> {
  GoalController(this._ref, this._repository) : super(const AsyncData(null));

  final Ref _ref;
  final GoalRepository _repository;

  /// Add a new goal. Returns an error message on failure, null on success.
  Future<String?> addGoal({
    required String title,
    required double targetAmount,
    required GoalType type,
    DateTime? deadline,
  }) async {
    final session = _ref.read(currentSessionProvider);
    if (session == null) {
      return 'You need to sign in before creating a goal.';
    }

    state = const AsyncLoading();

    try {
      await _repository.addGoal(
        userId: session.user.id,
        title: title,
        targetAmount: targetAmount,
        type: type,
        deadline: deadline,
      );

      state = const AsyncData(null);
      _ref.invalidate(goalsProvider);
      return null;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return 'Could not save the goal. Please try again.';
    }
  }

  /// Update the progress amount of a goal.
  Future<String?> updateProgress({
    required String goalId,
    required double currentAmount,
  }) async {
    state = const AsyncLoading();

    try {
      await _repository.updateGoalProgress(
        goalId: goalId,
        currentAmount: currentAmount,
      );

      state = const AsyncData(null);
      _ref.invalidate(goalsProvider);
      return null;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return 'Could not update the goal. Please try again.';
    }
  }

  /// Delete a goal by ID.
  Future<String?> deleteGoal(String goalId) async {
    state = const AsyncLoading();

    try {
      await _repository.deleteGoal(goalId);

      state = const AsyncData(null);
      _ref.invalidate(goalsProvider);
      return null;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return 'Could not delete the goal. Please try again.';
    }
  }
}
