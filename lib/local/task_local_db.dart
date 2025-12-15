import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class TaskLocalDb {
  static Database? _database;
  static const String _tableName = 'tasks';

  // Singleton pattern
  TaskLocalDb._();
  static final TaskLocalDb instance = TaskLocalDb._();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'tasks.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTable,
    );
  }

  Future<void> _createTable(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        localId INTEGER PRIMARY KEY AUTOINCREMENT,
        serverId INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        completed INTEGER NOT NULL DEFAULT 0,
        userId TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        isSynced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // Insert task
  Future<int> insert(Task task) async {
    final db = await database;
    final map = task.toMap();
    map.remove('localId'); // Auto-increment akan handle ini
    return await db.insert(_tableName, map);
  }

  // Update task
  Future<int> update(Task task) async {
    final db = await database;
    return await db.update(
      _tableName,
      task.toMap(),
      where: 'localId = ?',
      whereArgs: [task.localId],
    );
  }

  // Delete task by localId
  Future<int> delete(int localId) async {
    final db = await database;
    return await db.delete(
      _tableName,
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }

  // Get all tasks for a user
  Future<List<Task>> getAllTasks(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  // Get unsynced tasks (untuk sinkronisasi)
  Future<List<Task>> getUnsyncedTasks(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: 'userId = ? AND isSynced = 0',
      whereArgs: [userId],
    );
    return maps.map((map) => Task.fromMap(map)).toList();
  }

  // Replace all tasks (untuk sync dari server)
  Future<void> replaceAllTasks(List<Task> tasks, String userId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Hapus task yang sudah tersinkron
      await txn.delete(
        _tableName,
        where: 'userId = ? AND isSynced = 1',
        whereArgs: [userId],
      );
      // Insert semua task baru dari server
      for (var task in tasks) {
        await txn.insert(_tableName, task.toMap());
      }
    });
  }

  // Clear all tasks for a user
  Future<void> clearAll(String userId) async {
    final db = await database;
    await db.delete(
      _tableName,
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }

  // Update serverId setelah sync berhasil
  Future<void> updateServerId(int localId, int serverId) async {
    final db = await database;
    await db.update(
      _tableName,
      {'serverId': serverId, 'isSynced': 1},
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }

  // Mark task as synced
  Future<void> markAsSynced(int localId) async {
    final db = await database;
    await db.update(
      _tableName,
      {'isSynced': 1},
      where: 'localId = ?',
      whereArgs: [localId],
    );
  }
}
