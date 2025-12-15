import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../local/task_local_db.dart';
import '../api/task_api.dart';

class TaskProvider with ChangeNotifier {
  final TaskLocalDb _localDb;
  final TaskApiService _api;

  TaskProvider({
    TaskLocalDb? localDb,
    TaskApiService? api,
  })  : _localDb = localDb ?? TaskLocalDb.instance,
        _api = api ?? TaskApiService();

  // Auth state
  bool _isAuthenticated = false;
  String? _userId;
  String? _userEmail;
  
  // Task state
  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;
  bool _isOnline = true;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isOnline => _isOnline;
  
  int get unsyncedCount => _tasks.where((t) => !t.isSynced).length;

  // ========================
  // AUTHENTICATION
  // ========================

  Future<void> checkSession() async {
    _setLoading(true);
    
    try {
      final result = await _api.loadSession();
      
      if (result['success']) {
        _userId = result['user']['id'];
        _userEmail = result['user']['email'];
        _isAuthenticated = true;
        await loadTasks();
      }
    } catch (e) {
      _setError('Session check failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _api.login(email, password);
      
      if (result['success']) {
        _userId = result['user']['id'];
        _userEmail = result['user']['email'];
        _isAuthenticated = true;
        await loadTasks();
        _setLoading(false);
        return true;
      } else {
        _setError(result['error']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Login failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await _api.register(email, password);
      
      if (result['success']) {
        _userId = result['user']['id'];
        _userEmail = result['user']['email'];
        _isAuthenticated = true;
        _setLoading(false);
        return true;
      } else {
        _setError(result['error']);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Registration failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    await _api.logout();
    if (_userId != null) {
      await _localDb.clearAll(_userId!);
    }
    _isAuthenticated = false;
    _userId = null;
    _userEmail = null;
    _tasks = [];
    notifyListeners();
  }

  // ========================
  // TASK CRUD (OFFLINE-FIRST)
  // ========================

  Future<void> loadTasks() async {
    if (_userId == null) return;

    _setLoading(true);
    
    // 1. Load dari SQLite dulu (offline-first)
    try {
      _tasks = await _localDb.getAllTasks(_userId!);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load local tasks: $e');
    }

    // 2. Coba sync dengan server jika online
    await syncWithServer();
    
    _setLoading(false);
  }

  Future<void> syncWithServer() async {
    if (_userId == null) return;

    try {
      // Get tasks dari server
      final serverTasks = await _api.getTasks(_userId!);
      
      // Server reachable, kita online
      _isOnline = true;
      
      // Replace tasks yang sudah synced dengan data dari server
      await _localDb.replaceAllTasks(serverTasks, _userId!);
      
      // Sync unsynced tasks ke server
      final unsyncedTasks = await _localDb.getUnsyncedTasks(_userId!);
      
      for (var task in unsyncedTasks) {
        try {
          if (task.serverId == null) {
            // Task baru, create di server
            final createdTask = await _api.createTask(task);
            if (createdTask != null && task.localId != null) {
              await _localDb.updateServerId(task.localId!, createdTask.serverId!);
            }
          } else {
            // Task sudah ada di server, update
            await _api.updateTask(task);
            if (task.localId != null) {
              await _localDb.markAsSynced(task.localId!);
            }
          }
        } catch (e) {
          print('Failed to sync task ${task.localId}: $e');
        }
      }
      
      // Reload dari local setelah sync
      _tasks = await _localDb.getAllTasks(_userId!);
      notifyListeners();
      
    } catch (e) {
      // Server tidak reachable, kita offline
      _isOnline = false;
      print('Sync failed (offline): $e');
    }
  }

  Future<void> addTask(String title, String description) async {
    if (_userId == null) return;

    final task = Task(
      title: title,
      description: description,
      userId: _userId!,
      isSynced: false,
    );

    try {
      // Save ke SQLite dulu (offline-first)
      final localId = await _localDb.insert(task);
      final savedTask = task.copyWith(localId: localId);
      
      // Update UI
      _tasks.insert(0, savedTask);
      notifyListeners();

      // Coba sync ke server jika online
      if (_isOnline) {
        try {
          final createdTask = await _api.createTask(savedTask);
          if (createdTask != null) {
            await _localDb.updateServerId(localId, createdTask.serverId!);
            // Reload untuk update isSynced
            await loadTasks();
          }
        } catch (e) {
          print('Failed to sync new task to server: $e');
          _isOnline = false;
        }
      }
    } catch (e) {
      _setError('Failed to add task: $e');
    }
  }

  Future<void> toggleTask(Task task) async {
    if (_userId == null || task.localId == null) return;

    try {
      // Update di SQLite
      final updatedTask = task.copyWith(
        completed: !task.completed,
        isSynced: false, // Mark as unsynced
      );
      
      await _localDb.update(updatedTask);
      
      // Update UI
      final index = _tasks.indexWhere((t) => t.localId == task.localId);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }

      // Coba sync ke server jika online
      if (_isOnline && task.serverId != null) {
        try {
          await _api.updateTask(updatedTask);
          await _localDb.markAsSynced(task.localId!);
          await loadTasks();
        } catch (e) {
          print('Failed to sync toggle to server: $e');
          _isOnline = false;
        }
      }
    } catch (e) {
      _setError('Failed to toggle task: $e');
    }
  }

  Future<void> updateTask(Task task, String title, String description) async {
    if (_userId == null || task.localId == null) return;

    try {
      // Update di SQLite
      final updatedTask = task.copyWith(
        title: title,
        description: description,
        isSynced: false,
      );
      
      await _localDb.update(updatedTask);
      
      // Update UI
      final index = _tasks.indexWhere((t) => t.localId == task.localId);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }

      // Coba sync ke server jika online
      if (_isOnline && task.serverId != null) {
        try {
          await _api.updateTask(updatedTask);
          await _localDb.markAsSynced(task.localId!);
          await loadTasks();
        } catch (e) {
          print('Failed to sync update to server: $e');
          _isOnline = false;
        }
      }
    } catch (e) {
      _setError('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(Task task) async {
    if (_userId == null || task.localId == null) return;

    try {
      // Delete dari SQLite
      await _localDb.delete(task.localId!);
      
      // Update UI
      _tasks.removeWhere((t) => t.localId == task.localId);
      notifyListeners();

      // Coba delete dari server jika online dan ada serverId
      if (_isOnline && task.serverId != null) {
        try {
          await _api.deleteTask(task.serverId!);
        } catch (e) {
          print('Failed to delete from server: $e');
          _isOnline = false;
        }
      }
    } catch (e) {
      _setError('Failed to delete task: $e');
    }
  }

  // ========================
  // HELPER METHODS
  // ========================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}
