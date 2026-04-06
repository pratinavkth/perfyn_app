import 'package:drift/drift.dart';

class SyncQueueTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetTable => text()();    // 'transactions' | 'goals'
  TextColumn get operation => text()();    // 'insert' | 'update' | 'delete'
  TextColumn get payload => text()();      // JSON string of the record
  TextColumn get recordLocalId => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}