import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:perfyn_app/app/providers/app_providers.dart';
import 'package:perfyn_app/core/database/database_provider.dart';
import 'package:perfyn_app/core/network/sync_manager.dart';
import 'package:perfyn_app/features/auth/providers/auth_provider.dart';
import 'package:perfyn_app/features/goals/data/goal_repository.dart';
import 'package:perfyn_app/features/goals/domain/entities/goal_record.dart';

/// Provides the [GoalRepository] instance.
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final dao = ref.watch(appDatabaseProvider).goalsDao;
  final syncManager = ref.watch(syncManagerProvider);
  return GoalRepository(client, dao, syncManager);
});

/// Watches all goals for the current user from SQLite drift database.
final goalsProvider = StreamProvider.autoDispose<List<GoalRecord>>((ref) {
  final session = ref.watch(currentSessionProvider);
  if (session == null) return const Stream.empty();

  final repository = ref.watch(goalRepositoryProvider);
  repository.syncFromServer(session.user.id).catchError((_) {});

  return repository.watchGoals(session.user.id);
});

/// Controller for goal mutations (add, update progress, delete).
/// Not autoDispose — survives async mutations that outlive the calling widget.
final goalControllerProvider =
    StateNotifierProvider<GoalController, AsyncValue<void>>((ref) {
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
      return null;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return 'Could not save the goal. Please try again.';
    }
  }

  /// Update full goal configuration.
  Future<String?> updateGoal({
    required int localId,
    required String? remoteId,
    required String title,
    required double targetAmount,
    required GoalType type,
    DateTime? deadline,
  }) async {
    final session = _ref.read(currentSessionProvider);
    if (session == null) return 'You need to sign in.';

    state = const AsyncLoading();

    try {
      await _repository.updateGoal(
        localId: localId,
        remoteId: remoteId,
        userId: session.user.id,
        title: title,
        targetAmount: targetAmount,
        type: type,
        deadline: deadline,
      );

      state = const AsyncData(null);
      return null;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return 'Could not update the goal. Please try again.';
    }
  }

  Future<String?> updateProgress({
    required int localId,
    required String? remoteId,
    required double currentAmount,
  }) async {
    final session = _ref.read(currentSessionProvider);
    if (session == null) return 'You need to sign in.';

    state = const AsyncLoading();

    try {
      await _repository.updateGoalProgress(
        localId: localId,
        remoteId: remoteId,
        userId: session.user.id,
        currentAmount: currentAmount,
      );

      state = const AsyncData(null);
      return null;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return 'Could not update the goal. Please try again.';
    }
  }

  Future<String?> deleteGoal(int localId, String? remoteId) async {
    final session = _ref.read(currentSessionProvider);
    if (session == null) return 'You need to sign in.';

    state = const AsyncLoading();

    try {
      await _repository.deleteGoal(
        localId: localId,
        remoteId: remoteId,
        userId: session.user.id,
      );

      state = const AsyncData(null);
      return null;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return 'Could not delete the goal. Please try again.';
    }
  }
}
