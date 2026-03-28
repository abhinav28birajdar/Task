import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/timezone.dart' as tz;
import 'dart:typed_data';
import '../data/models/task_model.dart';
import '../core/routes/app_router.dart';

class NotificationService {
  static final instance = NotificationService._();
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      AppRouter.router.push('/task/${response.payload}');
    }
  }

  Future<void> scheduleTaskReminder({
    required int id,
    required String taskId,
    required String title,
    required String body,
    required DateTime scheduledTime,
    bool useAlarmSound = false,
  }) async {
    final tzTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          useAlarmSound ? 'alarm_channel' : 'task_channel',
          useAlarmSound ? 'Task Alarms' : 'Task Reminders',
          channelDescription: 'Notifications for task reminders',
          importance: Importance.max,
          priority: Priority.high,
          sound: useAlarmSound
              ? const RawResourceAndroidNotificationSound('alarm')
              : null,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
          fullScreenIntent: useAlarmSound,
          category: useAlarmSound
              ? AndroidNotificationCategory.alarm
              : AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(
          sound: useAlarmSound ? 'alarm.aiff' : 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: useAlarmSound
              ? InterruptionLevel.timeSensitive
              : InterruptionLevel.active,
        ),
      ),
      payload: taskId,
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_channel',
          'Instant Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> rescheduleAllFromFirestore(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('uid', isEqualTo: uid)
        .where('isCompleted', isEqualTo: false)
        .where('reminder', isEqualTo: true)
        .get();

    for (final doc in snapshot.docs) {
      final task = TaskModel.fromMap(doc.data());
      if (task.dueDate != null && task.alarmId != null) {
        final reminderTime = task.dueDate!.subtract(
          Duration(minutes: task.reminderMinutesBefore ?? 10),
        );
        if (reminderTime.isAfter(DateTime.now())) {
          await scheduleTaskReminder(
            id: task.alarmId!,
            taskId: task.id,
            title: '⏰ ${task.title}',
            body: task.dueTime != null
                ? 'Due at ${task.dueTime}'
                : 'Task is due soon',
            scheduledTime: reminderTime,
            useAlarmSound: task.alarmEnabled,
          );
        }
      }
    }
  }
}
