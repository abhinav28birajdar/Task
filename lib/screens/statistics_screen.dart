import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import '../providers/hybrid_task_provider.dart';
import '../providers/hybrid_category_provider.dart';
import '../models/todo.dart';
import '../models/category.dart';
import '../widgets/stats_card.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Statistics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor:
              theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          indicatorColor: theme.primaryColor,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Charts'),
            Tab(text: 'Achievements'),
          ],
        ),
      ),
      body: Consumer2<HybridTaskProvider, HybridCategoryProvider>(
        builder: (context, taskProvider, categoryProvider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(taskProvider, categoryProvider),
              _buildChartsTab(taskProvider, categoryProvider),
              _buildAchievementsTab(taskProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(
    HybridTaskProvider taskProvider,
    HybridCategoryProvider categoryProvider,
  ) {
    final allTasks = taskProvider.allTodos;
    final completedTasks = allTasks.where((t) => t.isCompleted).toList();
    final pendingTasks = allTasks.where((t) => !t.isCompleted).toList();
    final overdueTasks = pendingTasks.where((t) => t.isOverdue).toList();
    final completionRate = allTasks.isEmpty
        ? 0.0
        : (completedTasks.length / allTasks.length * 100);

    // Calculate streak
    final streak = _calculateStreak(completedTasks);
    final longestStreak = _calculateLongestStreak(completedTasks);

    // Today's stats
    final now = DateTime.now();
    final todayCompleted = completedTasks.where((t) {
      if (t.completionDate == null) return false;
      return t.completionDate!.year == now.year &&
          t.completionDate!.month == now.month &&
          t.completionDate!.day == now.day;
    }).length;

    final todayCreated = allTasks.where((t) {
      return t.creationDate.year == now.year &&
          t.creationDate.month == now.month &&
          t.creationDate.day == now.day;
    }).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Stats Cards
          Row(
            children: [
              Expanded(
                child: LargeStatsCard(
                  title: 'Total Tasks',
                  value: allTasks.length.toString(),
                  subtitle: '$todayCreated created today',
                  icon: Icons.list_alt_rounded,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatsCard(
                  title: 'Completed',
                  value: completedTasks.length.toString(),
                  icon: Icons.check_circle_outline_rounded,
                  color: const Color(0xFF22C55E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatsCard(
                  title: 'Pending',
                  value: pendingTasks.length.toString(),
                  icon: Icons.pending_actions_rounded,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatsCard(
                  title: 'Overdue',
                  value: overdueTasks.length.toString(),
                  icon: Icons.warning_amber_rounded,
                  color: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Completion Rate
          ProgressStatsCard(
            title: 'Overall Completion Rate',
            completed: completedTasks.length,
            total: allTasks.isEmpty ? 1 : allTasks.length,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 24),

          // Streak Section
          const Text(
            'Productivity Streak',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStreakCard(
                  title: 'Current Streak',
                  value: streak,
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFF97316),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStreakCard(
                  title: 'Longest Streak',
                  value: longestStreak,
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFFEAB308),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Today's Summary
          const Text(
            "Today's Summary",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  icon: Icons.add_task_rounded,
                  label: 'Tasks Created',
                  value: todayCreated.toString(),
                  color: Theme.of(context).primaryColor,
                ),
                const Divider(height: 24),
                _buildSummaryRow(
                  icon: Icons.check_circle_rounded,
                  label: 'Tasks Completed',
                  value: todayCompleted.toString(),
                  color: const Color(0xFF22C55E),
                ),
                const Divider(height: 24),
                _buildSummaryRow(
                  icon: Icons.trending_up_rounded,
                  label: 'Completion Rate',
                  value: '${completionRate.toStringAsFixed(1)}%',
                  color: const Color(0xFF06B6D4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Category Distribution
          if (categoryProvider.categories.isNotEmpty) ...[
            const Text(
              'Tasks by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildCategoryDistribution(allTasks, categoryProvider.categories),
          ],
        ],
      ),
    );
  }

  Widget _buildChartsTab(
    HybridTaskProvider taskProvider,
    HybridCategoryProvider categoryProvider,
  ) {
    final allTasks = taskProvider.allTodos;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly Completion Chart
          const Text(
            'Weekly Completion Trend',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildWeeklyChart(allTasks),
          const SizedBox(height: 24),

          // Priority Distribution
          const Text(
            'Priority Distribution',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildPriorityChart(allTasks),
          const SizedBox(height: 24),

          // Productivity Heatmap
          const Text(
            'Monthly Activity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildMonthlyHeatmap(allTasks),
          const SizedBox(height: 24),

          // Most Productive Hours
          const Text(
            'Productive Hours',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildHourlyChart(allTasks),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(HybridTaskProvider taskProvider) {
    final allTasks = taskProvider.allTodos;
    final completedCount = allTasks.where((t) => t.isCompleted).length;
    final streak =
        _calculateStreak(allTasks.where((t) => t.isCompleted).toList());

    final achievements = [
      _Achievement(
        title: 'First Task',
        description: 'Complete your first task',
        icon: Icons.star_rounded,
        color: const Color(0xFFEAB308),
        isUnlocked: completedCount >= 1,
        progress: completedCount >= 1 ? 1.0 : 0.0,
      ),
      _Achievement(
        title: 'Getting Started',
        description: 'Complete 10 tasks',
        icon: Icons.rocket_launch_rounded,
        color: const Color(0xFF06B6D4),
        isUnlocked: completedCount >= 10,
        progress: math.min(completedCount / 10, 1.0),
      ),
      _Achievement(
        title: 'Task Master',
        description: 'Complete 50 tasks',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFF59E0B),
        isUnlocked: completedCount >= 50,
        progress: math.min(completedCount / 50, 1.0),
      ),
      _Achievement(
        title: 'Productivity Pro',
        description: 'Complete 100 tasks',
        icon: Icons.workspace_premium_rounded,
        color: const Color(0xFF8B5CF6),
        isUnlocked: completedCount >= 100,
        progress: math.min(completedCount / 100, 1.0),
      ),
      _Achievement(
        title: 'Task Legend',
        description: 'Complete 500 tasks',
        icon: Icons.diamond_rounded,
        color: const Color(0xFFEC4899),
        isUnlocked: completedCount >= 500,
        progress: math.min(completedCount / 500, 1.0),
      ),
      _Achievement(
        title: 'On Fire',
        description: 'Maintain a 3-day streak',
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFF97316),
        isUnlocked: streak >= 3,
        progress: math.min(streak / 3, 1.0),
      ),
      _Achievement(
        title: 'Consistent',
        description: 'Maintain a 7-day streak',
        icon: Icons.whatshot_rounded,
        color: const Color(0xFFEF4444),
        isUnlocked: streak >= 7,
        progress: math.min(streak / 7, 1.0),
      ),
      _Achievement(
        title: 'Unstoppable',
        description: 'Maintain a 30-day streak',
        icon: Icons.auto_awesome_rounded,
        color: const Color(0xFF10B981),
        isUnlocked: streak >= 30,
        progress: math.min(streak / 30, 1.0),
      ),
    ];

    final unlockedCount = achievements.where((a) => a.isUnlocked).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Achievements Unlocked',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$unlockedCount / ${achievements.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Achievement List
          ...achievements.map((achievement) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAchievementCard(achievement),
              )),
        ],
      ),
    );
  }

  Widget _buildStreakCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                ' days',
                style: TextStyle(
                  fontSize: 14,
                  color: color.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.7),
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDistribution(
      List<Todo> tasks, List<Category> categories) {
    final categoryCount = <String, int>{};
    for (var task in tasks) {
      if (task.categoryId != null) {
        categoryCount[task.categoryId!] =
            (categoryCount[task.categoryId!] ?? 0) + 1;
      }
    }

    if (categoryCount.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No categorized tasks yet'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: categoryCount.entries.map((entry) {
          final category = categories.firstWhere(
            (c) => c.id == entry.key,
            orElse: () => Category(
              name: 'Unknown',
              colorValue: Colors.grey.value,
              iconData: Icons.folder,
            ),
          );
          final percentage =
              (entry.value / tasks.length * 100).toStringAsFixed(1);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    category.iconData,
                    color: category.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: entry.value / tasks.length,
                          backgroundColor: category.color.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation(category.color),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: category.color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWeeklyChart(List<Todo> tasks) {
    final now = DateTime.now();
    final weekData = <String, int>{};

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayName = DateFormat('E').format(date);
      weekData[dayName] = tasks.where((t) {
        if (t.completionDate == null) return false;
        return t.completionDate!.year == date.year &&
            t.completionDate!.month == date.month &&
            t.completionDate!.day == date.day;
      }).length;
    }

    final maxValue = weekData.values.isEmpty
        ? 1
        : weekData.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekData.entries.map((entry) {
                final height =
                    maxValue > 0 ? (entry.value / maxValue * 120) : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: height > 0 ? height : 4,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityChart(List<Todo> tasks) {
    final priorityCount = {
      'High': tasks.where((t) => t.priority == 1).length,
      'Medium': tasks.where((t) => t.priority == 2).length,
      'Low': tasks.where((t) => t.priority == 3).length,
    };

    final priorityColors = {
      'High': const Color(0xFFEF4444),
      'Medium': const Color(0xFFF59E0B),
      'Low': const Color(0xFF22C55E),
    };

    final total = tasks.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: priorityCount.entries.map((entry) {
          final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: priorityColors[entry.key],
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${entry.key} Priority',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  '${entry.value} (${percentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: priorityColors[entry.key],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyHeatmap(List<Todo> tasks) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(now),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: daysInMonth,
            itemBuilder: (context, index) {
              final date = DateTime(now.year, now.month, index + 1);
              final count = tasks.where((t) {
                if (t.completionDate == null) return false;
                return t.completionDate!.year == date.year &&
                    t.completionDate!.month == date.month &&
                    t.completionDate!.day == date.day;
              }).length;

              final opacity = count == 0
                  ? 0.1
                  : count == 1
                      ? 0.3
                      : count == 2
                          ? 0.5
                          : count < 5
                              ? 0.7
                              : 1.0;

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(opacity),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 10,
                      color: opacity > 0.5
                          ? Colors.white
                          : Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChart(List<Todo> tasks) {
    final hourlyCount = <int, int>{};
    for (var task in tasks.where((t) => t.completionDate != null)) {
      final hour = task.completionDate!.hour;
      hourlyCount[hour] = (hourlyCount[hour] ?? 0) + 1;
    }

    final mostProductiveHour = hourlyCount.isEmpty
        ? null
        : hourlyCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mostProductiveHour != null)
            Row(
              children: [
                Icon(
                  mostProductiveHour < 12
                      ? Icons.wb_sunny_rounded
                      : mostProductiveHour < 18
                          ? Icons.wb_twilight_rounded
                          : Icons.nights_stay_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Most productive at ${_formatHour(mostProductiveHour)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            )
          else
            const Text('Complete some tasks to see your productive hours!'),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(_Achievement achievement) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: achievement.isUnlocked
            ? achievement.color.withOpacity(0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.isUnlocked
              ? achievement.color.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: achievement.isUnlocked
                  ? achievement.color.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              achievement.icon,
              color: achievement.isUnlocked ? achievement.color : Colors.grey,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: achievement.isUnlocked
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: achievement.isUnlocked
                        ? Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.7)
                        : Colors.grey.withOpacity(0.7),
                  ),
                ),
                if (!achievement.isUnlocked) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: achievement.progress,
                      backgroundColor: Colors.grey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation(achievement.color),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (achievement.isUnlocked)
            Icon(
              Icons.check_circle_rounded,
              color: achievement.color,
              size: 24,
            ),
        ],
      ),
    );
  }

  int _calculateStreak(List<Todo> completedTasks) {
    if (completedTasks.isEmpty) return 0;

    final sortedDates = completedTasks
        .where((t) => t.completionDate != null)
        .map((t) => DateTime(t.completionDate!.year, t.completionDate!.month,
            t.completionDate!.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (sortedDates.isEmpty) return 0;

    int streak = 0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (int i = 0; i < sortedDates.length; i++) {
      final expectedDate = today.subtract(Duration(days: i));
      if (sortedDates.contains(expectedDate)) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }

  int _calculateLongestStreak(List<Todo> completedTasks) {
    if (completedTasks.isEmpty) return 0;

    final sortedDates = completedTasks
        .where((t) => t.completionDate != null)
        .map((t) => DateTime(t.completionDate!.year, t.completionDate!.month,
            t.completionDate!.day))
        .toSet()
        .toList()
      ..sort();

    if (sortedDates.isEmpty) return 0;

    int maxStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sortedDates.length; i++) {
      if (sortedDates[i].difference(sortedDates[i - 1]).inDays == 1) {
        currentStreak++;
        maxStreak = math.max(maxStreak, currentStreak);
      } else {
        currentStreak = 1;
      }
    }

    return maxStreak;
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
}

class _Achievement {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final double progress;

  _Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.progress,
  });
}
