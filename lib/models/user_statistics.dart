import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'user_statistics.g.dart';

/// Achievement types
enum AchievementType {
  tasksCompleted,
  streak,
  categoryMaster,
  earlyBird,
  nightOwl,
  focusChampion,
  speedDemon,
  perfectWeek,
  perfectMonth,
}

/// Achievement model
@HiveType(typeId: 14)
class Achievement extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  String iconName;

  @HiveField(4)
  int achievementType;

  @HiveField(5)
  int requiredValue;

  @HiveField(6)
  int currentValue;

  @HiveField(7)
  bool isUnlocked;

  @HiveField(8)
  DateTime? unlockedAt;

  @HiveField(9)
  int xpReward;

  Achievement({
    String? id,
    required this.title,
    required this.description,
    required this.iconName,
    required this.achievementType,
    required this.requiredValue,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.xpReward = 100,
  }) : id = id ?? const Uuid().v4();

  AchievementType get type => AchievementType.values[achievementType];
  set type(AchievementType value) => achievementType = value.index;

  double get progress => currentValue / requiredValue;

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? iconName,
    int? achievementType,
    int? requiredValue,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? xpReward,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      achievementType: achievementType ?? this.achievementType,
      requiredValue: requiredValue ?? this.requiredValue,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'icon_name': iconName,
        'achievement_type': achievementType,
        'required_value': requiredValue,
        'current_value': currentValue,
        'is_unlocked': isUnlocked,
        'unlocked_at': unlockedAt?.toIso8601String(),
        'xp_reward': xpReward,
      };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'] as String?,
        title: json['title'] as String,
        description: json['description'] as String,
        iconName: json['icon_name'] as String,
        achievementType: json['achievement_type'] as int,
        requiredValue: json['required_value'] as int,
        currentValue: json['current_value'] as int? ?? 0,
        isUnlocked: json['is_unlocked'] as bool? ?? false,
        unlockedAt: json['unlocked_at'] != null
            ? DateTime.parse(json['unlocked_at'] as String)
            : null,
        xpReward: json['xp_reward'] as int? ?? 100,
      );
}

/// Daily statistics snapshot
@HiveType(typeId: 15)
class DailyStats extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  int tasksCreated;

  @HiveField(3)
  int tasksCompleted;

  @HiveField(4)
  int focusMinutes;

  @HiveField(5)
  int pomodoroSessions;

  @HiveField(6)
  List<String> completedTaskIds;

  @HiveField(7)
  Map<String, int> categoryTaskCount;

  @HiveField(8)
  int overdueTasks;

  DailyStats({
    String? id,
    required this.date,
    this.tasksCreated = 0,
    this.tasksCompleted = 0,
    this.focusMinutes = 0,
    this.pomodoroSessions = 0,
    List<String>? completedTaskIds,
    Map<String, int>? categoryTaskCount,
    this.overdueTasks = 0,
  })  : id = id ?? const Uuid().v4(),
        completedTaskIds = completedTaskIds ?? [],
        categoryTaskCount = categoryTaskCount ?? {};

  DailyStats copyWith({
    String? id,
    DateTime? date,
    int? tasksCreated,
    int? tasksCompleted,
    int? focusMinutes,
    int? pomodoroSessions,
    List<String>? completedTaskIds,
    Map<String, int>? categoryTaskCount,
    int? overdueTasks,
  }) {
    return DailyStats(
      id: id ?? this.id,
      date: date ?? this.date,
      tasksCreated: tasksCreated ?? this.tasksCreated,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      focusMinutes: focusMinutes ?? this.focusMinutes,
      pomodoroSessions: pomodoroSessions ?? this.pomodoroSessions,
      completedTaskIds: completedTaskIds ?? List.from(this.completedTaskIds),
      categoryTaskCount: categoryTaskCount ?? Map.from(this.categoryTaskCount),
      overdueTasks: overdueTasks ?? this.overdueTasks,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'tasks_created': tasksCreated,
        'tasks_completed': tasksCompleted,
        'focus_minutes': focusMinutes,
        'pomodoro_sessions': pomodoroSessions,
        'completed_task_ids': completedTaskIds,
        'category_task_count': categoryTaskCount,
        'overdue_tasks': overdueTasks,
      };

  factory DailyStats.fromJson(Map<String, dynamic> json) => DailyStats(
        id: json['id'] as String?,
        date: DateTime.parse(json['date'] as String),
        tasksCreated: json['tasks_created'] as int? ?? 0,
        tasksCompleted: json['tasks_completed'] as int? ?? 0,
        focusMinutes: json['focus_minutes'] as int? ?? 0,
        pomodoroSessions: json['pomodoro_sessions'] as int? ?? 0,
        completedTaskIds:
            (json['completed_task_ids'] as List<dynamic>?)?.cast<String>() ??
                [],
        categoryTaskCount:
            (json['category_task_count'] as Map<String, dynamic>?)
                    ?.cast<String, int>() ??
                {},
        overdueTasks: json['overdue_tasks'] as int? ?? 0,
      );
}

