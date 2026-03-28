import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/note_model.dart';

class NoteProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription? _noteSubscription;

  List<NoteModel> _notes = [];
  bool _isLoading = false;
  String? _error;

  String _filterColor = 'all';
  String _searchQuery = '';
  bool _showArchived = false;

  List<NoteModel> get notes => _notes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterColor => _filterColor;
  String get searchQuery => _searchQuery;
  bool get showArchived => _showArchived;

  /// Get filtered and sorted notes
  List<NoteModel> get filteredNotes {
    var filtered = _notes.where((note) {
      if (!_showArchived && note.isArchived) return false;
      if (note.deletedAt != null) return false; // Skip soft-deleted
      if (_filterColor != 'all' && note.color != _filterColor) return false;
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return (note.title?.toLowerCase().contains(query) ?? false) ||
            note.content.toLowerCase().contains(query) ||
            note.tags.any((tag) => tag.toLowerCase().contains(query));
      }
      return true;
    }).toList();

    // Sort: pinned first, then by date
    filtered.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

    return filtered;
  }

  int get totalNotes => _notes.length;
  int get archivedCount => _notes.where((n) => n.isArchived).length;

  /// Start listening to notes
  void startListening(String userId) {
    _noteSubscription?.cancel();
    _isLoading = true;
    _error = null;
    notifyListeners();

    _noteSubscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('notes')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen(
      (snapshot) {
        _notes =
            snapshot.docs.map((doc) => NoteModel.fromJson(doc.data())).toList();
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  /// Create new note
  Future<void> createNote({
    required String userId,
    required String content,
    String? title,
    String color = 'yellow',
    List<String> tags = const [],
  }) async {
    try {
      final note = NoteModel(
        id: _firestore.collection('notes').doc().id,
        userId: userId,
        title: title,
        content: content,
        color: color,
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(note.id)
          .set(note.toJson());
    } catch (e) {
      _error = 'Failed to create note: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Update note
  Future<void> updateNote({
    required String userId,
    required String noteId,
    String? title,
    String? content,
    String? color,
    List<String>? tags,
    bool? isPinned,
    bool? isArchived,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .update({
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (color != null) 'color': color,
        if (tags != null) 'tags': tags,
        if (isPinned != null) 'isPinned': isPinned,
        if (isArchived != null) 'isArchived': isArchived,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      _error = 'Failed to update note: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Delete note (soft delete)
  Future<void> deleteNote(String userId, String noteId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .update({
        'deletedAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      _error = 'Failed to delete note: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Toggle pin
  Future<void> togglePin(String userId, String noteId, bool isPinned) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .update({
        'isPinned': !isPinned,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      _error = 'Failed to update pin status: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Toggle archive
  Future<void> toggleArchive(
      String userId, String noteId, bool isArchived) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .update({
        'isArchived': !isArchived,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      _error = 'Failed to update archive status: $e';
      notifyListeners();
      rethrow;
    }
  }

  /// Set color filter
  void setColorFilter(String color) {
    _filterColor = color;
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Toggle show archived
  void toggleShowArchived() {
    _showArchived = !_showArchived;
    notifyListeners();
  }

  @override
  void dispose() {
    _noteSubscription?.cancel();
    super.dispose();
  }
}
