// lib/core/database/database_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../database/tables/test_table.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, 'app_database.db');

  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) async {
      await db.execute(TestTable.createTable());
    },
  );
});