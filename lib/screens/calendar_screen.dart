import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/hybrid_task_provider.dart';
import '../providers/hybrid_category_provider.dart';
import '../models/todo.dart';
import '../widgets/task_card.dart';
import 'add_edit_todo_screen.dart';

enum CalendarViewMode { month, week, agenda }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();
  CalendarViewMode _viewMode = CalendarViewMode.month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _viewMode = CalendarViewMode.values[_tabController.index];
      });
    });
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
          'Calendar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
                _focusedMonth = DateTime.now();
              });
            },
            icon: const Icon(Icons.today_rounded),
            tooltip: 'Today',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.primaryColor,
          unselectedLabelColor:
              theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
          indicatorColor: theme.primaryColor,
          tabs: const [
            Tab(text: 'Month'),
            Tab(text: 'Week'),
            Tab(text: 'Agenda'),
          ],
        ),
      ),
      body: Consumer2<HybridTaskProvider, HybridCategoryProvider>(
        builder: (context, taskProvider, categoryProvider, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildMonthView(taskProvider, categoryProvider),
              _buildWeekView(taskProvider, categoryProvider),
              _buildAgendaView(taskProvider, categoryProvider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createTaskForDate(_selectedDate),
        heroTag: 'calendar_fab',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildMonthView(
    HybridTaskProvider taskProvider,
    HybridCategoryProvider categoryProvider,
  ) {
    return Column(
      children: [
        // Month Header
        _buildMonthHeader(),
        // Calendar Grid
        Expanded(
          child: _buildCalendarGrid(taskProvider),
        ),
        // Selected Day Tasks
        _buildDayTasksSheet(taskProvider, categoryProvider),
      ],
    );
  }

  Widget _buildMonthHeader() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month - 1,
                );
              });
            },
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          GestureDetector(
            onTap: () => _showMonthPicker(),
            child: Text(
              DateFormat('MMMM yyyy').format(_focusedMonth),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month + 1,
                );
              });
            },
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(HybridTaskProvider taskProvider) {
    final theme = Theme.of(context);
    final firstDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final firstWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    // Calculate previous month days to show
    final prevMonthDays = firstWeekday - 1;
    final prevMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    final daysInPrevMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 0).day;

    return Column(
      children: [
        // Weekday Headers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 8),
        // Calendar Days
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              DateTime date;
              bool isCurrentMonth = true;

              if (index < prevMonthDays) {
                // Previous month
                date = DateTime(
                  prevMonth.year,
                  prevMonth.month,
                  daysInPrevMonth - prevMonthDays + index + 1,
                );
                isCurrentMonth = false;
              } else if (index >= prevMonthDays + daysInMonth) {
                // Next month
                date = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month + 1,
                  index - prevMonthDays - daysInMonth + 1,
                );
                isCurrentMonth = false;
              } else {
                // Current month
                date = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month,
                  index - prevMonthDays + 1,
                );
              }

              final tasksForDay = _getTasksForDate(taskProvider, date);
              final isSelected = _isSameDay(date, _selectedDate);
              final isToday = _isSameDay(date, DateTime.now());

              return _buildDayCell(
                date: date,
                isCurrentMonth: isCurrentMonth,
                isSelected: isSelected,
                isToday: isToday,
                taskCount: tasksForDay.length,
                hasOverdue: tasksForDay.any((t) => t.isOverdue),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell({
    required DateTime date,
    required bool isCurrentMonth,
    required bool isSelected,
    required bool isToday,
    required int taskCount,
    required bool hasOverdue,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDate = date;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.primaryColor
              : isToday
                  ? theme.primaryColor.withOpacity(0.1)
                  : null,
          borderRadius: BorderRadius.circular(10),
          border: isToday && !isSelected
              ? Border.all(color: theme.primaryColor, width: 1.5)
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday || isSelected ? FontWeight.bold : null,
                color: isSelected
                    ? Colors.white
                    : isCurrentMonth
                        ? theme.textTheme.bodyLarge?.color
                        : theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
              ),
            ),
            if (taskCount > 0)
              Container(
                margin: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: hasOverdue
                            ? Colors.red
                            : isSelected
                                ? Colors.white
                                : theme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (taskCount > 1) ...[
                      const SizedBox(width: 2),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.7)
                              : theme.primaryColor.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayTasksSheet(
    HybridTaskProvider taskProvider,
    HybridCategoryProvider categoryProvider,
  ) {
    final tasks = _getTasksForDate(taskProvider, _selectedDate);
    final isToday = _isSameDay(_selectedDate, DateTime.now());

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday
                          ? 'Today'
                          : DateFormat('EEEE, MMM d').format(_selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${tasks.length} task${tasks.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _createTaskForDate(_selectedDate),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          // Tasks List
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_available_outlined,
                          size: 48,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No tasks for this day',
                          style: TextStyle(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: CompactTaskCard(
                          task: task,
                          onTap: () => _navigateToTask(task),
                          onComplete: () =>
                              _toggleTaskComplete(taskProvider, task),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekView(
    HybridTaskProvider taskProvider,
    HybridCategoryProvider categoryProvider,
  ) {
    final weekStart = _selectedDate.subtract(
      Duration(days: _selectedDate.weekday - 1),
    );

    return Column(
      children: [
        // Week Navigation
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(
                      const Duration(days: 7),
                    );
                  });
                },
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekStart.add(const Duration(days: 6)))}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.add(
                      const Duration(days: 7),
                    );
                  });
                },
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        // Week Days Horizontal Scroll
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 7,
            itemBuilder: (context, index) {
              final date = weekStart.add(Duration(days: index));
              final isSelected = _isSameDay(date, _selectedDate);
              final isToday = _isSameDay(date, DateTime.now());
              final tasks = _getTasksForDate(taskProvider, date);

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  width: 56,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : isToday
                            ? Theme.of(context).primaryColor.withOpacity(0.1)
                            : Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday && !isSelected
                        ? Border.all(
                            color: Theme.of(context).primaryColor,
                            width: 1.5,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      if (tasks.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withOpacity(0.3)
                                : Theme.of(context)
                                    .primaryColor
                                    .withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tasks.length.toString(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        // Selected Day Tasks
        Expanded(
          child: _buildTaskListForDate(
            taskProvider,
            categoryProvider,
            _selectedDate,
          ),
        ),
      ],
    );
  }

  Widget _buildAgendaView(
    HybridTaskProvider taskProvider,
    HybridCategoryProvider categoryProvider,
  ) {
    final allTasks = taskProvider.allTodos
        .where((t) => !t.isCompleted && t.dueDate != null)
        .toList()
      ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!));

    // Group tasks by date
    final Map<DateTime, List<Todo>> groupedTasks = {};
    for (final task in allTasks) {
      final date = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      groupedTasks.putIfAbsent(date, () => []).add(task);
    }

    final sortedDates = groupedTasks.keys.toList()..sort();

    return allTasks.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.event_note_outlined,
                  size: 64,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No upcoming tasks',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.color
                        ?.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final tasks = groupedTasks[date]!;
              final isToday = _isSameDay(date, DateTime.now());
              final isPast = date.isBefore(DateTime.now());

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isPast && !isToday
                                ? Colors.red.withOpacity(0.1)
                                : isToday
                                    ? Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.1)
                                    : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isToday
                                ? 'Today'
                                : DateFormat('EEE, MMM d').format(date),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isPast && !isToday
                                  ? Colors.red
                                  : isToday
                                      ? Theme.of(context).primaryColor
                                      : Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${tasks.length} task${tasks.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tasks
                  ...tasks.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: TaskCard(
                          task: task,
                          onTap: () => _navigateToTask(task),
                          onComplete: () =>
                              _toggleTaskComplete(taskProvider, task),
                          categoryProvider: categoryProvider,
                        ),
                      )),
                  const SizedBox(height: 8),
                ],
              );
            },
          );
  }

  Widget _buildTaskListForDate(
    HybridTaskProvider taskProvider,
    HybridCategoryProvider categoryProvider,
    DateTime date,
  ) {
    final tasks = _getTasksForDate(taskProvider, date);

    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.task_outlined,
              size: 48,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks for this day',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _createTaskForDate(date),
              child: const Text('Add Task'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: TaskCard(
            task: task,
            onTap: () => _navigateToTask(task),
            onComplete: () => _toggleTaskComplete(taskProvider, task),
            categoryProvider: categoryProvider,
          ),
        );
      },
    );
  }

  List<Todo> _getTasksForDate(HybridTaskProvider provider, DateTime date) {
    return provider.allTodos.where((task) {
      if (task.dueDate == null) return false;
      return _isSameDay(task.dueDate!, date);
    }).toList()
      ..sort((a, b) {
        // Sort by completion status first, then by priority
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1;
        }
        return a.priority.compareTo(b.priority);
      });
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _showMonthPicker() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _focusedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() {
        _focusedMonth = DateTime(picked.year, picked.month);
        _selectedDate = picked;
      });
    }
  }

  void _createTaskForDate(DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTodoScreen(
          initialDueDate: date,
        ),
      ),
    );
  }

  void _navigateToTask(Todo task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditTodoScreen(existingTodo: task),
      ),
    );
  }

  void _toggleTaskComplete(HybridTaskProvider provider, Todo task) {
    provider.updateTodo(task.copyWith(
      isCompleted: !task.isCompleted,
      completionDate: !task.isCompleted ? DateTime.now() : null,
    ));
  }
}
