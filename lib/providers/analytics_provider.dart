import 'package:flutter/material.dart';
import '../data/models/task_model.dart';

class AnalyticsProvider extends ChangeNotifier {
  List<TaskModel> tasks = [];

  /// Get completion rate for this week
  double getWeeklyCompletionRate() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekTasks = tasks.where((t) => t.createdAt.isAfter(weekAgo)).toList();

    if (weekTasks.isEmpty) return 0;
    final completed = weekTasks.where((t) => t.isCompleted).length;
    return (completed / weekTasks.length) * 100;
  }

  /// Get daily completion counts for last 30 days
  Map<DateTime, int> getDailyCompletionCounts() {
    final counts = <DateTime, int>{};

    for (int i = 0; i < 30; i++) {
      final day = DateTime.now().subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final completed = tasks
          .where((t) =>
              t.isCompleted &&
              t.updatedAt.isAfter(dayStart) &&
              t.updatedAt.isBefore(dayEnd))
          .length;

      counts[dayStart] = completed;
    }

    return counts;
  }

  /// Get task counts by priority
  Map<String, int> getTasksByPriority() {
    return {
      'high': tasks.where((t) => t.priority == 'high').length,
      'medium': tasks.where((t) => t.priority == 'medium').length,
      'low': tasks.where((t) => t.priority == 'low').length,
    };
  }

  /// Get task counts by status
  Map<String, int> getTasksByStatus() {
    return {
      'completed': tasks.where((t) => t.isCompleted).length,
      'pending': tasks.where((t) => !t.isCompleted).length,
    };
  }

  /// Get average time to completion (in hours)
  double getAverageCompletionTime() {
    final completed = tasks.where((t) => t.isCompleted).toList();
    if (completed.isEmpty) return 0;

    final totalHours = completed.fold<double>(0, (sum, task) {
      final hours = task.updatedAt.difference(task.createdAt).inHours;
      return sum + hours;
    });

    return totalHours / completed.length;
  }

  /// Get completion rate percentage
  int getCompletionRatePercentage() {
    if (tasks.isEmpty) return 0;
    final completed = tasks.where((t) => t.isCompleted).length;
    return ((completed / tasks.length) * 100).toInt();
  }

  /// Get total tasks by category
  Map<String, int> getTasksByCategory() {
    final categories = <String, int>{};
    for (final task in tasks) {
      categories[task.category] = (categories[task.category] ?? 0) + 1;
    }
    return categories;
  }

  /// Get most productive day
  String getMostProductiveDay() {
    final dailyCounts = getDailyCompletionCounts();
    if (dailyCounts.isEmpty) return 'N/A';

    final maxEntry =
        dailyCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[maxEntry.key.weekday - 1];
  }

  /// Get this week's data
  List<int> getThisWeek() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekCounts = <int>[];

    for (int i = 6; i >= 0; i--) {
      final day = DateTime.now().subtract(Duration(days: i));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      final completed = tasks
          .where((t) =>
              t.isCompleted &&
              t.updatedAt.isAfter(dayStart) &&
              t.updatedAt.isBefore(dayEnd))
          .length;

      weekCounts.add(completed);
    }

    return weekCounts;
  }

  /// Update tasks
  void updateTasks(List<TaskModel> newTasks) {
    tasks = newTasks;
    notifyListeners();
  }
}
