import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/task_model.dart';
import '../services/notification_service.dart';
import '../services/alarm_service.dart';

class TaskProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _taskSubscription;
  List<TaskModel> _tasks = [];
  bool _isLoading = false;

  String _filterCategory = 'all';
  String _filterPriority = 'all';
  String _filterStatus = 'all';
  String _filterQuery = '';

  String get filterCategory => _filterCategory;
  String get filterPriority => _filterPriority;
  String get filterStatus => _filterStatus;
  String get filterQuery => _filterQuery;

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;

  List<TaskModel> get filteredTasks {
    return _tasks.where((t) {
      final catMatch =
          _filterCategory == 'all' || t.category == _filterCategory;
      final priMatch =
          _filterPriority == 'all' || t.priority == _filterPriority;
      final statMatch = _filterStatus == 'all' ||
          (_filterStatus == 'completed' && t.isCompleted) ||
          (_filterStatus == 'pending' && !t.isCompleted);
      final qMatch = _filterQuery.isEmpty ||
          t.title.toLowerCase().contains(_filterQuery) ||
          t.description.toLowerCase().contains(_filterQuery);
      return catMatch && priMatch && statMatch && qMatch;
    }).toList();
  }

  List<TaskModel> get starredTasks {
    return _tasks.where((t) => t.isStarred).toList();
  }

  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  int get pendingCount => _tasks.where((t) => !t.isCompleted).length;
  int get overdueCount => _tasks
      .where((t) =>
          !t.isCompleted &&
          t.dueDate != null &&
          t.dueDate!.isBefore(DateTime.now()))
      .length;

  int currentStreak(String uid) {
    if (_tasks.isEmpty) return 0;
    final sortedCompletions = _tasks
        .where((t) => t.isCompleted)
        .map((t) =>
            DateTime(t.updatedAt.year, t.updatedAt.month, t.updatedAt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (sortedCompletions.isEmpty) return 0;

    int streak = 0;
    DateTime currentDay =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

    if (sortedCompletions.first
        .isBefore(currentDay.subtract(const Duration(days: 1)))) {
      return 0; // Streak broken
    }

    for (var i = 0; i < sortedCompletions.length; i++) {
      if (i == 0) {
        if (sortedCompletions[i] == currentDay ||
            sortedCompletions[i] ==
                currentDay.subtract(const Duration(days: 1))) {
          streak++;
          currentDay = sortedCompletions[i];
        }
      } else {
        if (sortedCompletions[i] ==
            currentDay.subtract(const Duration(days: 1))) {
          streak++;
          currentDay = sortedCompletions[i];
        } else {
          break;
        }
      }
    }
    return streak;
  }

  void startListening(String uid) {
    _taskSubscription?.cancel();
    _isLoading = true;
    notifyListeners();
    _taskSubscription = _db
        .collection('tasks')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snap) {
      _tasks = snap.docs.map((d) => TaskModel.fromMap(d.data())).toList();
      _isLoading = false;
      notifyListeners();
    });
  }

  void stopListening() => _taskSubscription?.cancel();

  Future<void> addTask(TaskModel task) async {
    final doc = _db.collection('tasks').doc();
    final newTask = task.copyWith(
        id: doc.id, createdAt: DateTime.now(), updatedAt: DateTime.now());
    await doc.set(newTask.toMap());

    if (newTask.reminder && newTask.dueDate != null) {
      final reminderTime = newTask.dueDate!
          .subtract(Duration(minutes: newTask.reminderMinutesBefore ?? 10));
      if (reminderTime.isAfter(DateTime.now())) {
        final alarmId = doc.id.hashCode.abs();
        await NotificationService.instance.scheduleTaskReminder(
          id: alarmId,
          taskId: doc.id,
          title: '⏰ ${newTask.title}',
          body: 'Due at ${newTask.dueTime ?? "soon"}',
          scheduledTime: reminderTime,
          useAlarmSound: newTask.alarmEnabled,
        );
        if (newTask.alarmEnabled) {
          await AlarmService.instance.setAlarm(
            alarmId: alarmId,
            alarmTime: reminderTime,
            taskId: doc.id,
          );
        }
        await doc.update({'alarmId': alarmId});
      }
    }
  }

  Future<void> updateTask(TaskModel task) async {
    if (task.alarmId != null) {
      await NotificationService.instance.cancelNotification(task.alarmId!);
      await AlarmService.instance.cancelAlarm(task.alarmId!);
    }

    await _db
        .collection('tasks')
        .doc(task.id)
        .update(task.copyWith(updatedAt: DateTime.now()).toMap());

    if (task.reminder && task.dueDate != null) {
      final reminderTime = task.dueDate!
          .subtract(Duration(minutes: task.reminderMinutesBefore ?? 10));
      if (reminderTime.isAfter(DateTime.now())) {
        final alarmId = task.id.hashCode.abs();
        await NotificationService.instance.scheduleTaskReminder(
          id: alarmId,
          taskId: task.id,
          title: '⏰ ${task.title}',
          body: 'Due at ${task.dueTime ?? "soon"}',
          scheduledTime: reminderTime,
          useAlarmSound: task.alarmEnabled,
        );
        if (task.alarmEnabled) {
          await AlarmService.instance.setAlarm(
              alarmId: alarmId, alarmTime: reminderTime, taskId: task.id);
        }
        await _db.collection('tasks').doc(task.id).update({'alarmId': alarmId});
      }
    }
  }

  Future<void> deleteTask(TaskModel task) async {
    if (task.alarmId != null) {
      await NotificationService.instance.cancelNotification(task.alarmId!);
      await AlarmService.instance.cancelAlarm(task.alarmId!);
    }
    await _db.collection('tasks').doc(task.id).delete();
  }

  Future<void> clearAllTasks(String uid) async {
    for (final t in _tasks) {
      if (t.alarmId != null) {
        await NotificationService.instance.cancelNotification(t.alarmId!);
        await AlarmService.instance.cancelAlarm(t.alarmId!);
      }
      await _db.collection('tasks').doc(t.id).delete();
    }
  }

  Future<void> toggleTask(String taskId, bool isCompleted) async {
    await _db.collection('tasks').doc(taskId).update({
      'isCompleted': isCompleted,
      'updatedAt': Timestamp.now(),
    });
    HapticFeedback.lightImpact();
  }

  Future<void> toggleStarred(String taskId, bool isStarred) async {
    await _db.collection('tasks').doc(taskId).update({
      'isStarred': isStarred,
      'updatedAt': Timestamp.now(),
    });
    HapticFeedback.lightImpact();
  }

  Future<void> toggleSubTask(String taskId, String subTaskId, bool val) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;
    final updatedSubTasks = _tasks[taskIndex]
        .subTasks
        .map((s) => s.id == subTaskId ? s.copyWith(isCompleted: val) : s)
        .toList();
    await _db.collection('tasks').doc(taskId).update({
      'subTasks': updatedSubTasks.map((s) => s.toMap()).toList(),
      'updatedAt': Timestamp.now(),
    });
  }

  List<TaskModel> searchTasks(String query) {
    final q = query.toLowerCase();
    return _tasks
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q))
        .toList();
  }

  void setFilterCategory(String cat) {
    _filterCategory = cat;
    notifyListeners();
  }

  void setFilterPriority(String p) {
    _filterPriority = p;
    notifyListeners();
  }

  void setFilterStatus(String s) {
    _filterStatus = s;
    notifyListeners();
  }

  void setFilterQuery(String q) {
    _filterQuery = q.toLowerCase();
    notifyListeners();
  }

  @override
  void dispose() {
    _taskSubscription?.cancel();
    super.dispose();
  }
}
