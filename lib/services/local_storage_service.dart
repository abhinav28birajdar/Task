import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../data/models/task_model.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  late Database _database;
  late SharedPreferences _prefs;

  factory LocalStorageService() {
    return _instance;
  }

  LocalStorageService._internal();

  /// Initialize local storage
  Future<void> initialize() async {
    // Initialize SharedPreferences
    _prefs = await SharedPreferences.getInstance();

    // Initialize SQLite
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'task_app.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  /// Create database tables
  Future<void> _createTables(Database db, int version) async {
    // Tasks table
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT,
        priority TEXT,
        isCompleted INTEGER DEFAULT 0,
        dueDate TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        syncedAt TEXT,
        synced INTEGER DEFAULT 0,
        deleted INTEGER DEFAULT 0,
        data TEXT
      )
    ''');

    // Notes table
    await db.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        title TEXT,
        content TEXT,
        color TEXT,
        isArchived INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        syncedAt TEXT,
        synced INTEGER DEFAULT 0,
        deleted INTEGER DEFAULT 0,
        data TEXT
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        collectionName TEXT NOT NULL,
        documentId TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        retryCount INTEGER DEFAULT 0,
        maxRetries INTEGER DEFAULT 5
      )
    ''');

    // User settings table
    await db.execute('''
      CREATE TABLE user_settings (
        userId TEXT PRIMARY KEY,
        theme TEXT,
        notificationsEnabled INTEGER DEFAULT 1,
        biometricEnabled INTEGER DEFAULT 0,
        lastSyncedAt TEXT,
        data TEXT
      )
    ''');
  }

  Future<void> _upgradeTables(
      Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
  }

  // ==================== TASKS ====================

  /// Save task locally
  Future<void> saveTaskLocally(TaskModel task, String userId) async {
    await _database.insert(
      'tasks',
      {
        'id': task.id,
        'userId': userId,
        'title': task.title,
        'description': task.description,
        'category': task.category,
        'priority': task.priority,
        'isCompleted': task.isCompleted ? 1 : 0,
        'dueDate': task.dueDate?.toIso8601String(),
        'createdAt': task.createdAt.toIso8601String(),
        'updatedAt': task.updatedAt.toIso8601String(),
        'synced': 0,
        'data': jsonEncode(task.toMap()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all tasks for user (offline)
  Future<List<TaskModel>> getTasksLocally(String userId) async {
    final result = await _database.query(
      'tasks',
      where: 'userId = ? AND deleted = 0',
      whereArgs: [userId],
    );

    return result.map((map) {
      final jsonData = jsonDecode(map['data'] as String);
      return TaskModel.fromMap(jsonData);
    }).toList();
  }

  /// Get specific task
  Future<TaskModel?> getTaskLocally(String taskId) async {
    final result = await _database.query(
      'tasks',
      where: 'id = ? AND deleted = 0',
      whereArgs: [taskId],
      limit: 1,
    );

    if (result.isEmpty) return null;

    final jsonData = jsonDecode(result.first['data'] as String);
    return TaskModel.fromMap(jsonData);
  }

  /// Update task locally
  Future<void> updateTaskLocally(TaskModel task, String userId) async {
    await _database.update(
      'tasks',
      {
        'title': task.title,
        'description': task.description,
        'category': task.category,
        'priority': task.priority,
        'isCompleted': task.isCompleted ? 1 : 0,
        'dueDate': task.dueDate?.toIso8601String(),
        'updatedAt': task.updatedAt.toIso8601String(),
        'synced': 0,
        'data': jsonEncode(task.toMap()),
      },
      where: 'id = ? AND userId = ?',
      whereArgs: [task.id, userId],
    );
  }

  /// Delete task locally (soft delete)
  Future<void> deleteTaskLocally(String taskId, String userId) async {
    await _database.update(
      'tasks',
      {'deleted': 1, 'synced': 0},
      where: 'id = ? AND userId = ?',
      whereArgs: [taskId, userId],
    );
  }

  /// Get unsynced tasks
  Future<List<Map>> getUnsyncedTasks(String userId) async {
    final result = await _database.query(
      'tasks',
      where: 'userId = ? AND synced = 0',
      whereArgs: [userId],
    );
    return result;
  }

  /// Mark task as synced
  Future<void> markTaskSynced(String taskId) async {
    await _database.update(
      'tasks',
      {'synced': 1, 'syncedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // ==================== NOTES ====================

  /// Save note locally
  Future<void> saveNoteLocally(Map<String, dynamic> note, String userId) async {
    await _database.insert(
      'notes',
      {
        'id': note['id'],
        'userId': userId,
        'title': note['title'],
        'content': note['content'],
        'color': note['color'],
        'isArchived': (note['isArchived'] ?? false) ? 1 : 0,
        'createdAt': note['createdAt']?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'updatedAt': note['updatedAt']?.toIso8601String() ??
            DateTime.now().toIso8601String(),
        'synced': 0,
        'data': jsonEncode(note),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all notes for user
  Future<List<Map>> getNotesLocally(String userId) async {
    final result = await _database.query(
      'notes',
      where: 'userId = ? AND deleted = 0',
      whereArgs: [userId],
    );
    return result;
  }

  /// Update note locally
  Future<void> updateNoteLocally(
      Map<String, dynamic> note, String userId) async {
    await _database.update(
      'notes',
      {
        'title': note['title'],
        'content': note['content'],
        'color': note['color'],
        'isArchived': (note['isArchived'] ?? false) ? 1 : 0,
        'updatedAt': DateTime.now().toIso8601String(),
        'synced': 0,
        'data': jsonEncode(note),
      },
      where: 'id = ? AND userId = ?',
      whereArgs: [note['id'], userId],
    );
  }

  /// Delete note locally
  Future<void> deleteNoteLocally(String noteId) async {
    await _database.update(
      'notes',
      {'deleted': 1, 'synced': 0},
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  // ==================== SYNC QUEUE ====================

  /// Add operation to sync queue
  Future<void> addToSyncQueue({
    required String userId,
    required String collectionName,
    required String documentId,
    required String operation,
    required Map<String, dynamic> data,
  }) async {
    await _database.insert(
      'sync_queue',
      {
        'userId': userId,
        'collectionName': collectionName,
        'documentId': documentId,
        'operation': operation,
        'data': jsonEncode(data),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get pending sync operations
  Future<List<Map>> getPendingSyncOperations(String userId) async {
    return await _database.query(
      'sync_queue',
      where: 'userId = ? AND retryCount < maxRetries',
      whereArgs: [userId],
      orderBy: 'timestamp ASC',
    );
  }

  /// Mark sync operation as complete
  Future<void> markSyncComplete(int syncId) async {
    await _database.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [syncId],
    );
  }

  /// Increment retry count
  Future<void> incrementRetry(int syncId) async {
    await _database.execute(
      'UPDATE sync_queue SET retryCount = retryCount + 1 WHERE id = ?',
      [syncId],
    );
  }

  // ==================== USER SETTINGS ====================

  /// Save user settings locally
  Future<void> saveUserSettingsLocally(
      String userId, Map<String, dynamic> settings) async {
    await _database.insert(
      'user_settings',
      {
        'userId': userId,
        'theme': settings['theme'],
        'notificationsEnabled':
            (settings['notificationsEnabled'] ?? true) ? 1 : 0,
        'biometricEnabled': (settings['biometricEnabled'] ?? false) ? 1 : 0,
        'lastSyncedAt': DateTime.now().toIso8601String(),
        'data': jsonEncode(settings),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get user settings locally
  Future<Map<String, dynamic>?> getUserSettingsLocally(String userId) async {
    final result = await _database.query(
      'user_settings',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return jsonDecode(result.first['data'] as String);
  }

  // ==================== SHARED PREFERENCES ====================

  /// Save last offline sync time
  Future<void> saveLastSyncTime(String userId) async {
    await _prefs.setString(
        'last_sync_$userId', DateTime.now().toIso8601String());
  }

  /// Get last offline sync time
  String? getLastSyncTime(String userId) {
    return _prefs.getString('last_sync_$userId');
  }

  /// Check if offline mode is active
  Future<bool> isOfflineMode() async {
    // This will be determined by connectivity provider
    final lastSync = _prefs.getString('last_offline_check');
    return lastSync != null;
  }

  /// Set offline mode
  Future<void> setOfflineMode(bool isOffline) async {
    if (isOffline) {
      await _prefs.setString(
          'last_offline_check', DateTime.now().toIso8601String());
    } else {
      await _prefs.remove('last_offline_check');
    }
  }

  /// Clear all local data (for logout)
  Future<void> clearAllLocalData(String userId) async {
    await _database.delete('tasks', where: 'userId = ?', whereArgs: [userId]);
    await _database.delete('notes', where: 'userId = ?', whereArgs: [userId]);
    await _database
        .delete('sync_queue', where: 'userId = ?', whereArgs: [userId]);
    await _database
        .delete('user_settings', where: 'userId = ?', whereArgs: [userId]);
    await _prefs.remove('last_sync_$userId');
  }

  /// Get database size
  Future<int> getDatabaseSize() async {
    final result = await _database.rawQuery(
        'SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size();');
    return result.isNotEmpty ? (result.first['size'] as int) : 0;
  }

  /// Dispose database
  Future<void> dispose() async {
    await _database.close();
  }
}
