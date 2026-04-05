import 'package:drift/drift.dart';

class TransactionsTable extends Table {
  // local id — auto increment
  IntColumn get localId => integer().autoIncrement()();

  // remote supabase uuid — null until synced
  TextColumn get remoteId => text().nullable()();

  TextColumn get userId => text()();
  RealColumn get amount => real()();
  TextColumn get type => text()();       // 'income' | 'expense'
  TextColumn get category => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get notes => text().nullable()();

  // sync tracking
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get syncOperation => text().nullable()(); // 'insert' | 'update' | 'delete'

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}