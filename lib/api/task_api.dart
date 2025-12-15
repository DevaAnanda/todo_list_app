import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class TaskApiService {
  // Ganti dengan URL Supabase Anda
  static const String supabaseUrl = 'https://xpnszatvvwzjtnxpgnzn.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhwbnN6YXR2dnd6anRueHBnbnpuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ4NDI4MzQsImV4cCI6MjA4MDQxODgzNH0.v8l89T6AGE8PeMSMuG7gRbKtAeZF7gsfyp4C3k9jzLQ';
  
  String? _accessToken;

  // ========================
  // AUTHENTICATION
  // ========================

  Future<Map<String, dynamic>> register(String email, String password) async {
    final url = Uri.parse('$supabaseUrl/auth/v1/signup');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'apikey': supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        await _saveToken(_accessToken!);
        return {'success': true, 'user': data['user']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error_description'] ?? 'Registration failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$supabaseUrl/auth/v1/token?grant_type=password');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'apikey': supabaseAnonKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        await _saveToken(_accessToken!);
        return {'success': true, 'user': data['user']};
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'error': error['error_description'] ?? 'Login failed'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    if (token == null) {
      return {'success': false, 'error': 'No saved session'};
    }

    _accessToken = token;
    
    // Verify token dengan mengambil user info
    final url = Uri.parse('$supabaseUrl/auth/v1/user');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final user = jsonDecode(response.body);
        return {'success': true, 'user': user};
      } else {
        await _clearToken();
        return {'success': false, 'error': 'Invalid session'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> logout() async {
    await _clearToken();
    _accessToken = null;
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // ========================
  // TASK CRUD
  // ========================

  Future<List<Task>> getTasks(String userId) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse('$supabaseUrl/rest/v1/tasks?user_id=eq.$userId&order=created_at.desc');
    
    try {
      final response = await http.get(
        url,
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading tasks: $e');
    }
  }

  Future<Task?> createTask(Task task) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse('$supabaseUrl/rest/v1/tasks');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'title': task.title,
          'description': task.description,
          'completed': task.completed,
          'user_id': task.userId,
        }),
      );

      if (response.statusCode == 201) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return Task.fromJson(data[0]);
        }
      }
      throw Exception('Failed to create task: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  Future<Task?> updateTask(Task task) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated');
    }

    if (task.serverId == null) {
      throw Exception('Cannot update task without serverId');
    }

    final url = Uri.parse('$supabaseUrl/rest/v1/tasks?id=eq.${task.serverId}');
    
    try {
      final response = await http.patch(
        url,
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $_accessToken',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation',
        },
        body: jsonEncode({
          'title': task.title,
          'description': task.description,
          'completed': task.completed,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return Task.fromJson(data[0]);
        }
      }
      throw Exception('Failed to update task: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error updating task: $e');
    }
  }

  Future<void> deleteTask(int serverId) async {
    if (_accessToken == null) {
      throw Exception('Not authenticated');
    }

    final url = Uri.parse('$supabaseUrl/rest/v1/tasks?id=eq.$serverId');
    
    try {
      final response = await http.delete(
        url,
        headers: {
          'apikey': supabaseAnonKey,
          'Authorization': 'Bearer $_accessToken',
        },
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete task: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting task: $e');
    }
  }
}
