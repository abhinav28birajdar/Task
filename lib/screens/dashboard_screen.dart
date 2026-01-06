import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/hybrid_task_provider.dart';
import '../providers/hybrid_category_provider.dart';
import '../providers/settings_provider.dart';
import '../models/todo.dart';
import '../widgets/task_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/quick_action_fab.dart';
import 'add_edit_todo_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final taskProvider =
        Provider.of<HybridTaskProvider>(context, listen: false);
    await taskProvider.loadTasks();
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadData();
    setState(() => _isRefreshing = false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Consumer3<HybridTaskProvider, HybridCategoryProvider,
        SettingsProvider>(
      builder: (context, taskProvider, categoryProvider, settingsProvider, _) {
        final allTasks = taskProvider.allTodos;
        final todayTasks = _getTodayTasks(allTasks);
        final overdueTasks = _getOverdueTasks(allTasks);
        final upcomingTasks = _getUpcomingTasks(allTasks);
        final completedToday = _getCompletedTodayCount(allTasks);
        final pendingCount = allTasks.where((t) => !t.isCompleted).length;
        final streak = _calculateStreak(allTasks);

        return RefreshIndicator(
          onRefresh: _refreshData,
          color: theme.primaryColor,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Custom App Bar with Welcome Message
              SliverAppBar(
                expandedHeight: 140,
                floating: true,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getGreeting(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: theme.textTheme.bodyMedium?.color
                                          ?.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    settingsProvider.userName ?? 'User',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Profile Avatar
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/profile'),
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                    theme.primaryColor.withOpacity(0.1),
                                child: Icon(
                                  Icons.person_outline,
                                  color: theme.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('EEEE, MMMM d').format(DateTime.now()),
                          style: TextStyle(
                            fontSize: 14,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Stats Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats Row
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            StatsCard(
                              title: 'Total Tasks',
                              value: allTasks.length.toString(),
                              icon: Icons.list_alt_rounded,
                              color: theme.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            StatsCard(
                              title: 'Completed Today',
                              value: completedToday.toString(),
                              icon: Icons.check_circle_outline_rounded,
                              color: const Color(0xFF22C55E),
                            ),
                            const SizedBox(width: 12),
                            StatsCard(
                              title: 'Pending',
                              value: pendingCount.toString(),
                              icon: Icons.pending_actions_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 12),
                            StatsCard(
                              title: 'Overdue',
                              value: overdueTasks.length.toString(),
                              icon: Icons.warning_amber_rounded,
                              color: const Color(0xFFEF4444),
                            ),
                            const SizedBox(width: 12),
                            StatsCard(
                              title: 'Streak',
                              value: '$streak 🔥',
                              icon: Icons.local_fire_department_rounded,
                              color: const Color(0xFFF97316),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Overdue Tasks Alert
                      if (overdueTasks.isNotEmpty) ...[
                        _buildOverdueAlert(overdueTasks),
                        const SizedBox(height: 24),
                      ],

                      // Today's Tasks Section
                      _buildSectionHeader(
                        context,
                        title: "Today's Tasks",
                        count: todayTasks.length,
                        onSeeAll: () => Navigator.pushNamed(context, '/tasks'),
                      ),
                    ],
                  ),
                ),
              ),

              // Today's Tasks List
              if (todayTasks.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyState(
                    icon: Icons.wb_sunny_outlined,
                    title: 'No tasks for today',
                    subtitle: 'Enjoy your free time or add a new task!',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = todayTasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TaskCard(
                            task: task,
                            onTap: () => _navigateToTaskDetail(task),
                            onComplete: () => _toggleTaskComplete(task),
                            categoryProvider: categoryProvider,
                          ),
                        );
                      },
                      childCount: todayTasks.length > 5 ? 5 : todayTasks.length,
                    ),
                  ),
                ),

              // Upcoming Tasks Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: _buildSectionHeader(
                    context,
                    title: 'Upcoming (Next 3 Days)',
                    count: upcomingTasks.length,
                    onSeeAll: () => Navigator.pushNamed(context, '/calendar'),
                  ),
                ),
              ),

              if (upcomingTasks.isEmpty)
                SliverToBoxAdapter(
                  child: _buildEmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'No upcoming tasks',
                    subtitle: 'Plan ahead by scheduling tasks!',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = upcomingTasks[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: TaskCard(
                            task: task,
                            onTap: () => _navigateToTaskDetail(task),
                            onComplete: () => _toggleTaskComplete(task),
                            showDate: true,
                            categoryProvider: categoryProvider,
                          ),
                        );
                      },
                      childCount:
                          upcomingTasks.length > 3 ? 3 : upcomingTasks.length,
                    ),
                  ),
                ),

              // Bottom padding for FAB
              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required int count,
    VoidCallback? onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Text('See All'),
          ),
      ],
    );
  }

  Widget _buildOverdueAlert(List<Todo> overdueTasks) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFEF4444).withOpacity(0.1),
            const Color(0xFFEF4444).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFEF4444),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${overdueTasks.length} Overdue Task${overdueTasks.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'These tasks need your immediate attention',
                  style: TextStyle(
                    fontSize: 13,
                    color: const Color(0xFFEF4444).withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/tasks',
                arguments: {'filter': 'overdue'}),
            icon: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFFEF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            icon,
            size: 64,
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.color
                  ?.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning,';
    } else if (hour < 17) {
      return 'Good Afternoon,';
    } else {
      return 'Good Evening,';
    }
  }

  List<Todo> _getTodayTasks(List<Todo> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return tasks.where((task) {
      if (task.dueDate == null) return false;
      final taskDate =
          DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return taskDate.isAtSameMomentAs(today) && !task.isCompleted;
    }).toList();
  }

  List<Todo> _getOverdueTasks(List<Todo> tasks) {
    return tasks.where((task) => task.isOverdue).toList();
  }

  List<Todo> _getUpcomingTasks(List<Todo> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final threeDaysLater = today.add(const Duration(days: 3));
    return tasks.where((task) {
      if (task.dueDate == null || task.isCompleted) return false;
      final taskDate =
          DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
      return taskDate.isAfter(today) && taskDate.isBefore(threeDaysLater);
    }).toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
  }

  int _getCompletedTodayCount(List<Todo> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return tasks.where((task) {
      if (task.completionDate == null) return false;
      final completedDate = DateTime(task.completionDate!.year,
          task.completionDate!.month, task.completionDate!.day);
      return completedDate.isAtSameMomentAs(today);
    }).length;
  }

  int _calculateStreak(List<Todo> tasks) {
    // Simple streak calculation - count consecutive days with completed tasks
    final completedTasks = tasks.where((t) => t.isCompleted).toList();
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

  void _navigateToTaskDetail(Todo task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTodoScreen(existingTodo: task),
      ),
    );
  }

  void _toggleTaskComplete(Todo task) {
    final taskProvider =
        Provider.of<HybridTaskProvider>(context, listen: false);
    taskProvider.updateTodo(task.copyWith(
      isCompleted: !task.isCompleted,
      completionDate: !task.isCompleted ? DateTime.now() : null,
    ));
  }
}
