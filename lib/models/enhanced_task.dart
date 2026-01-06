import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'enhanced_task.g.dart';

/// Priority levels for tasks
enum TaskPriority {
  @HiveField(0)
  minimal,
  @HiveField(1)
  low,
  @HiveField(2)
  medium,
  @HiveField(3)
  high,
  @HiveField(4)
  critical
}

/// Recurrence types for repeating tasks
enum RecurrenceType {
  @HiveField(0)
  none,
  @HiveField(1)
  daily,
  @HiveField(2)
  weekly,
  @HiveField(3)
  monthly,
  @HiveField(4)
  yearly,
  @HiveField(5)
  custom
}

/// Reminder types
enum ReminderType {
  @HiveField(0)
  atTime,
  @HiveField(1)
  fifteenMinutes,
  @HiveField(2)
  oneHour,
  @HiveField(3)
  oneDay,
  @HiveField(4)
  custom
}

/// Subtask model
@HiveType(typeId: 10)
class SubTask extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  int order;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? completedAt;

  SubTask({
    String? id,
    required this.title,
    this.isCompleted = false,
    this.order = 0,
    DateTime? createdAt,
    this.completedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  SubTask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    int? order,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return SubTask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'is_completed': isCompleted,
        'order': order,
        'created_at': createdAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
      };

  factory SubTask.fromJson(Map<String, dynamic> json) => SubTask(
        id: json['id'] as String?,
        title: json['title'] as String,
        isCompleted: json['is_completed'] as bool? ?? false,
        order: json['order'] as int? ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
      );
}

