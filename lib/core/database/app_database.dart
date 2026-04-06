import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/transaction_table.dart';
import 'tables/goals_table.dart';
import 'tables/sync_queue_table.dart';
import 'daos/transaction_dao.dart';
import 'daos/goals_dao.dart';
import 'daos/sync_queue_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    TransactionsTable,
    GoalsTable,
    SyncQueueTable,
  ],
  daos: [
    TransactionsDao,
    GoalsDao,
    SyncQueueDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // run migrations here when you change tables later
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      // handle future schema changes here
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'finwise.db'));
    return NativeDatabase.createInBackground(file);
  });
}