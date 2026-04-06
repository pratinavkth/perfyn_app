import 'package:perfyn_app/core/database/daos/goals_dao.dart';
import 'package:perfyn_app/core/database/app_database.dart';
import 'package:perfyn_app/core/network/sync_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' as drift;
import 'package:perfyn_app/features/goals/domain/entities/goal_record.dart';

class GoalRepository {
  const GoalRepository(this._client, this._dao, this._syncManager);

  final SupabaseClient _client;
  final GoalsDao _dao;
  final SyncManager _syncManager;

  Stream<List<GoalRecord>> watchGoals(String userId) {
    return _dao.watchAll(userId).map(
          (list) => list.map((e) => GoalRecord.fromDb(e)).toList(),
        );
  }

  Future<void> syncFromServer(String userId) async {
    final response = await _client.from('goals').select().eq('user_id', userId);
    for (final row in response) {
      final remoteId = row['id'] as String;
      
      final existingQuery = await (_dao.select(_dao.goalsTable)..where((g) => g.remoteId.equals(remoteId))).get();
      final existing = existingQuery.isNotEmpty ? existingQuery.first : null;

      final companion = GoalsTableCompanion(
        localId: existing != null ? drift.Value(existing.localId) : const drift.Value.absent(),
        remoteId: drift.Value(remoteId),
        userId: drift.Value(row['user_id'] as String),
        title: drift.Value(row['title'] as String),
        targetAmount: drift.Value((row['target_amount'] as num?)?.toDouble() ?? 0.0),
        currentAmount: drift.Value((row['current_amount'] as num?)?.toDouble() ?? 0.0),
        type: drift.Value(row['type'] as String),
        deadline: drift.Value(row['deadline'] != null ? DateTime.tryParse(row['deadline'] as String) : null),
        createdAt: drift.Value(DateTime.tryParse(row['created_at'] as String) ?? DateTime.now()),
        isSynced: const drift.Value(true),
        syncOperation: const drift.Value(null),
      );

      if (existing != null) {
        if (existing.syncOperation == null) {
          await _dao.updateLocal(companion);
        }
      } else {
        await _dao.insertLocal(companion);
      }
    }
  }

  Future<void> addGoal({
    required String userId,
    required String title,
    required double targetAmount,
    required GoalType type,
    DateTime? deadline,
  }) async {
    final localId = await _dao.insertLocal(GoalsTableCompanion.insert(
      userId: userId,
      title: title.trim(),
      targetAmount: drift.Value(targetAmount),
      currentAmount: const drift.Value(0.0),
      type: GoalRecord.goalTypeToString(type),
      deadline: drift.Value(deadline),
      isSynced: const drift.Value(false),
      syncOperation: const drift.Value('insert'),
    ));

    await _syncManager.enqueue(
      tableName: 'goals',
      operation: 'insert',
      recordLocalId: localId.toString(),
      payload: {
        'user_id': userId,
        'title': title.trim(),
        'target_amount': targetAmount,
        'current_amount': 0,
        'type': GoalRecord.goalTypeToString(type),
        'deadline': deadline != null ? _formatDate(deadline) : null,
      },
    );
  }

  Future<void> updateGoal({
    required int localId,
    required String? remoteId,
    required String userId,
    required String title,
    required double targetAmount,
    required GoalType type,
    DateTime? deadline,
  }) async {
    final existingQuery = await (_dao.select(_dao.goalsTable)..where((g) => g.localId.equals(localId))).get();
    if (existingQuery.isEmpty) return;
    final existing = existingQuery.first;

    await _dao.updateLocal(
      existing.copyWith(
        title: title.trim(),
        targetAmount: drift.Value(targetAmount),
        type: GoalRecord.goalTypeToString(type),
        deadline: drift.Value(deadline),
        isSynced: false,
        syncOperation: drift.Value(existing.syncOperation ?? 'update'),
      ).toCompanion(true),
    );

    await _syncManager.enqueue(
      tableName: 'goals',
      operation: 'update',
      recordLocalId: localId.toString(),
      payload: {
        if (remoteId != null) 'id': remoteId,
        'user_id': userId,
        'title': title.trim(),
        'target_amount': targetAmount,
        'type': GoalRecord.goalTypeToString(type),
        'deadline': deadline != null ? _formatDate(deadline) : null,
      },
    );
  }

  Future<void> updateGoalProgress({
    required int localId,
    required String? remoteId,
    required String userId,
    required double currentAmount,
  }) async {
    final existingQuery = await (_dao.select(_dao.goalsTable)..where((g) => g.localId.equals(localId))).get();
    if (existingQuery.isEmpty) return;
    final existing = existingQuery.first;

    await _dao.updateLocal(
      existing.copyWith(
        currentAmount: currentAmount,
        isSynced: false,
        syncOperation: drift.Value(existing.syncOperation ?? 'update'),
      ).toCompanion(true),
    );

    await _syncManager.enqueue(
      tableName: 'goals',
      operation: 'update',
      recordLocalId: localId.toString(),
      payload: {
        if (remoteId != null) 'id': remoteId,
        'user_id': userId,
        'current_amount': currentAmount,
      },
    );
  }

  Future<void> deleteGoal({
    required int localId,
    required String? remoteId,
    required String userId,
  }) async {
    if (remoteId != null) {
      await _dao.markForDeletion(localId);
      await _syncManager.enqueue(
        tableName: 'goals',
        operation: 'delete',
        recordLocalId: localId.toString(),
        payload: {
          'id': remoteId,
        },
      );
    } else {
      await _dao.deleteLocal(localId);
    }
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
