class Task {
  final int? localId; // SQLite primary key
  final int? serverId; // Supabase ID
  final String title;
  final String description;
  final bool completed;
  final String userId;
  final DateTime createdAt;
  final bool isSynced;

  Task({
    this.localId,
    this.serverId,
    required this.title,
    this.description = '',
    this.completed = false,
    required this.userId,
    DateTime? createdAt,
    this.isSynced = false,
  }) : createdAt = createdAt ?? DateTime.now();

  // Untuk Supabase API
  Map<String, dynamic> toJson() {
    return {
      'id': serverId,
      'title': title,
      'description': description,
      'completed': completed,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      serverId: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      completed: json['completed'] as bool? ?? false,
      userId: json['user_id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isSynced: true, // Data dari server sudah tersinkron
    );
  }

  // Untuk SQLite
  Map<String, dynamic> toMap() {
    return {
      'localId': localId,
      'serverId': serverId,
      'title': title,
      'description': description,
      'completed': completed ? 1 : 0,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': isSynced ? 1 : 0,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      localId: map['localId'] as int?,
      serverId: map['serverId'] as int?,
      title: map['title'] as String,
      description: map['description'] as String? ?? '',
      completed: (map['completed'] as int) == 1,
      userId: map['userId'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      isSynced: (map['isSynced'] as int) == 1,
    );
  }

  Task copyWith({
    int? localId,
    int? serverId,
    String? title,
    String? description,
    bool? completed,
    String? userId,
    DateTime? createdAt,
    bool? isSynced,
  }) {
    return Task(
      localId: localId ?? this.localId,
      serverId: serverId ?? this.serverId,
      title: title ?? this.title,
      description: description ?? this.description,
      completed: completed ?? this.completed,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
