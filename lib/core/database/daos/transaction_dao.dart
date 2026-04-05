import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transaction_table.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [TransactionsTable])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {

  TransactionsDao(super.db);

  // watch all transactions — reactive, updates UI automatically
  Stream<List<TransactionsTableData>> watchAll(String userId) {
    return (select(transactionsTable)
      ..where((t) => t.userId.equals(userId))
      ..where((t) => t.syncOperation.isNotValue('delete'))
      ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .watch();
  }

  // get unsynced records — used by SyncManager
  Future<List<TransactionsTableData>> getUnsynced() {
    return (select(transactionsTable)
      ..where((t) => t.isSynced.equals(false)))
      .get();
  }

  // insert locally
  Future<int> insertLocal(TransactionsTableCompanion entry) {
    return into(transactionsTable).insert(entry);
  }

  // update locally
  Future<bool> updateLocal(TransactionsTableCompanion entry) {
    return update(transactionsTable).replace(entry);
  }

  // soft delete — mark for sync deletion, dont actually delete yet
  Future<void> markForDeletion(int localId) {
    return (update(transactionsTable)
      ..where((t) => t.localId.equals(localId)))
      .write(const TransactionsTableCompanion(
        syncOperation: Value('delete'),
        isSynced: Value(false),
      ));
  }

  // hard delete after confirmed sync
  Future<void> deleteLocal(int localId) {
    return (delete(transactionsTable)
      ..where((t) => t.localId.equals(localId)))
      .go();
  }

  // mark as synced after successful Supabase push
  Future<void> markSynced(int localId, String remoteId) {
    return (update(transactionsTable)
      ..where((t) => t.localId.equals(localId)))
      .write(TransactionsTableCompanion(
        isSynced: const Value(true),
        remoteId: Value(remoteId),
        syncOperation: const Value(null),
      ));
  }

  // filter by category
  Stream<List<TransactionsTableData>> watchByCategory(
      String userId, String category) {
    return (select(transactionsTable)
      ..where((t) => t.userId.equals(userId))
      ..where((t) => t.category.equals(category))
      ..where((t) => t.syncOperation.isNotValue('delete')))
      .watch();
  }
}