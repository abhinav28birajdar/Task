import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  final SharedPreferences _prefs;

  NotificationProvider(this._prefs) {
    _pushEnabled = _prefs.getBool('push_notifications') ?? true;
    _remindersEnabled = _prefs.getBool('task_reminders') ?? true;
    _alarmsEnabled = _prefs.getBool('alarm_notifications') ?? true;
    _dailySummaryEnabled = _prefs.getBool('daily_summary') ?? false;

    final summaryTimeStr = _prefs.getString('daily_summary_time');
    if (summaryTimeStr != null) {
      final parts = summaryTimeStr.split(':');
      _dailySummaryTime =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } else {
      _dailySummaryTime = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  bool _pushEnabled = true;
  bool _remindersEnabled = true;
  bool _alarmsEnabled = true;
  bool _dailySummaryEnabled = false;
  late TimeOfDay _dailySummaryTime;

  bool get pushEnabled => _pushEnabled;
  bool get remindersEnabled => _remindersEnabled;
  bool get alarmsEnabled => _alarmsEnabled;
  bool get dailySummary => _dailySummaryEnabled;
  TimeOfDay get dailySummaryTime => _dailySummaryTime;

  void togglePush(bool value) {
    _pushEnabled = value;
    _prefs.setBool('push_notifications', value);
    notifyListeners();
  }

  void toggleReminders(bool value) {
    _remindersEnabled = value;
    _prefs.setBool('task_reminders', value);
    notifyListeners();
  }

  void toggleAlarms(bool value) {
    _alarmsEnabled = value;
    _prefs.setBool('alarm_notifications', value);
    notifyListeners();
  }

  void toggleDailySummary(bool value) {
    _dailySummaryEnabled = value;
    _prefs.setBool('daily_summary', value);
    notifyListeners();
  }

  void setDailySummaryTime(TimeOfDay time) {
    _dailySummaryTime = time;
    _prefs.setString('daily_summary_time', '${time.hour}:${time.minute}');
    notifyListeners();
  }
}
