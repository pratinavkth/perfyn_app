import 'package:drift/drift.dart';

class GoalsTable extends Table {
  IntColumn get localId => integer().autoIncrement()();
  TextColumn get remoteId => text().nullable()();
  TextColumn get userId => text()();
  TextColumn get title => text()();
  TextColumn get type => text()();
  RealColumn get targetAmount => real().nullable()();
  RealColumn get currentAmount => real().withDefault(const Constant(0.0))();
  TextColumn get category => text().nullable()();
  DateTimeColumn get deadline => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  TextColumn get syncOperation => text().nullable()(); // 'insert' | 'update' | 'delete'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}