import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';

// single instance shared across whole app
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});