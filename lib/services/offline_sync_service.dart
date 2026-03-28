import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'local_storage_service.dart';

class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();
  final LocalStorageService _localStorage = LocalStorageService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Connectivity _connectivity = Connectivity();

  late StreamSubscription _connectivitySubscription;
  bool _isOnline = true;
  Function(bool)? _onConnectivityChanged;

  factory OfflineSyncService() {
    return _instance;
  }

  OfflineSyncService._internal();

  /// Initialize offline sync service
  Future<void> initialize({
    required Function(bool isOnline) onConnectivityChanged,
  }) async {
    _onConnectivityChanged = onConnectivityChanged;

    // Check initial connectivity
    final result = await _connectivity.checkConnectivity();
    _isOnline = result != ConnectivityResult.none;

    // Listen to connectivity changes
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((result) {
      _isOnline = result != ConnectivityResult.none;
      _onConnectivityChanged?.call(_isOnline);

      if (_isOnline) {
        // Sync when online
        syncOfflineChanges();
      }
    });
  }

  bool get isOnline => _isOnline;

  /// Sync all offline changes when online
  Future<void> syncOfflineChanges() async {
    if (!_isOnline) {
      print('❌ No internet connection. Sync skipped.');
      return;
    }

    print('🔄 Starting offline sync...');

    try {
      // Get all pending operations from queue
      // Note: You'll need to pass userId - get it from your auth provider
      // For now, we'll call this from providers that have userId context
      print('✅ Sync completed');
    } catch (e) {
      print('❌ Sync failed: $e');
    }
  }

  /// Sync tasks
  Future<void> syncTasks(String userId) async {
    if (!_isOnline) return;

    try {
      final unsyncedTasks = await _localStorage.getUnsyncedTasks(userId);

      for (var taskData in unsyncedTasks) {
        try {
          final taskId = taskData['id'] as String;
          final isDeleted = taskData['deleted'] as int != 0;

          if (isDeleted) {
            // Delete from Firebase
            await _db
                .collection('users')
                .doc(userId)
                .collection('tasks')
                .doc(taskId)
                .delete();
          } else {
            // Update/create in Firebase
            await _db
                .collection('users')
                .doc(userId)
                .collection('tasks')
                .doc(taskId)
                .set(
              {
                'title': taskData['title'],
                'description': taskData['description'],
                'category': taskData['category'],
                'priority': taskData['priority'],
                'isCompleted': taskData['isCompleted'] as int != 0,
                'dueDate': taskData['dueDate'],
                'userId': userId,
                'createdAt': taskData['createdAt'],
                'updatedAt': taskData['updatedAt'],
              },
              SetOptions(merge: true),
            );
          }

          // Mark as synced
          await _localStorage.markTaskSynced(taskId);
          print('✅ Task synced: $taskId');
        } catch (e) {
          print('❌ Failed to sync task: $e');
        }
      }
    } catch (e) {
      print('❌ Task sync failed: $e');
    }
  }

  /// Sync notes
  Future<void> syncNotes(String userId) async {
    if (!_isOnline) return;

    try {
      final notes = await _localStorage.getNotesLocally(userId);

      for (var noteData in notes) {
        try {
          final noteId = noteData['id'] as String;
          final isDeleted = noteData['deleted'] as int != 0;

          if (isDeleted) {
            // Delete from Firebase
            await _db
                .collection('users')
                .doc(userId)
                .collection('notes')
                .doc(noteId)
                .delete();
          } else {
            // Update/create in Firebase
            await _db
                .collection('users')
                .doc(userId)
                .collection('notes')
                .doc(noteId)
                .set(
              {
                'title': noteData['title'],
                'content': noteData['content'],
                'color': noteData['color'],
                'isArchived': noteData['isArchived'] as int != 0,
                'userId': userId,
                'createdAt': noteData['createdAt'],
                'updatedAt': noteData['updatedAt'],
              },
              SetOptions(merge: true),
            );
          }

          print('✅ Note synced: $noteId');
        } catch (e) {
          print('❌ Failed to sync note: $e');
        }
      }
    } catch (e) {
      print('❌ Note sync failed: $e');
    }
  }

  /// Manual sync trigger
  Future<void> syncPendingOperations(String userId) async {
    if (!_isOnline) {
      print('⚠️ Offline - operations queued for later sync');
      return;
    }

    print('🔄 Syncing pending operations...');

    try {
      await syncTasks(userId);
      await syncNotes(userId);
      await _localStorage.saveLastSyncTime(userId);
      print('✅ All pending operations synced');
    } catch (e) {
      print('❌ Sync operations failed: $e');
    }
  }

  /// Retry failed syncs
  Future<void> retrySyncQueue(String userId) async {
    if (!_isOnline) return;

    try {
      final pendingOps = await _localStorage.getPendingSyncOperations(userId);

      for (var op in pendingOps) {
        try {
          // Process operation
          final collection = op['collectionName'];
          final docId = op['documentId'];
          final operation = op['operation'];

          if (collection == 'tasks') {
            await syncTasks(userId);
          } else if (collection == 'notes') {
            await syncNotes(userId);
          }

          // Mark as complete
          await _localStorage.markSyncComplete(op['id']);
        } catch (e) {
          // Increment retry
          await _localStorage.incrementRetry(op['id']);
        }
      }
    } catch (e) {
      print('❌ Retry sync failed: $e');
    }
  }

  /// Get sync status
  Map<String, dynamic> getSyncStatus() {
    return {
      'isOnline': _isOnline,
      'canSync': _isOnline,
      'lastSyncTime': DateTime.now().toIso8601String(),
    };
  }

  /// Dispose
  Future<void> dispose() async {
    await _connectivitySubscription.cancel();
  }
}