/// Task attachment model for images and files
@HiveType(typeId: 11)
class TaskAttachment extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String path;

  @HiveField(2)
  String type; // 'image', 'audio', 'file'

  @HiveField(3)
  String? thumbnailPath;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  String? fileName;

  @HiveField(6)
  int? fileSize;

  TaskAttachment({
    String? id,
    required this.path,
    required this.type,
    this.thumbnailPath,
    DateTime? createdAt,
    this.fileName,
    this.fileSize,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  TaskAttachment copyWith({
    String? id,
    String? path,
    String? type,
    String? thumbnailPath,
    DateTime? createdAt,
    String? fileName,
    int? fileSize,
  }) {
    return TaskAttachment(
      id: id ?? this.id,
      path: path ?? this.path,
      type: type ?? this.type,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'type': type,
        'thumbnail_path': thumbnailPath,
        'created_at': createdAt.toIso8601String(),
        'file_name': fileName,
        'file_size': fileSize,
      };

  factory TaskAttachment.fromJson(Map<String, dynamic> json) => TaskAttachment(
        id: json['id'] as String?,
        path: json['path'] as String,
        type: json['type'] as String,
        thumbnailPath: json['thumbnail_path'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        fileName: json['file_name'] as String?,
        fileSize: json['file_size'] as int?,
      );
}

/// Reminder model for task notifications
@HiveType(typeId: 12)
class TaskReminder extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int reminderType; // ReminderType index

  @HiveField(2)
  DateTime? customTime;

  @HiveField(3)
  bool isEnabled;

  @HiveField(4)
  bool hasTriggered;

  TaskReminder({
    String? id,
    this.reminderType = 0,
    this.customTime,
    this.isEnabled = true,
    this.hasTriggered = false,
  }) : id = id ?? const Uuid().v4();

  ReminderType get type => ReminderType.values[reminderType];
  set type(ReminderType value) => reminderType = value.index;

  TaskReminder copyWith({
    String? id,
    int? reminderType,
    DateTime? customTime,
    bool? isEnabled,
    bool? hasTriggered,
  }) {
    return TaskReminder(
      id: id ?? this.id,
      reminderType: reminderType ?? this.reminderType,
      customTime: customTime ?? this.customTime,
      isEnabled: isEnabled ?? this.isEnabled,
      hasTriggered: hasTriggered ?? this.hasTriggered,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reminder_type': reminderType,
        'custom_time': customTime?.toIso8601String(),
        'is_enabled': isEnabled,
        'has_triggered': hasTriggered,
      };

  factory TaskReminder.fromJson(Map<String, dynamic> json) => TaskReminder(
        id: json['id'] as String?,
        reminderType: json['reminder_type'] as int? ?? 0,
        customTime: json['custom_time'] != null
            ? DateTime.parse(json['custom_time'] as String)
            : null,
        isEnabled: json['is_enabled'] as bool? ?? true,
        hasTriggered: json['has_triggered'] as bool? ?? false,
      );
}

/// Enhanced Task model with all features
@HiveType(typeId: 13)
class EnhancedTask extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  String? richTextContent; // JSON string for rich text

  @HiveField(4)
  bool isCompleted;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  DateTime? dueDate;

  @HiveField(7)
  DateTime? dueTime;

  @HiveField(8)
  String? categoryId;

  @HiveField(9)
  int priorityIndex; // TaskPriority index

  @HiveField(10)
  List<String> tags;

  @HiveField(11)
  List<SubTask> subtasks;

  @HiveField(12)
  List<TaskAttachment> attachments;

  @HiveField(13)
  List<TaskReminder> reminders;

  @HiveField(14)
  int recurrenceIndex; // RecurrenceType index

  @HiveField(15)
  String? recurrenceRule; // Custom recurrence rule

  @HiveField(16)
  DateTime? completedAt;

  @HiveField(17)
  String? notes;

  @HiveField(18)
  bool isArchived;

  @HiveField(19)
  DateTime? archivedAt;

  @HiveField(20)
  int? estimatedMinutes;

  @HiveField(21)
  int? actualMinutes;

  @HiveField(22)
  String? aiSuggestion;

  @HiveField(23)
  bool isAiGenerated;

  @HiveField(24)
  String? parentTaskId; // For recurring task instances

  @HiveField(25)
  DateTime? updatedAt;

  @HiveField(26)
  String? userId;

  @HiveField(27)
  bool isFavorite;

  @HiveField(28)
  int sortOrder;

  EnhancedTask({
    String? id,
    required this.title,
    this.description = '',
    this.richTextContent,
    this.isCompleted = false,
    DateTime? createdAt,
    this.dueDate,
    this.dueTime,
    this.categoryId,
    this.priorityIndex = 2, // Default medium
    List<String>? tags,
    List<SubTask>? subtasks,
    List<TaskAttachment>? attachments,
    List<TaskReminder>? reminders,
    this.recurrenceIndex = 0, // Default none
    this.recurrenceRule,
    this.completedAt,
    this.notes,
    this.isArchived = false,
    this.archivedAt,
    this.estimatedMinutes,
    this.actualMinutes,
    this.aiSuggestion,
    this.isAiGenerated = false,
    this.parentTaskId,
    DateTime? updatedAt,
    this.userId,
    this.isFavorite = false,
    this.sortOrder = 0,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        tags = tags ?? [],
        subtasks = subtasks ?? [],
        attachments = attachments ?? [],
        reminders = reminders ?? [];

  // Getters for enums
  TaskPriority get priority => TaskPriority.values[priorityIndex];
  set priority(TaskPriority value) => priorityIndex = value.index;

  RecurrenceType get recurrence => RecurrenceType.values[recurrenceIndex];
  set recurrence(RecurrenceType value) => recurrenceIndex = value.index;

  // Priority helpers
  String get priorityText {
    switch (priority) {
      case TaskPriority.critical:
        return 'Critical';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.minimal:
        return 'Minimal';
    }
  }

  int get priorityColor {
    switch (priority) {
      case TaskPriority.critical:
        return 0xFFEF4444; // Red
      case TaskPriority.high:
        return 0xFFF97316; // Orange
      case TaskPriority.medium:
        return 0xFFEAB308; // Yellow
      case TaskPriority.low:
        return 0xFF22C55E; // Green
      case TaskPriority.minimal:
        return 0xFF3B82F6; // Blue
    }
  }

  // Status helpers
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    final now = DateTime.now();
    final dueDateTime = dueTime != null
        ? DateTime(dueDate!.year, dueDate!.month, dueDate!.day, dueTime!.hour,
            dueTime!.minute)
        : DateTime(dueDate!.year, dueDate!.month, dueDate!.day, 23, 59, 59);
    return now.isAfter(dueDateTime);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  bool get isDueTomorrow {
    if (dueDate == null) return false;
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return dueDate!.year == tomorrow.year &&
        dueDate!.month == tomorrow.month &&
        dueDate!.day == tomorrow.day;
  }

  bool get isDueThisWeek {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    return dueDate!.isAfter(startOfWeek) && dueDate!.isBefore(endOfWeek);
  }

  // Subtask progress
  double get subtaskProgress {
    if (subtasks.isEmpty) return isCompleted ? 1.0 : 0.0;
    final completed = subtasks.where((s) => s.isCompleted).length;
    return completed / subtasks.length;
  }

  int get completedSubtasksCount => subtasks.where((s) => s.isCompleted).length;

  bool get hasAttachments => attachments.isNotEmpty;
  bool get hasSubtasks => subtasks.isNotEmpty;
  bool get hasReminders => reminders.isNotEmpty;
  bool get isRecurring => recurrence != RecurrenceType.none;

  // Copy with method
  EnhancedTask copyWith({
    String? id,
    String? title,
    String? description,
    String? richTextContent,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? dueTime,
    String? categoryId,
    int? priorityIndex,
    List<String>? tags,
    List<SubTask>? subtasks,
    List<TaskAttachment>? attachments,
    List<TaskReminder>? reminders,
    int? recurrenceIndex,
    String? recurrenceRule,
    DateTime? completedAt,
    String? notes,
    bool? isArchived,
    DateTime? archivedAt,
    int? estimatedMinutes,
    int? actualMinutes,
    String? aiSuggestion,
    bool? isAiGenerated,
    String? parentTaskId,
    DateTime? updatedAt,
    String? userId,
    bool? isFavorite,
    int? sortOrder,
  }) {
    return EnhancedTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      richTextContent: richTextContent ?? this.richTextContent,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      categoryId: categoryId ?? this.categoryId,
      priorityIndex: priorityIndex ?? this.priorityIndex,
      tags: tags ?? List.from(this.tags),
      subtasks: subtasks ?? List.from(this.subtasks),
      attachments: attachments ?? List.from(this.attachments),
      reminders: reminders ?? List.from(this.reminders),
      recurrenceIndex: recurrenceIndex ?? this.recurrenceIndex,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      isArchived: isArchived ?? this.isArchived,
      archivedAt: archivedAt ?? this.archivedAt,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      aiSuggestion: aiSuggestion ?? this.aiSuggestion,
      isAiGenerated: isAiGenerated ?? this.isAiGenerated,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      updatedAt: updatedAt ?? DateTime.now(),
      userId: userId ?? this.userId,
      isFavorite: isFavorite ?? this.isFavorite,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'rich_text_content': richTextContent,
        'is_completed': isCompleted,
        'created_at': createdAt.toIso8601String(),
        'due_date': dueDate?.toIso8601String(),
        'due_time': dueTime?.toIso8601String(),
        'category_id': categoryId,
        'priority': priorityIndex,
        'tags': tags,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'reminders': reminders.map((r) => r.toJson()).toList(),
        'recurrence': recurrenceIndex,
        'recurrence_rule': recurrenceRule,
        'completed_at': completedAt?.toIso8601String(),
        'notes': notes,
        'is_archived': isArchived,
        'archived_at': archivedAt?.toIso8601String(),
        'estimated_minutes': estimatedMinutes,
        'actual_minutes': actualMinutes,
        'ai_suggestion': aiSuggestion,
        'is_ai_generated': isAiGenerated,
        'parent_task_id': parentTaskId,
        'updated_at': updatedAt?.toIso8601String(),
        'user_id': userId,
        'is_favorite': isFavorite,
        'sort_order': sortOrder,
      };

  factory EnhancedTask.fromJson(Map<String, dynamic> json) => EnhancedTask(
        id: json['id'] as String?,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        richTextContent: json['rich_text_content'] as String?,
        isCompleted: json['is_completed'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        dueDate: json['due_date'] != null
            ? DateTime.parse(json['due_date'] as String)
            : null,
        dueTime: json['due_time'] != null
            ? DateTime.parse(json['due_time'] as String)
            : null,
        categoryId: json['category_id'] as String?,
        priorityIndex: json['priority'] as int? ?? 2,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        subtasks: (json['subtasks'] as List<dynamic>?)
                ?.map((s) => SubTask.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        attachments: (json['attachments'] as List<dynamic>?)
                ?.map((a) => TaskAttachment.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
        reminders: (json['reminders'] as List<dynamic>?)
                ?.map((r) => TaskReminder.fromJson(r as Map<String, dynamic>))
                .toList() ??
            [],
        recurrenceIndex: json['recurrence'] as int? ?? 0,
        recurrenceRule: json['recurrence_rule'] as String?,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        notes: json['notes'] as String?,
        isArchived: json['is_archived'] as bool? ?? false,
        archivedAt: json['archived_at'] != null
            ? DateTime.parse(json['archived_at'] as String)
            : null,
        estimatedMinutes: json['estimated_minutes'] as int?,
        actualMinutes: json['actual_minutes'] as int?,
        aiSuggestion: json['ai_suggestion'] as String?,
        isAiGenerated: json['is_ai_generated'] as bool? ?? false,
        parentTaskId: json['parent_task_id'] as String?,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
        userId: json['user_id'] as String?,
        isFavorite: json['is_favorite'] as bool? ?? false,
        sortOrder: json['sort_order'] as int? ?? 0,
      );

  @override
  String toString() =>
      'EnhancedTask(id: $id, title: $title, isCompleted: $isCompleted)';
}
