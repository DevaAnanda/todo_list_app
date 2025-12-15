import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

/// Initialize sqflite for testing environment
void initTestDatabase() {
  // Initialize FFI
  sqfliteFfiInit();
  
  // Set the database factory for testing
  databaseFactory = databaseFactoryFfi;
}

/// Get a temporary database path for testing
Future<String> getTestDatabasePath(String dbName) async {
  final directory = Directory.systemTemp.createTempSync('test_db');
  return join(directory.path, dbName);
}

/// Delete test database file
Future<void> deleteTestDatabase(String path) async {
  final file = File(path);
  if (await file.exists()) {
    await file.delete();
  }
}

/// Clean up test database directory
Future<void> cleanupTestDatabases() async {
  final tempDir = Directory.systemTemp;
  await for (var entity in tempDir.list()) {
    if (entity is Directory && entity.path.contains('test_db')) {
      try {
        await entity.delete(recursive: true);
      } catch (e) {
        // Ignore errors during cleanup
      }
    }
  }
}
