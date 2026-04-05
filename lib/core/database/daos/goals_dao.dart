import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/goals_table.dart';

part 'goals_dao.g.dart';

@DriftAccessor(tables: [GoalsTable])
class GoalsDao extends DatabaseAccessor<AppDatabase> with _$GoalsDaoMixin {
  GoalsDao(super.db);

  // watch all goals — reactive, updates UI automatically
  Stream<List<GoalsTableData>> watchAll(String userId) {
    return (select(goalsTable)
      ..where((g) => g.userId.equals(userId))
      ..where((g) => g.syncOperation.isNotValue('delete'))
      ..orderBy([(g) => OrderingTerm.desc(g.createdAt)]))
      .watch();
  }

  // get unsynced records
  Future<List<GoalsTableData>> getUnsynced() {
    return (select(goalsTable)..where((g) => g.isSynced.equals(false))).get();
  }

  // insert locally
  Future<int> insertLocal(GoalsTableCompanion entry) {
    return into(goalsTable).insert(entry);
  }

  // update locally
  Future<bool> updateLocal(GoalsTableCompanion entry) {
    return update(goalsTable).replace(entry);
  }

  // soft delete
  Future<void> markForDeletion(int localId) {
    return (update(goalsTable)..where((g) => g.localId.equals(localId)))
        .write(const GoalsTableCompanion(
      syncOperation: Value('delete'),
      isSynced: Value(false),
    ));
  }

  // hard delete
  Future<void> deleteLocal(int localId) {
    return (delete(goalsTable)..where((g) => g.localId.equals(localId))).go();
  }

  // mark as synced
  Future<void> markSynced(int localId, String remoteId) {
    return (update(goalsTable)..where((g) => g.localId.equals(localId)))
        .write(GoalsTableCompanion(
      isSynced: const Value(true),
      remoteId: Value(remoteId),
      syncOperation: const Value(null),
    ));
  }
}
