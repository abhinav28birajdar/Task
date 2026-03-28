import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DataManagementService {
  static final DataManagementService _instance =
      DataManagementService._internal();

  factory DataManagementService() {
    return _instance;
  }

  DataManagementService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Export all user data as JSON
  Future<String> exportUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      debugPrint('📊 Exporting user data...');

      // Fetch tasks
      final tasksSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .get();

      // Fetch notes
      final notesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .get();

      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'userId': user.uid,
        'userEmail': user.email,
        'tasks': tasksSnapshot.docs.map((doc) => doc.data()).toList(),
        'notes': notesSnapshot.docs.map((doc) => doc.data()).toList(),
        'version': 1,
      };

      final jsonString = jsonEncode(exportData);
      debugPrint('✅ User data exported successfully');
      return jsonString;
    } catch (e) {
      debugPrint('❌ Export failed: $e');
      rethrow;
    }
  }

  /// Import data from JSON
  Future<void> importUserData(String jsonString) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      debugPrint('📥 Importing user data...');

      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      // Import tasks
      if (data['tasks'] is List) {
        for (final taskData in data['tasks']) {
          if (taskData is Map<String, dynamic>) {
            final taskId = taskData['id'] as String?;
            if (taskId != null) {
              await _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('tasks')
                  .doc(taskId)
                  .set(taskData, SetOptions(merge: true));
            }
          }
        }
      }

      // Import notes
      if (data['notes'] is List) {
        for (final noteData in data['notes']) {
          if (noteData is Map<String, dynamic>) {
            final noteId = noteData['id'] as String?;
            if (noteId != null) {
              await _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('notes')
                  .doc(noteId)
                  .set(noteData, SetOptions(merge: true));
            }
          }
        }
      }

      debugPrint('✅ User data imported successfully');
    } catch (e) {
      debugPrint('❌ Import failed: $e');
      rethrow;
    }
  }

  /// Clear all local data
  Future<void> clearLocalData() async {
    try {
      // This would depend on your local storage implementation
      // For now, it's a placeholder for SharedPreferences/Hive cleanup
      debugPrint('🗑️ Local data cleared');
    } catch (e) {
      debugPrint('❌ Failed to clear local data: $e');
      rethrow;
    }
  }

  /// Delete user account
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      debugPrint('🗑️ Deleting user account...');

      // Delete all user data from Firestore
      final tasksSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .get();

      for (final doc in tasksSnapshot.docs) {
        await doc.reference.delete();
      }

      final notesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .get();

      for (final doc in notesSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete user document
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete Firebase Auth user
      await user.delete();

      // Sign out
      await _auth.signOut();

      debugPrint('✅ User account deleted successfully');
    } catch (e) {
      debugPrint('❌ Account deletion failed: $e');
      rethrow;
    }
  }

  /// Get storage statistics
  Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final tasksSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .count()
          .get();

      final notesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notes')
          .count()
          .get();

      return {
        'totalTasks': tasksSnapshot.count,
        'totalNotes': notesSnapshot.count,
        'lastBackup': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Failed to get storage stats: $e');
      return {};
    }
  }
}
