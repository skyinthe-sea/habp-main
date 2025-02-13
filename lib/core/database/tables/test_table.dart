class TestTable {
  static const String tableName = 'test';
  static const String columnId = 'id';
  static const String columnData = 'data';
  static const String columnCreatedAt = 'created_at';

  static String createTable() {
    return '''
      CREATE TABLE $tableName (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnData TEXT NOT NULL,
        $columnCreatedAt TEXT NOT NULL
      )
    ''';
  }
}