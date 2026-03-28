import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import '../data/models/task_model.dart';
import 'notification_service.dart';
import '../firebase_options.dart';

class AlarmService {
  static final instance = AlarmService._();
  AlarmService._();

  Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  Future<void> setAlarm({
    required int alarmId,
    required DateTime alarmTime,
    required String taskId,
  }) async {
    await AndroidAlarmManager.oneShotAt(
      alarmTime,
      alarmId,
      _alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      params: {'taskId': taskId, 'alarmId': alarmId},
    );
  }

  Future<void> cancelAlarm(int alarmId) async {
    await AndroidAlarmManager.cancel(alarmId);
  }
}

@pragma('vm:entry-point')
Future<void> _alarmCallback(int id, Map<String, dynamic>? data) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.initialize();

  final taskId = data?['taskId'] as String? ?? '';
  final snapshot =
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();

  if (snapshot.exists) {
    final task = TaskModel.fromMap(snapshot.data()!);
    if (!task.isCompleted) {
      await NotificationService.instance.showInstantNotification(
        id: id,
        title: '⏰ Alarm: ${task.title}',
        body: 'Your task alarm is ringing!',
        payload: taskId,
      );
    }
  }
}
