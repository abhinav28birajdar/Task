import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/task_model.dart';

enum SyncStatus { synced, syncing, pending, error, offline }

class SyncItem {
  final String id;
  final String taskId;
  final String operation; // 'create', 'update', 'delete'
  final TaskModel? data;
  final DateTime createdAt;
  final int retries;

  SyncItem({
    required this.id,
    required this.taskId,
    required this.operation,
    this.data,
    required this.createdAt,
    this.retries = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'operation': operation,
        'data': data?.toMap(),
        'createdAt': createdAt.toIso8601String(),
        'retries': retries,
      };

  factory SyncItem.fromJson(Map<String, dynamic> json) => SyncItem(
        id: json['id'] as String,
        taskId: json['taskId'] as String,
        operation: json['operation'] as String,
        data: json['data'] != null ? TaskModel.fromMap(json['data']) : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        retries: json['retries'] as int? ?? 0,
      );
}

class SyncService extends ChangeNotifier {
  static final SyncService _instance = SyncService._internal();

  factory SyncService() {
    return _instance;
  }

  SyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  SyncStatus _status = SyncStatus.synced;
  int _pendingItems = 0;
  DateTime? _lastSyncTime;
  String? _errorMessage;
  bool _isOnline = true;

  StreamSubscription? _connectivitySubscription;
  StreamSubscription? _syncSubscription;

  // Getters
  SyncStatus get status => _status;
  int get pendingItems => _pendingItems;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    debugPrint('🔄 Initializing SyncService...');

    // Monitor connectivity
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (result) {
        // result is now List<ConnectivityResult>
        final hasConnection = !result.contains(ConnectivityResult.none);
        _handleConnectivityChange(hasConnection);
      },
    );

    // Initial connectivity check
    final result = await _connectivity.checkConnectivity();
    // result is now List<ConnectivityResult>
    final hasConnection = !result.contains(ConnectivityResult.none);
    _handleConnectivityChange(hasConnection);

    debugPrint('✅ SyncService initialized');
  }

  void _handleConnectivityChange(bool isOnline) {
    final wasOnline = _isOnline;
    _isOnline = isOnline;

    if (_isOnline && !wasOnline) {
      debugPrint('📡 Network connection restored');
      _performSync();
    } else if (!_isOnline && wasOnline) {
      debugPrint('⚠️ Network connection lost');
      _status = SyncStatus.offline;
      notifyListeners();
    }
  }

  /// Add task to sync queue
  Future<void> addToQueue({
    required String taskId,
    required String operation,
    required TaskModel data,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getStringList('sync_queue') ?? [];

      final item = SyncItem(
        id: '${DateTime.now().millisecondsSinceEpoch}_$taskId',
        taskId: taskId,
        operation: operation,
        data: data,
        createdAt: DateTime.now(),
      );

      queueJson.add(item.toJson().toString());
      await prefs.setStringList('sync_queue', queueJson);

      _pendingItems = queueJson.length;
      _status = SyncStatus.pending;
      notifyListeners();

      debugPrint('📋 Task added to sync queue: $operation - $taskId');

      // Auto-sync if online
      if (_isOnline) {
        await Future.delayed(const Duration(seconds: 2));
        _performSync();
      }
    } catch (e) {
      debugPrint('❌ Error adding to queue: $e');
      _errorMessage = 'Failed to queue task for sync';
      notifyListeners();
    }
  }

  /// Perform synchronization
  Future<void> _performSync() async {
    if (!_isOnline) {
      debugPrint('⚠️ Cannot sync - no network connection');
      return;
    }

    if (_status == SyncStatus.syncing) {
      return; // Already syncing
    }

    _status = SyncStatus.syncing;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getStringList('sync_queue') ?? [];

      if (queueJson.isEmpty) {
        _status = SyncStatus.synced;
        _lastSyncTime = DateTime.now();
        notifyListeners();
        debugPrint('✅ Sync complete - no pending items');
        return;
      }

      debugPrint('🔄 Syncing ${queueJson.length} items...');

      int successCount = 0;
      final failedItems = <String>[];

      for (int i = 0; i < queueJson.length; i++) {
        try {
          // Parse sync item (handle both JSON string and map)
          final itemData = queueJson[i];
          final Map<String, dynamic> itemMap = _parseJson(itemData);
          final item = SyncItem.fromJson(itemMap);

          // Execute sync operation
          await _executeSyncOperation(item);
          successCount++;

          // Remove from queue
          queueJson.removeAt(i);
          i--;
        } catch (e) {
          debugPrint('❌ Sync failed for item $i: $e');
          failedItems.add(queueJson[i]);
        }
      }

      // Update queue
      await prefs.setStringList('sync_queue', queueJson);
      _pendingItems = queueJson.length;

      if (failedItems.isEmpty) {
        _status = SyncStatus.synced;
        _errorMessage = null;
        _lastSyncTime = DateTime.now();
        debugPrint('✅ All items synced successfully ($successCount items)');
      } else {
        _status = SyncStatus.pending;
        _errorMessage = 'Failed to sync ${failedItems.length} items';
        debugPrint('⚠️ Partial sync - ${failedItems.length} items failed');
      }
    } catch (e) {
      _status = SyncStatus.error;
      _errorMessage = 'Sync error: $e';
      debugPrint('❌ Sync error: $e');
    }

    notifyListeners();
  }

  /// Execute individual sync operation
  Future<void> _executeSyncOperation(SyncItem item) async {
    final userId =
        _firestore.app.options.projectId; // Placeholder - use actual userId

    switch (item.operation) {
      case 'create':
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .doc(item.taskId)
            .set(item.data?.toMap() ?? {});
        break;

      case 'update':
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .doc(item.taskId)
            .update(item.data?.toMap() ?? {});
        break;

      case 'delete':
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('tasks')
            .doc(item.taskId)
            .delete();
        break;
    }
  }

  /// Manual sync trigger
  Future<void> manualSync() async {
    if (!_isOnline) {
      _errorMessage = 'No internet connection';
      notifyListeners();
      return;
    }
    await _performSync();
  }

  /// Parse JSON string or return as-is if already map
  Map<String, dynamic> _parseJson(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is String) {
      // Handle both JSON string and map string representation
      try {
        if (data.startsWith('{') && data.endsWith('}')) {
          // This is a complex nested JSON that was converted to string
          // For now, return empty map - in production use jsonDecode
          return {};
        }
      } catch (e) {
        debugPrint('⚠️ Could not parse: $e');
      }
    }
    return {};
  }

  /// Get sync status for UI display
  String getStatusText() {
    switch (_status) {
      case SyncStatus.synced:
        return _lastSyncTime != null
            ? 'Synced ${_getRelativeTime(_lastSyncTime!)}'
            : 'Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.pending:
        return 'Pending ($_pendingItems items)';
      case SyncStatus.error:
        return 'Sync failed';
      case SyncStatus.offline:
        return 'Offline mode';
    }
  }

  String _getRelativeTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncSubscription?.cancel();
    super.dispose();
  }
}
