import 'package:cloud_firestore/cloud_firestore.dart';
import 'subtask_model.dart';

class TaskModel {
  final String id;
  final String uid;
  final String title;
  final String description;
  final String category;
  final String priority;
  final bool isCompleted;
  final DateTime? dueDate;
  final String? dueTime;
  final bool reminder;
  final int? reminderMinutesBefore;
  final bool alarmEnabled;
  final String? alarmTone;
  final int? alarmId;
  final List<SubTaskModel> subTasks;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? color;
  final bool isStarred;

  TaskModel({
    required this.id,
    required this.uid,
    required this.title,
    required this.description,
    required this.category,
    required this.priority,
    required this.isCompleted,
    this.dueDate,
    this.dueTime,
    required this.reminder,
    this.reminderMinutesBefore,
    required this.alarmEnabled,
    this.alarmTone,
    this.alarmId,
    required this.subTasks,
    required this.createdAt,
    required this.updatedAt,
    this.color,
    this.isStarred = false,
  });

  TaskModel copyWith({
    String? id,
    String? uid,
    String? title,
    String? description,
    String? category,
    String? priority,
    bool? isCompleted,
    DateTime? dueDate,
    String? dueTime,
    bool? reminder,
    int? reminderMinutesBefore,
    bool? alarmEnabled,
    String? alarmTone,
    int? alarmId,
    List<SubTaskModel>? subTasks,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? color,
    bool? isStarred,
  }) {
    return TaskModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      reminder: reminder ?? this.reminder,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      alarmEnabled: alarmEnabled ?? this.alarmEnabled,
      alarmTone: alarmTone ?? this.alarmTone,
      alarmId: alarmId ?? this.alarmId,
      subTasks: subTasks ?? this.subTasks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      color: color ?? this.color,
      isStarred: isStarred ?? this.isStarred,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'uid': uid,
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'isCompleted': isCompleted,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'dueTime': dueTime,
      'reminder': reminder,
      'reminderMinutesBefore': reminderMinutesBefore,
      'alarmEnabled': alarmEnabled,
      'alarmTone': alarmTone,
      'alarmId': alarmId,
      'subTasks': subTasks.map((x) => x.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'color': color,
      'isStarred': isStarred,
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'other',
      priority: map['priority'] ?? 'low',
      isCompleted: map['isCompleted'] ?? false,
      dueDate: map['dueDate'] != null
          ? (map['dueDate'] as Timestamp).toDate()
          : null,
      dueTime: map['dueTime'],
      reminder: map['reminder'] ?? false,
      reminderMinutesBefore: map['reminderMinutesBefore'],
      alarmEnabled: map['alarmEnabled'] ?? false,
      alarmTone: map['alarmTone'],
      alarmId: map['alarmId'],
      subTasks: map['subTasks'] != null
          ? List<SubTaskModel>.from(
              (map['subTasks'] as List).map((x) => SubTaskModel.fromMap(x)))
          : [],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      color: map['color'],
      isStarred: map['isStarred'] ?? false,
    );
  }
}
