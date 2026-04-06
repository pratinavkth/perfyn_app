import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:perfyn_app/app/providers/app_providers.dart';
import '../database/app_database.dart';
import '../database/database_provider.dart';

final syncManagerProvider = Provider<SyncManager>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final client = ref.watch(supabaseClientProvider);
  return SyncManager(db: db, client: client);
});

class SyncManager {
  SyncManager({required this.db, required this.client});

  final AppDatabase db;
  final SupabaseClient client;

  // call this when connectivity is restored
  Future<void> flushQueue() async {
    final pending = await db.syncQueueDao.getPending();

    for (final item in pending) {
      try {
        final payload = jsonDecode(item.payload) as Map<String, dynamic>;

        switch (item.operation) {
          case 'insert':
            final result = await client.from(item.targetTable).insert(payload).select().single();
            final remoteId = result['id'] as String;
            if (item.targetTable == 'transactions') {
              await db.transactionsDao.markSynced(int.parse(item.recordLocalId), remoteId);
            } else if (item.targetTable == 'goals') {
              await db.goalsDao.markSynced(int.parse(item.recordLocalId), remoteId);
            }
            break;
          case 'update':
            final id = payload['id'] as String?;
            if (id != null) {
              // copy payload so we can remove 'id' if needed or just push
              final updatePayload = Map<String, dynamic>.from(payload)..remove('id');
              await client.from(item.targetTable).update(updatePayload).eq('id', id);
              
              if (item.targetTable == 'transactions') {
                await db.transactionsDao.markSynced(int.parse(item.recordLocalId), id);
              } else if (item.targetTable == 'goals') {
                await db.goalsDao.markSynced(int.parse(item.recordLocalId), id);
              }
            }
            break;
          case 'delete':
            final id = payload['id'] as String?;
            if (id != null) {
              await client.from(item.targetTable).delete().eq('id', id);
              if (item.targetTable == 'transactions') {
                await db.transactionsDao.deleteLocal(int.parse(item.recordLocalId));
              } else if (item.targetTable == 'goals') {
                await db.goalsDao.deleteLocal(int.parse(item.recordLocalId));
              }
            }
            break;
        }

        // success — remove from queue
        await db.syncQueueDao.remove(item.id);

      } catch (e) {
        // failed — leave in queue, try again next time
        print('Sync failed for item ${item.id}: $e');
      }
    }
  }

  // enqueue a mutation for later
  Future<void> enqueue({
    required String tableName,
    required String operation,
    required Map<String, dynamic> payload,
    required String recordLocalId,
  }) async {
    await db.syncQueueDao.enqueue(SyncQueueTableCompanion.insert(
      targetTable: tableName,
      operation: operation,
      payload: jsonEncode(payload),
      recordLocalId: recordLocalId,
    ));
  }
}