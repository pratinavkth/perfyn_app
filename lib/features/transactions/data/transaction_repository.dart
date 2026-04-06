import 'package:perfyn_app/core/database/daos/transaction_dao.dart';
import 'package:perfyn_app/core/database/app_database.dart';
import 'package:perfyn_app/core/network/sync_manager.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:drift/drift.dart' as drift;
import 'package:perfyn_app/features/transactions/domain/entities/transaction_record.dart';

class TransactionRepository {
  const TransactionRepository(this._client, this._dao, this._syncManager);

  final SupabaseClient _client;
  final TransactionsDao _dao;
  final SyncManager _syncManager;

  Future<void> addTransaction({
    required String userId,
    required double amount,
    required TransactionType type,
    required String category,
    required DateTime date,
    String? notes,
  }) async {
    final formattedDate = _formatDate(date);
    
    // 1. Save to local database
    final localId = await _dao.insertLocal(TransactionsTableCompanion.insert(
      userId: userId,
      amount: amount,
      type: type.name,
      category: category,
      date: date,
      notes: drift.Value(notes?.trim().isEmpty ?? true ? null : notes?.trim()),
      isSynced: const drift.Value(false),
      syncOperation: const drift.Value('insert'),
    ));

    // 2. Queue for upload when online
    await _syncManager.enqueue(
      tableName: 'transactions',
      operation: 'insert',
      recordLocalId: localId.toString(),
      payload: {
        'user_id': userId,
        'amount': amount,
        'type': type.name,
        'category': category,
        'date': formattedDate,
        'notes': notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      },
    );
  }

  Future<void> updateTransaction({
    required int localId,
    required String? remoteId,
    required String userId,
    required double amount,
    required TransactionType type,
    required String category,
    required DateTime date,
    String? notes,
  }) async {
    // Update local database immediately
    await _dao.updateLocal(TransactionsTableCompanion(
      localId: drift.Value(localId),
      remoteId: drift.Value(remoteId),
      userId: drift.Value(userId),
      amount: drift.Value(amount),
      type: drift.Value(type.name),
      category: drift.Value(category),
      date: drift.Value(date),
      notes: drift.Value(notes?.trim().isEmpty ?? true ? null : notes?.trim()),
      isSynced: const drift.Value(false),
      syncOperation: const drift.Value('update'),
    ));

    // Wait until it has a remoteId to push updates to Supabase, 
    // unless the queue processor is smart enough to coalesce missing remoteIds
    await _syncManager.enqueue(
      tableName: 'transactions',
      operation: 'update',
      recordLocalId: localId.toString(),
      payload: {
        if (remoteId != null) 'id': remoteId,
        'user_id': userId,
        'amount': amount,
        'type': type.name,
        'category': category,
        'date': _formatDate(date),
        'notes': notes?.trim().isEmpty ?? true ? null : notes?.trim(),
      },
    );
  }

  Future<void> deleteTransaction({
    required int localId,
    required String? remoteId,
    required String userId,
  }) async {
    if (remoteId != null) {
      // Soft delete locally — will be hard deleted when sync succeeds
      await _dao.markForDeletion(localId);
      await _syncManager.enqueue(
        tableName: 'transactions',
        operation: 'delete',
        recordLocalId: localId.toString(),
        payload: {
          'id': remoteId,
        },
      );
    } else {
      // Doesn't exist on server yet, so just destroy it locally
      await _dao.deleteLocal(localId);
    }
  }

  /// Observe the transactions natively from the local database
  Stream<List<TransactionRecord>> watchTransactions(String userId) {
    return _dao.watchAll(userId).map(
          (list) => list.map((e) => TransactionRecord.fromDb(e)).toList(),
        );
  }

  /// Download the latest data from server and apply it directly to our Drift tables
  Future<void> syncFromServer(String userId) async {
    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', userId);

    for (final row in response) {
      final remoteId = row['id'] as String;
      
      // Find existing by remoteId
      final existingQuery = await (_dao.select(_dao.transactionsTable)..where((t) => t.remoteId.equals(remoteId))).get();
      final existing = existingQuery.isNotEmpty ? existingQuery.first : null;

      final companion = TransactionsTableCompanion(
        localId: existing != null ? drift.Value(existing.localId) : const drift.Value.absent(),
        remoteId: drift.Value(remoteId),
        userId: drift.Value(row['user_id'] as String),
        amount: drift.Value((row['amount'] as num).toDouble()),
        type: drift.Value(row['type'] as String),
        category: drift.Value(row['category'] as String),
        date: drift.Value(DateTime.parse(row['date'] as String)),
        notes: drift.Value(row['notes'] as String?),
        createdAt: drift.Value(DateTime.parse(row['created_at'] as String)),
        isSynced: const drift.Value(true),
        syncOperation: const drift.Value(null),
      );

      if (existing != null) {
        if (existing.syncOperation == null) {
          // Only overwrite if we haven't mutated this record offline locally 
          await _dao.updateLocal(companion);
        }
      } else {
        await _dao.insertLocal(companion);
      }
    }
  }

  String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
