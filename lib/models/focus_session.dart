import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'focus_session.g.dart';

/// Focus session status
enum FocusSessionStatus {
  @HiveField(0)
  notStarted,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  paused,
  @HiveField(3)
  completed,
  @HiveField(4)
  cancelled
}

/// Focus session type
enum FocusSessionType {
  @HiveField(0)
  work,
  @HiveField(1)
  shortBreak,
  @HiveField(2)
  longBreak
}

/// Focus session model for Pomodoro timer
@HiveType(typeId: 19)
class FocusSession extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String? taskId;

  @HiveField(2)
  String? taskTitle;

  @HiveField(3)
  int sessionTypeIndex;

  @HiveField(4)
  int statusIndex;

  @HiveField(5)
  int durationMinutes;

  @HiveField(6)
  int elapsedSeconds;

  @HiveField(7)
  DateTime? startedAt;

  @HiveField(8)
  DateTime? completedAt;

  @HiveField(9)
  DateTime? pausedAt;

  @HiveField(10)
  int pauseCount;

  @HiveField(11)
  int totalPausedSeconds;

  @HiveField(12)
  String? notes;

  @HiveField(13)
  bool wasInterrupted;

  @HiveField(14)
  DateTime createdAt;

  FocusSession({
    String? id,
    this.taskId,
    this.taskTitle,
    this.sessionTypeIndex = 0,
    this.statusIndex = 0,
    this.durationMinutes = 25,
    this.elapsedSeconds = 0,
    this.startedAt,
    this.completedAt,
    this.pausedAt,
    this.pauseCount = 0,
    this.totalPausedSeconds = 0,
    this.notes,
    this.wasInterrupted = false,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  FocusSessionType get sessionType => FocusSessionType.values[sessionTypeIndex];
  set sessionType(FocusSessionType value) => sessionTypeIndex = value.index;

  FocusSessionStatus get status => FocusSessionStatus.values[statusIndex];
  set status(FocusSessionStatus value) => statusIndex = value.index;

  int get totalDurationSeconds => durationMinutes * 60;
  int get remainingSeconds => totalDurationSeconds - elapsedSeconds;
  double get progress => elapsedSeconds / totalDurationSeconds;
  bool get isCompleted => status == FocusSessionStatus.completed;
  bool get isInProgress => status == FocusSessionStatus.inProgress;
  bool get isPaused => status == FocusSessionStatus.paused;

  String get formattedRemaining {
    final mins = remainingSeconds ~/ 60;
    final secs = remainingSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String get formattedElapsed {
    final mins = elapsedSeconds ~/ 60;
    final secs = elapsedSeconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  String get sessionTypeName {
    switch (sessionType) {
      case FocusSessionType.work:
        return 'Focus';
      case FocusSessionType.shortBreak:
        return 'Short Break';
      case FocusSessionType.longBreak:
        return 'Long Break';
    }
  }

  FocusSession copyWith({
    String? id,
    String? taskId,
    String? taskTitle,
    int? sessionTypeIndex,
    int? statusIndex,
    int? durationMinutes,
    int? elapsedSeconds,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? pausedAt,
    int? pauseCount,
    int? totalPausedSeconds,
    String? notes,
    bool? wasInterrupted,
    DateTime? createdAt,
  }) {
    return FocusSession(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      taskTitle: taskTitle ?? this.taskTitle,
      sessionTypeIndex: sessionTypeIndex ?? this.sessionTypeIndex,
      statusIndex: statusIndex ?? this.statusIndex,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      pausedAt: pausedAt ?? this.pausedAt,
      pauseCount: pauseCount ?? this.pauseCount,
      totalPausedSeconds: totalPausedSeconds ?? this.totalPausedSeconds,
      notes: notes ?? this.notes,
      wasInterrupted: wasInterrupted ?? this.wasInterrupted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'task_id': taskId,
        'task_title': taskTitle,
        'session_type': sessionTypeIndex,
        'status': statusIndex,
        'duration_minutes': durationMinutes,
        'elapsed_seconds': elapsedSeconds,
        'started_at': startedAt?.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'paused_at': pausedAt?.toIso8601String(),
        'pause_count': pauseCount,
        'total_paused_seconds': totalPausedSeconds,
        'notes': notes,
        'was_interrupted': wasInterrupted,
        'created_at': createdAt.toIso8601String(),
      };

  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
        id: json['id'] as String?,
        taskId: json['task_id'] as String?,
        taskTitle: json['task_title'] as String?,
        sessionTypeIndex: json['session_type'] as int? ?? 0,
        statusIndex: json['status'] as int? ?? 0,
        durationMinutes: json['duration_minutes'] as int? ?? 25,
        elapsedSeconds: json['elapsed_seconds'] as int? ?? 0,
        startedAt: json['started_at'] != null
            ? DateTime.parse(json['started_at'] as String)
            : null,
        completedAt: json['completed_at'] != null
            ? DateTime.parse(json['completed_at'] as String)
            : null,
        pausedAt: json['paused_at'] != null
            ? DateTime.parse(json['paused_at'] as String)
            : null,
        pauseCount: json['pause_count'] as int? ?? 0,
        totalPausedSeconds: json['total_paused_seconds'] as int? ?? 0,
        notes: json['notes'] as String?,
        wasInterrupted: json['was_interrupted'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );
}

/// Pomodoro settings model
@HiveType(typeId: 20)
class PomodoroSettings extends HiveObject {
  @HiveField(0)
  int workDuration; // in minutes

  @HiveField(1)
  int shortBreakDuration;

  @HiveField(2)
  int longBreakDuration;

  @HiveField(3)
  int sessionsBeforeLongBreak;

  @HiveField(4)
  bool autoStartBreaks;

  @HiveField(5)
  bool autoStartWork;

  @HiveField(6)
  bool playSound;

  @HiveField(7)
  bool vibrate;

  @HiveField(8)
  bool showNotification;

  @HiveField(9)
  String? selectedSoundId;

  @HiveField(10)
  int dailyGoal; // Number of focus sessions

  PomodoroSettings({
    this.workDuration = 25,
    this.shortBreakDuration = 5,
    this.longBreakDuration = 15,
    this.sessionsBeforeLongBreak = 4,
    this.autoStartBreaks = false,
    this.autoStartWork = false,
    this.playSound = true,
    this.vibrate = true,
    this.showNotification = true,
    this.selectedSoundId,
    this.dailyGoal = 8,
  });

  PomodoroSettings copyWith({
    int? workDuration,
    int? shortBreakDuration,
    int? longBreakDuration,
    int? sessionsBeforeLongBreak,
    bool? autoStartBreaks,
    bool? autoStartWork,
    bool? playSound,
    bool? vibrate,
    bool? showNotification,
    String? selectedSoundId,
    int? dailyGoal,
  }) {
    return PomodoroSettings(
      workDuration: workDuration ?? this.workDuration,
      shortBreakDuration: shortBreakDuration ?? this.shortBreakDuration,
      longBreakDuration: longBreakDuration ?? this.longBreakDuration,
      sessionsBeforeLongBreak:
          sessionsBeforeLongBreak ?? this.sessionsBeforeLongBreak,
      autoStartBreaks: autoStartBreaks ?? this.autoStartBreaks,
      autoStartWork: autoStartWork ?? this.autoStartWork,
      playSound: playSound ?? this.playSound,
      vibrate: vibrate ?? this.vibrate,
      showNotification: showNotification ?? this.showNotification,
      selectedSoundId: selectedSoundId ?? this.selectedSoundId,
      dailyGoal: dailyGoal ?? this.dailyGoal,
    );
  }

  Map<String, dynamic> toJson() => {
        'work_duration': workDuration,
        'short_break_duration': shortBreakDuration,
        'long_break_duration': longBreakDuration,
        'sessions_before_long_break': sessionsBeforeLongBreak,
        'auto_start_breaks': autoStartBreaks,
        'auto_start_work': autoStartWork,
        'play_sound': playSound,
        'vibrate': vibrate,
        'show_notification': showNotification,
        'selected_sound_id': selectedSoundId,
        'daily_goal': dailyGoal,
      };

  factory PomodoroSettings.fromJson(Map<String, dynamic> json) =>
      PomodoroSettings(
        workDuration: json['work_duration'] as int? ?? 25,
        shortBreakDuration: json['short_break_duration'] as int? ?? 5,
        longBreakDuration: json['long_break_duration'] as int? ?? 15,
        sessionsBeforeLongBreak:
            json['sessions_before_long_break'] as int? ?? 4,
        autoStartBreaks: json['auto_start_breaks'] as bool? ?? false,
        autoStartWork: json['auto_start_work'] as bool? ?? false,
        playSound: json['play_sound'] as bool? ?? true,
        vibrate: json['vibrate'] as bool? ?? true,
        showNotification: json['show_notification'] as bool? ?? true,
        selectedSoundId: json['selected_sound_id'] as String?,
        dailyGoal: json['daily_goal'] as int? ?? 8,
      );
}
