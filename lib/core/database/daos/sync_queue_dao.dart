import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sync_queue_table.dart';

part 'sync_queue_dao.g.dart';

@DriftAccessor(tables: [SyncQueueTable])
class SyncQueueDao extends DatabaseAccessor<AppDatabase>
    with _$SyncQueueDaoMixin {

  SyncQueueDao(super.db);

  Future<List<SyncQueueTableData>> getPending() {
    return (select(syncQueueTable)
      ..orderBy([(s) => OrderingTerm.asc(s.createdAt)]))
      .get();
  }

  Future<int> enqueue(SyncQueueTableCompanion entry) {
    return into(syncQueueTable).insert(entry);
  }

  Future<void> remove(int id) {
    return (delete(syncQueueTable)
      ..where((s) => s.id.equals(id)))
      .go();
  }

  Future<void> clearAll() => delete(syncQueueTable).go();
}