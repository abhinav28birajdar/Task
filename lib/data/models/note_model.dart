import 'package:cloud_firestore/cloud_firestore.dart';

enum NoteColor { yellow, blue, red, green, purple, white }

class NoteModel {
  final String id;
  final String userId;
  final String? title;
  final String content;
  final String color;
  final List<String> tags;
  final bool isPinned;
  final bool isArchived;
  final DateTime? reminder;
  final List<String> collaborators;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  NoteModel({
    required this.id,
    required this.userId,
    this.title,
    required this.content,
    this.color = 'yellow',
    this.tags = const [],
    this.isPinned = false,
    this.isArchived = false,
    this.reminder,
    this.collaborators = const [],
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'title': title,
        'content': content,
        'color': color,
        'tags': tags,
        'isPinned': isPinned,
        'isArchived': isArchived,
        'reminder': reminder,
        'collaborators': collaborators,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'deletedAt': deletedAt,
      };

  /// Create from Firestore document
  factory NoteModel.fromJson(Map<String, dynamic> json) => NoteModel(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        title: json['title'] as String?,
        content: json['content'] as String? ?? '',
        color: json['color'] as String? ?? 'yellow',
        tags: List<String>.from(json['tags'] as List? ?? []),
        isPinned: json['isPinned'] as bool? ?? false,
        isArchived: json['isArchived'] as bool? ?? false,
        reminder: json['reminder'] != null
            ? (json['reminder'] as Timestamp).toDate()
            : null,
        collaborators: List<String>.from(json['collaborators'] as List? ?? []),
        createdAt: json['createdAt'] != null
            ? (json['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? (json['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        deletedAt: json['deletedAt'] != null
            ? (json['deletedAt'] as Timestamp).toDate()
            : null,
      );

  /// Copy with modifications
  NoteModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? content,
    String? color,
    List<String>? tags,
    bool? isPinned,
    bool? isArchived,
    DateTime? reminder,
    List<String>? collaborators,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      NoteModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        content: content ?? this.content,
        color: color ?? this.color,
        tags: tags ?? this.tags,
        isPinned: isPinned ?? this.isPinned,
        isArchived: isArchived ?? this.isArchived,
        reminder: reminder ?? this.reminder,
        collaborators: collaborators ?? this.collaborators,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );
}
