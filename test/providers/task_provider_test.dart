import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todo_list_app/models/task.dart';
import 'package:todo_list_app/providers/task_provider.dart';
import 'package:todo_list_app/local/task_local_db.dart';
import 'package:todo_list_app/api/task_api.dart';

// ===========================================
// MOCK CLASSES
// ===========================================
class MockTaskApiService extends Mock implements TaskApiService {}

class MockTaskLocalDb extends Mock implements TaskLocalDb {}

// Fallback values untuk mocktail
class FakeTask extends Fake implements Task {}

void main() {
  late TaskProvider provider;
  late MockTaskApiService mockApi;
  late MockTaskLocalDb mockLocalDb;

  setUpAll(() {
    // Register fallback values
    registerFallbackValue(FakeTask());
  });

  setUp(() {
    mockApi = MockTaskApiService();
    mockLocalDb = MockTaskLocalDb();
    
    // Create provider with mocked dependencies
    provider = TaskProvider(
      localDb: mockLocalDb,
      api: mockApi,
    );
  });

  tearDown(() {
    provider.dispose();
  });

  // ===========================================
  // GROUP: Authentication Flow
  // ===========================================
  group('Authentication Flow', () {
    test('checkSession - should set authenticated when session exists', () async {
      // Arrange
      when(() => mockApi.loadSession()).thenAnswer(
        (_) async => {
          'success': true,
          'user': {'id': 'user123', 'email': 'test@example.com'},
        },
      );
      when(() => mockLocalDb.getAllTasks('user123')).thenAnswer((_) async => []);
      when(() => mockApi.getTasks('user123')).thenAnswer((_) async => []);
      when(() => mockLocalDb.replaceAllTasks(any(), 'user123')).thenAnswer((_) async => {});
      when(() => mockLocalDb.getUnsyncedTasks('user123')).thenAnswer((_) async => []);

      // Act
      await provider.checkSession();

      // Assert
      expect(provider.isAuthenticated, true);
      expect(provider.userId, 'user123');
      expect(provider.userEmail, 'test@example.com');
      expect(provider.isLoading, false);
      verify(() => mockApi.loadSession()).called(1);
    });

    test('checkSession - should remain unauthenticated when no session', () async {
      // Arrange
      when(() => mockApi.loadSession()).thenAnswer(
        (_) async => {'success': false, 'error': 'No session'},
      );

      // Act
      await provider.checkSession();

      // Assert
      expect(provider.isAuthenticated, false);
      expect(provider.userId, null);
      expect(provider.isLoading, false);
    });

    test('checkSession - should handle API error gracefully', () async {
      // Arrange
      when(() => mockApi.loadSession()).thenThrow(Exception('Network error'));

      // Act
      await provider.checkSession();

      // Assert
      expect(provider.isAuthenticated, false);
      expect(provider.error, isNotNull);
      expect(provider.error, contains('Session check failed'));
    });

    test('logout - should reset auth state and clear tasks', () async {
      // Arrange - Login first
      when(() => mockApi.login(any(), any())).thenAnswer(
        (_) async => {
          'success': true,
          'user': {'id': 'user123', 'email': 'test@example.com'},
        },
      );
      when(() => mockLocalDb.getAllTasks('user123')).thenAnswer((_) async => []);
      when(() => mockApi.getTasks('user123')).thenAnswer((_) async => []);
      when(() => mockLocalDb.replaceAllTasks(any(), 'user123')).thenAnswer((_) async => {});
      when(() => mockLocalDb.getUnsyncedTasks('user123')).thenAnswer((_) async => []);
      await provider.login('test@example.com', 'password');
      
      when(() => mockApi.logout()).thenAnswer((_) async => {});
      when(() => mockLocalDb.clearAll('user123')).thenAnswer((_) async => {});

      // Act
      await provider.logout();

      // Assert
      expect(provider.isAuthenticated, false);
      expect(provider.userId, null);
      expect(provider.userEmail, null);
      expect(provider.tasks, isEmpty);
      verify(() => mockApi.logout()).called(1);
    });
  });

  // ===========================================
  // GROUP: Load Tasks (Offline-First)
  // ===========================================
  group('Load Tasks - Offline First', () {
    final userId = 'user123';

    test('should use local data when API fails (offline mode)', () async {
      // Arrange - login first
      when(() => mockApi.login(any(), any())).thenAnswer(
        (_) async => {
          'success': true,
          'user': {'id': userId, 'email': 'test@example.com'},
        },
      );
      
      final localTasks = [
        Task(localId: 1, serverId: 1, title: 'Local Task 1', userId: userId, isSynced: true),
        Task(localId: 2, title: 'Unsynced Task', userId: userId, isSynced: false),
      ];
      
      when(() => mockLocalDb.getAllTasks(userId)).thenAnswer((_) async => localTasks);
      when(() => mockApi.getTasks(userId)).thenThrow(Exception('Network error'));
      
      await provider.login('test@example.com', 'password');

      // Assert
      expect(provider.tasks.length, localTasks.length);
      expect(provider.isOnline, false);
      expect(provider.isLoading, false);
    });
  });

  // ===========================================
  // GROUP: Add Task
  // ===========================================
  group('Add Task', () {
    final userId = 'user123';

    setUp(() async {
      // Login before each test
      when(() => mockApi.login(any(), any())).thenAnswer(
        (_) async => {
          'success': true,
          'user': {'id': userId, 'email': 'test@example.com'},
        },
      );
      when(() => mockLocalDb.getAllTasks(userId)).thenAnswer((_) async => []);
      when(() => mockApi.getTasks(userId)).thenAnswer((_) async => []);
      when(() => mockLocalDb.replaceAllTasks(any(), userId)).thenAnswer((_) async => {});
      when(() => mockLocalDb.getUnsyncedTasks(userId)).thenAnswer((_) async => []);
      await provider.login('test@example.com', 'password');
    });

    test('should add task to SQLite and update UI immediately', () async {
      // Arrange
      when(() => mockLocalDb.insert(any())).thenAnswer((_) async => 1);
      when(() => mockApi.createTask(any())).thenAnswer(
        (_) async => Task(serverId: 10, title: 'New Task', userId: userId, isSynced: true),
      );
      when(() => mockLocalDb.updateServerId(1, 10)).thenAnswer((_) async => {});
      
      // Mock loadTasks() called after successful API creation
      when(() => mockLocalDb.getAllTasks(userId)).thenAnswer((_) async => [
        Task(localId: 1, serverId: 10, title: 'New Task', userId: userId, isSynced: true),
      ]);
      when(() => mockApi.getTasks(userId)).thenAnswer((_) async => []);
      when(() => mockLocalDb.replaceAllTasks(any(), userId)).thenAnswer((_) async => {});
      when(() => mockLocalDb.getUnsyncedTasks(userId)).thenAnswer((_) async => []);

      // Act
      await provider.addTask('New Task', 'Description');

      // Assert
      expect(provider.tasks.isNotEmpty, true);
      expect(provider.tasks.first.title, 'New Task');
      verify(() => mockLocalDb.insert(any())).called(1);
    });

    test('should keep isSynced false when API fails', () async {
      // Arrange
      when(() => mockLocalDb.insert(any())).thenAnswer((_) async => 1);
      when(() => mockApi.createTask(any())).thenThrow(Exception('API error'));

      // Act
      await provider.addTask('Offline Task', '');

      // Assert
      expect(provider.tasks.first.isSynced, false);
      expect(provider.isOnline, false);
    });
  });

  // ===========================================
  // GROUP: State Management
  // ===========================================
  group('State Management', () {
    test('isLoading should be false initially', () {
      // Assert
      expect(provider.isLoading, false);
    });

    test('isOnline should be true initially', () {
      // Assert
      expect(provider.isOnline, true);
    });

    test('tasks should be empty initially', () {
      // Assert
      expect(provider.tasks, isEmpty);
    });

    test('should clear error messages', () {
      // Act
      provider.clearError();

      // Assert
      expect(provider.error, null);
    });
  });

  // ===========================================
  // GROUP: Edge Cases
  // ===========================================
  group('Edge Cases', () {
    test('should handle null userId gracefully', () async {
      // Act & Assert - should not throw
      await provider.loadTasks();
      expect(provider.tasks, isEmpty);
    });

    test('addTask should handle empty title gracefully', () async {
      // Arrange
      when(() => mockApi.login(any(), any())).thenAnswer(
        (_) async => {
          'success': true,
          'user': {'id': 'user123', 'email': 'test@example.com'},
        },
      );
      when(() => mockLocalDb.getAllTasks('user123')).thenAnswer((_) async => []);
      when(() => mockApi.getTasks('user123')).thenAnswer((_) async => []);
      when(() => mockLocalDb.replaceAllTasks(any(), 'user123')).thenAnswer((_) async => {});
      when(() => mockLocalDb.getUnsyncedTasks('user123')).thenAnswer((_) async => []);
      await provider.login('test@example.com', 'password');
      
      when(() => mockLocalDb.insert(any())).thenAnswer((_) async => 1);
      // Simulate offline mode by making API throw error
      when(() => mockApi.createTask(any())).thenThrow(Exception('Offline'));

      // Act
      await provider.addTask('', '');

      // Assert - task added locally even with empty title
      expect(provider.tasks.isNotEmpty, true);
      expect(provider.tasks.first.title, '');
      expect(provider.tasks.first.isSynced, false);
    });
  });
}