/// User statistics model
@HiveType(typeId: 16)
class UserStatistics extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  int totalTasksCreated;

  @HiveField(2)
  int totalTasksCompleted;

  @HiveField(3)
  int currentStreak;

  @HiveField(4)
  int longestStreak;

  @HiveField(5)
  DateTime? lastCompletedDate;

  @HiveField(6)
  int totalFocusMinutes;

  @HiveField(7)
  int totalPomodoroSessions;

  @HiveField(8)
  int level;

  @HiveField(9)
  int experiencePoints;

  @HiveField(10)
  List<Achievement> achievements;

  @HiveField(11)
  List<DailyStats> dailyStats;

  @HiveField(12)
  Map<String, int> categoryCompletionCount;

  @HiveField(13)
  Map<int, int> hourlyProductivity; // Hour (0-23) -> tasks completed

  @HiveField(14)
  Map<int, int> weekdayProductivity; // Weekday (1-7) -> tasks completed

  @HiveField(15)
  DateTime createdAt;

  @HiveField(16)
  DateTime updatedAt;

  UserStatistics({
    String? id,
    this.totalTasksCreated = 0,
    this.totalTasksCompleted = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastCompletedDate,
    this.totalFocusMinutes = 0,
    this.totalPomodoroSessions = 0,
    this.level = 1,
    this.experiencePoints = 0,
    List<Achievement>? achievements,
    List<DailyStats>? dailyStats,
    Map<String, int>? categoryCompletionCount,
    Map<int, int>? hourlyProductivity,
    Map<int, int>? weekdayProductivity,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        achievements = achievements ?? [],
        dailyStats = dailyStats ?? [],
        categoryCompletionCount = categoryCompletionCount ?? {},
        hourlyProductivity = hourlyProductivity ?? {},
        weekdayProductivity = weekdayProductivity ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Completion rate
  double get completionRate {
    if (totalTasksCreated == 0) return 0;
    return totalTasksCompleted / totalTasksCreated;
  }

  // XP required for next level
  int get xpForNextLevel => level * 500;

  // XP progress to next level
  double get levelProgress => experiencePoints / xpForNextLevel;

  // Check and update streak
  void updateStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastCompletedDate == null) {
      currentStreak = 1;
      lastCompletedDate = today;
    } else {
      final lastDate = DateTime(lastCompletedDate!.year,
          lastCompletedDate!.month, lastCompletedDate!.day);
      final difference = today.difference(lastDate).inDays;

      if (difference == 0) {
        // Same day, no change
      } else if (difference == 1) {
        currentStreak++;
        lastCompletedDate = today;
      } else {
        currentStreak = 1;
        lastCompletedDate = today;
      }
    }

    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }

    updatedAt = DateTime.now();
  }

  // Add XP and handle level up
  bool addExperience(int xp) {
    experiencePoints += xp;
    bool leveledUp = false;

    while (experiencePoints >= xpForNextLevel) {
      experiencePoints -= xpForNextLevel;
      level++;
      leveledUp = true;
    }

    updatedAt = DateTime.now();
    return leveledUp;
  }

  // Get most productive hour
  int? get mostProductiveHour {
    if (hourlyProductivity.isEmpty) return null;
    return hourlyProductivity.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Get most productive day
  int? get mostProductiveWeekday {
    if (weekdayProductivity.isEmpty) return null;
    return weekdayProductivity.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  String get mostProductiveWeekdayName {
    final day = mostProductiveWeekday;
    if (day == null) return 'N/A';
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[day - 1];
  }

  // Get unlocked achievements count
  int get unlockedAchievementsCount =>
      achievements.where((a) => a.isUnlocked).length;

  UserStatistics copyWith({
    String? id,
    int? totalTasksCreated,
    int? totalTasksCompleted,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletedDate,
    int? totalFocusMinutes,
    int? totalPomodoroSessions,
    int? level,
    int? experiencePoints,
    List<Achievement>? achievements,
    List<DailyStats>? dailyStats,
    Map<String, int>? categoryCompletionCount,
    Map<int, int>? hourlyProductivity,
    Map<int, int>? weekdayProductivity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserStatistics(
      id: id ?? this.id,
      totalTasksCreated: totalTasksCreated ?? this.totalTasksCreated,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      totalFocusMinutes: totalFocusMinutes ?? this.totalFocusMinutes,
      totalPomodoroSessions:
          totalPomodoroSessions ?? this.totalPomodoroSessions,
      level: level ?? this.level,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      achievements: achievements ?? List.from(this.achievements),
      dailyStats: dailyStats ?? List.from(this.dailyStats),
      categoryCompletionCount:
          categoryCompletionCount ?? Map.from(this.categoryCompletionCount),
      hourlyProductivity:
          hourlyProductivity ?? Map.from(this.hourlyProductivity),
      weekdayProductivity:
          weekdayProductivity ?? Map.from(this.weekdayProductivity),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'total_tasks_created': totalTasksCreated,
        'total_tasks_completed': totalTasksCompleted,
        'current_streak': currentStreak,
        'longest_streak': longestStreak,
        'last_completed_date': lastCompletedDate?.toIso8601String(),
        'total_focus_minutes': totalFocusMinutes,
        'total_pomodoro_sessions': totalPomodoroSessions,
        'level': level,
        'experience_points': experiencePoints,
        'achievements': achievements.map((a) => a.toJson()).toList(),
        'daily_stats': dailyStats.map((d) => d.toJson()).toList(),
        'category_completion_count': categoryCompletionCount,
        'hourly_productivity':
            hourlyProductivity.map((k, v) => MapEntry(k.toString(), v)),
        'weekday_productivity':
            weekdayProductivity.map((k, v) => MapEntry(k.toString(), v)),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  factory UserStatistics.fromJson(Map<String, dynamic> json) => UserStatistics(
        id: json['id'] as String?,
        totalTasksCreated: json['total_tasks_created'] as int? ?? 0,
        totalTasksCompleted: json['total_tasks_completed'] as int? ?? 0,
        currentStreak: json['current_streak'] as int? ?? 0,
        longestStreak: json['longest_streak'] as int? ?? 0,
        lastCompletedDate: json['last_completed_date'] != null
            ? DateTime.parse(json['last_completed_date'] as String)
            : null,
        totalFocusMinutes: json['total_focus_minutes'] as int? ?? 0,
        totalPomodoroSessions: json['total_pomodoro_sessions'] as int? ?? 0,
        level: json['level'] as int? ?? 1,
        experiencePoints: json['experience_points'] as int? ?? 0,
        achievements: (json['achievements'] as List<dynamic>?)
                ?.map((a) => Achievement.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
        dailyStats: (json['daily_stats'] as List<dynamic>?)
                ?.map((d) => DailyStats.fromJson(d as Map<String, dynamic>))
                .toList() ??
            [],
        categoryCompletionCount:
            (json['category_completion_count'] as Map<String, dynamic>?)
                    ?.cast<String, int>() ??
                {},
        hourlyProductivity:
            (json['hourly_productivity'] as Map<String, dynamic>?)
                    ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
                {},
        weekdayProductivity:
            (json['weekday_productivity'] as Map<String, dynamic>?)
                    ?.map((k, v) => MapEntry(int.parse(k), v as int)) ??
                {},
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );
}
