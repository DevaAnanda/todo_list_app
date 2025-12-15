import 'package:flutter_test/flutter_test.dart';
import 'package:todo_list_app/models/task.dart';

void main() {
  // ===========================================
  // GROUP: toJson() - Supabase API format
  // ===========================================
  group('toJson()', () {
    test('should convert Task to JSON with all fields', () {
      // Arrange
      final createdAt = DateTime(2025, 1, 1, 10, 0, 0);
      final task = Task(
        localId: 5,
        serverId: 10,
        title: 'Test Task',
        description: 'Test Description',
        completed: true,
        userId: 'user123',
        createdAt: createdAt,
        isSynced: true,
      );

      // Act
      final json = task.toJson();

      // Assert
      expect(json['id'], 10); // serverId mapped to 'id'
      expect(json['title'], 'Test Task');
      expect(json['description'], 'Test Description');
      expect(json['completed'], true); // bool not int
      expect(json['user_id'], 'user123');
      expect(json['created_at'], createdAt.toIso8601String());
      expect(json.containsKey('localId'), false); // localId NOT sent to server
      expect(json.containsKey('isSynced'), false); // isSynced NOT sent to server
    });

    test('should handle null serverId in JSON', () {
      // Arrange
      final task = Task(
        title: 'New Task',
        userId: 'user123',
        serverId: null,
      );

      // Act
      final json = task.toJson();

      // Assert
      expect(json['id'], null);
    });

    test('should handle empty description', () {
      // Arrange
      final task = Task(
        title: 'Task',
        description: '',
        userId: 'user123',
      );

      // Act
      final json = task.toJson();

      // Assert
      expect(json['description'], '');
    });
  });

  // ===========================================
  // GROUP: fromJson() - Parse from Supabase
  // ===========================================
  group('fromJson()', () {
    test('should parse complete JSON correctly', () {
      // Arrange
      final json = {
        'id': 1,
        'title': 'Test Task',
        'description': 'Test Description',
        'completed': true,
        'user_id': 'user123',
        'created_at': '2025-01-01T10:00:00.000Z',
      };

      // Act
      final task = Task.fromJson(json);

      // Assert
      expect(task.serverId, 1); // 'id' mapped to serverId
      expect(task.title, 'Test Task');
      expect(task.description, 'Test Description');
      expect(task.completed, true);
      expect(task.userId, 'user123');
      expect(task.createdAt.year, 2025);
      expect(task.createdAt.month, 1);
      expect(task.createdAt.day, 1);
      expect(task.isSynced, true); // fromJson always sets isSynced = true
      expect(task.localId, null); // localId not in JSON
    });

    test('should handle missing optional fields with defaults', () {
      // Arrange
      final json = {
        'id': 2,
        'title': 'Minimal Task',
        'user_id': 'user123',
      };

      // Act
      final task = Task.fromJson(json);

      // Assert
      expect(task.serverId, 2);
      expect(task.title, 'Minimal Task');
      expect(task.description, ''); // default value
      expect(task.completed, false); // default value
      expect(task.userId, 'user123');
      expect(task.isSynced, true);
    });

    test('should handle null description', () {
      // Arrange
      final json = {
        'id': 3,
        'title': 'Task',
        'description': null,
        'user_id': 'user123',
      };

      // Act
      final task = Task.fromJson(json);

      // Assert
      expect(task.description, '');
    });

    test('should handle null completed', () {
      // Arrange
      final json = {
        'id': 4,
        'title': 'Task',
        'completed': null,
        'user_id': 'user123',
      };

      // Act
      final task = Task.fromJson(json);

      // Assert
      expect(task.completed, false);
    });

    test('should handle null created_at with current time', () {
      // Arrange
      final json = {
        'id': 5,
        'title': 'Task',
        'user_id': 'user123',
        'created_at': null,
      };

      // Act
      final before = DateTime.now();
      final task = Task.fromJson(json);
      final after = DateTime.now();

      // Assert
      expect(task.createdAt.isAfter(before.subtract(Duration(seconds: 1))), true);
      expect(task.createdAt.isBefore(after.add(Duration(seconds: 1))), true);
    });
  });

  // ===========================================
  // GROUP: toMap() - SQLite format
  // ===========================================
  group('toMap()', () {
    test('should convert Task to Map for SQLite', () {
      // Arrange
      final createdAt = DateTime(2025, 1, 15, 12, 30, 0);
      final task = Task(
        localId: 1,
        serverId: 10,
        title: 'Local Task',
        description: 'Description',
        completed: true,
        userId: 'user123',
        createdAt: createdAt,
        isSynced: false,
      );

      // Act
      final map = task.toMap();

      // Assert
      expect(map['localId'], 1);
      expect(map['serverId'], 10);
      expect(map['title'], 'Local Task');
      expect(map['description'], 'Description');
      expect(map['completed'], 1); // true → 1
      expect(map['userId'], 'user123');
      expect(map['createdAt'], createdAt.toIso8601String());
      expect(map['isSynced'], 0); // false → 0
    });

    test('should store completed as 0 when false', () {
      // Arrange
      final task = Task(
        title: 'Task',
        userId: 'user123',
        completed: false,
      );

      // Act
      final map = task.toMap();

      // Assert
      expect(map['completed'], 0);
    });

    test('should store isSynced as 1 when true', () {
      // Arrange
      final task = Task(
        title: 'Task',
        userId: 'user123',
        isSynced: true,
      );

      // Act
      final map = task.toMap();

      // Assert
      expect(map['isSynced'], 1);
    });

    test('should handle null localId and serverId', () {
      // Arrange
      final task = Task(
        localId: null,
        serverId: null,
        title: 'Task',
        userId: 'user123',
      );

      // Act
      final map = task.toMap();

      // Assert
      expect(map['localId'], null);
      expect(map['serverId'], null);
    });
  });

  // ===========================================
  // GROUP: fromMap() - Parse from SQLite
  // ===========================================
  group('fromMap()', () {
    test('should parse complete Map correctly', () {
      // Arrange
      final map = {
        'localId': 1,
        'serverId': 10,
        'title': 'SQLite Task',
        'description': 'Description',
        'completed': 1,
        'userId': 'user123',
        'createdAt': '2025-01-15T10:00:00.000Z',
        'isSynced': 0,
      };

      // Act
      final task = Task.fromMap(map);

      // Assert
      expect(task.localId, 1);
      expect(task.serverId, 10);
      expect(task.title, 'SQLite Task');
      expect(task.description, 'Description');
      expect(task.completed, true); // 1 → true
      expect(task.userId, 'user123');
      expect(task.createdAt.year, 2025);
      expect(task.isSynced, false); // 0 → false
    });

    test('should convert completed 0 to false', () {
      // Arrange
      final map = {
        'localId': 1,
        'title': 'Task',
        'completed': 0,
        'userId': 'user123',
        'createdAt': DateTime.now().toIso8601String(),
        'isSynced': 1,
      };

      // Act
      final task = Task.fromMap(map);

      // Assert
      expect(task.completed, false);
    });

    test('should convert isSynced 1 to true', () {
      // Arrange
      final map = {
        'localId': 1,
        'title': 'Task',
        'completed': 0,
        'userId': 'user123',
        'createdAt': DateTime.now().toIso8601String(),
        'isSynced': 1,
      };

      // Act
      final task = Task.fromMap(map);

      // Assert
      expect(task.isSynced, true);
    });

    test('should handle null description', () {
      // Arrange
      final map = {
        'localId': 1,
        'title': 'Task',
        'description': null,
        'completed': 0,
        'userId': 'user123',
        'createdAt': DateTime.now().toIso8601String(),
        'isSynced': 0,
      };

      // Act
      final task = Task.fromMap(map);

      // Assert
      expect(task.description, '');
    });

    test('should handle null localId and serverId', () {
      // Arrange
      final map = {
        'localId': null,
        'serverId': null,
        'title': 'Task',
        'completed': 0,
        'userId': 'user123',
        'createdAt': DateTime.now().toIso8601String(),
        'isSynced': 0,
      };

      // Act
      final task = Task.fromMap(map);

      // Assert
      expect(task.localId, null);
      expect(task.serverId, null);
    });
  });

  // ===========================================
  // GROUP: copyWith()
  // ===========================================
  group('copyWith()', () {
    test('should copy with updated fields only', () {
      // Arrange
      final original = Task(
        localId: 1,
        serverId: 10,
        title: 'Original',
        description: 'Desc',
        completed: false,
        userId: 'user123',
        isSynced: true,
      );

      // Act
      final updated = original.copyWith(
        title: 'Updated',
        completed: true,
      );

      // Assert
      expect(updated.localId, 1); // unchanged
      expect(updated.serverId, 10); // unchanged
      expect(updated.title, 'Updated'); // changed
      expect(updated.description, 'Desc'); // unchanged
      expect(updated.completed, true); // changed
      expect(updated.userId, 'user123'); // unchanged
      expect(updated.isSynced, true); // unchanged
    });

    test('should keep all fields when copyWith with no params', () {
      // Arrange
      final original = Task(
        localId: 1,
        serverId: 10,
        title: 'Task',
        description: 'Desc',
        completed: true,
        userId: 'user123',
        isSynced: false,
      );

      // Act
      final copy = original.copyWith();

      // Assert
      expect(copy.localId, original.localId);
      expect(copy.serverId, original.serverId);
      expect(copy.title, original.title);
      expect(copy.description, original.description);
      expect(copy.completed, original.completed);
      expect(copy.userId, original.userId);
      expect(copy.isSynced, original.isSynced);
    });

    test('should update localId and serverId', () {
      // Arrange
      final task = Task(
        localId: null,
        serverId: null,
        title: 'Task',
        userId: 'user123',
      );

      // Act
      final updated = task.copyWith(
        localId: 5,
        serverId: 50,
      );

      // Assert
      expect(updated.localId, 5);
      expect(updated.serverId, 50);
    });

    test('should update isSynced flag', () {
      // Arrange
      final task = Task(
        title: 'Task',
        userId: 'user123',
        isSynced: false,
      );

      // Act
      final synced = task.copyWith(isSynced: true);

      // Assert
      expect(synced.isSynced, true);
      expect(task.isSynced, false); // original unchanged
    });

    test('should update createdAt', () {
      // Arrange
      final oldDate = DateTime(2025, 1, 1);
      final newDate = DateTime(2025, 12, 15);
      final task = Task(
        title: 'Task',
        userId: 'user123',
        createdAt: oldDate,
      );

      // Act
      final updated = task.copyWith(createdAt: newDate);

      // Assert
      expect(updated.createdAt, newDate);
      expect(task.createdAt, oldDate); // original unchanged
    });
  });

  // ===========================================
  // GROUP: Edge Cases
  // ===========================================
  group('Edge Cases', () {
    test('should handle empty title (allowed by constructor)', () {
      // Arrange & Act
      final task = Task(
        title: '',
        userId: 'user123',
      );

      // Assert
      expect(task.title, '');
    });

    test('should roundtrip through toMap and fromMap', () {
      // Arrange
      final original = Task(
        localId: 1,
        serverId: 10,
        title: 'Roundtrip Task',
        description: 'Testing',
        completed: true,
        userId: 'user123',
        isSynced: false,
      );

      // Act
      final map = original.toMap();
      final restored = Task.fromMap(map);

      // Assert
      expect(restored.localId, original.localId);
      expect(restored.serverId, original.serverId);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.completed, original.completed);
      expect(restored.userId, original.userId);
      expect(restored.isSynced, original.isSynced);
    });

    test('should roundtrip through toJson and fromJson', () {
      // Arrange
      final original = Task(
        serverId: 20,
        title: 'API Task',
        description: 'Testing API',
        completed: false,
        userId: 'user456',
      );

      // Act
      final json = original.toJson();
      final restored = Task.fromJson(json);

      // Assert
      expect(restored.serverId, original.serverId);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.completed, original.completed);
      expect(restored.userId, original.userId);
      expect(restored.isSynced, true); // fromJson always sets true
    });

    test('should handle very long strings', () {
      // Arrange
      final longTitle = 'A' * 1000;
      final longDesc = 'B' * 5000;
      final task = Task(
        title: longTitle,
        description: longDesc,
        userId: 'user123',
      );

      // Act
      final json = task.toJson();
      final map = task.toMap();

      // Assert
      expect(json['title'], longTitle);
      expect(json['description'], longDesc);
      expect(map['title'], longTitle);
      expect(map['description'], longDesc);
    });
  });
}
