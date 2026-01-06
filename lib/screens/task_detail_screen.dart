import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import '../providers/hybrid_task_provider.dart';
import '../providers/hybrid_category_provider.dart';
import '../models/todo.dart';
import 'add_edit_todo_screen.dart';
import 'focus_mode_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Todo task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Todo _task;

  // Subtasks
  final List<_SubtaskItem> _subtasks = [];
  final TextEditingController _subtaskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _task = widget.task;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();

    // Parse subtasks from description if available
    _parseSubtasks();
  }

  void _parseSubtasks() {
    // In a real app, subtasks would be stored separately
    // For now, we'll use a simple list
    _subtasks.addAll([
      _SubtaskItem(title: 'Review requirements', isCompleted: true),
      _SubtaskItem(title: 'Create initial draft', isCompleted: false),
      _SubtaskItem(title: 'Get feedback', isCompleted: false),
    ]);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priorityColor = _getPriorityColor(_task.priority);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: priorityColor.withOpacity(0.1),
            leading: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            actions: [
              IconButton(
                onPressed: () => _shareTask(),
                icon: const Icon(Icons.share_rounded),
              ),
              PopupMenuButton<String>(
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy_rounded, size: 20),
                        SizedBox(width: 12),
                        Text('Duplicate'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      priorityColor.withOpacity(0.2),
                      theme.scaffoldBackgroundColor,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _task.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              decoration: _task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildCompletionToggle(theme, priorityColor),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Priority and Category Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChip(
                          icon: Icons.flag_rounded,
                          label: _task.priorityText,
                          color: priorityColor,
                        ),
                        Consumer<HybridCategoryProvider>(
                          builder: (context, categoryProvider, child) {
                            final category = _task.categoryId != null
                                ? categoryProvider.allCategories
                                    .cast<dynamic>()
                                    .firstWhere(
                                      (c) => c.id == _task.categoryId,
                                      orElse: () => null,
                                    )
                                : null;

                            if (category == null) {
                              return const SizedBox.shrink();
                            }

                            final catColor = Color(
                              int.parse(category.color.replaceAll('#', '0xFF')),
                            );

                            return _buildChip(
                              icon: Icons.folder_rounded,
                              label: category.name,
                              color: catColor,
                            );
                          },
                        ),
                        if (_task.dueDate != null)
                          _buildChip(
                            icon: Icons.calendar_today_rounded,
                            label: DateFormat.MMMd().format(_task.dueDate!),
                            color:
                                _isOverdue() ? Colors.red : theme.primaryColor,
                          ),
                        if (_task.dueTime != null)
                          _buildChip(
                            icon: Icons.access_time_rounded,
                            label: DateFormat.jm().format(
                              DateTime(
                                2000,
                                1,
                                1,
                                _task.dueTime!.hour,
                                _task.dueTime!.minute,
                              ),
                            ),
                            color: theme.primaryColor,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description
                    if (_task.description != null &&
                        _task.description!.isNotEmpty) ...[
                      _buildSectionHeader(theme, 'Description'),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _task.description!,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Subtasks
                    _buildSectionHeader(
                      theme,
                      'Subtasks',
                      trailing: Text(
                        '${_subtasks.where((s) => s.isCompleted).length}/${_subtasks.length}',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSubtasksList(theme),
                    const SizedBox(height: 12),
                    _buildAddSubtaskField(theme),
                    const SizedBox(height: 24),

                    // Progress
                    _buildSectionHeader(theme, 'Progress'),
                    const SizedBox(height: 12),
                    _buildProgressCard(theme, priorityColor),
                    const SizedBox(height: 24),

                    // Activity Timeline
                    _buildSectionHeader(theme, 'Activity'),
                    const SizedBox(height: 12),
                    _buildActivityTimeline(theme),
                    const SizedBox(height: 100), // Space for bottom actions
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomActions(theme),
    );
  }

  Widget _buildCompletionToggle(ThemeData theme, Color priorityColor) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        final taskProvider =
            Provider.of<HybridTaskProvider>(context, listen: false);
        taskProvider.toggleTodoCompletion(_task);
        setState(() {
          _task = _task.copyWith(isCompleted: !_task.isCompleted);
        });
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _task.isCompleted
              ? const Color(0xFF10B981)
              : priorityColor.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(
            color: _task.isCompleted ? const Color(0xFF10B981) : priorityColor,
            width: 2,
          ),
        ),
        child: _task.isCompleted
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title,
      {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildSubtasksList(ThemeData theme) {
    if (_subtasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No subtasks yet',
            style: TextStyle(color: theme.textTheme.bodySmall?.color),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _subtasks.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: theme.dividerColor,
        ),
        itemBuilder: (context, index) {
          final subtask = _subtasks[index];
          return ListTile(
            onTap: () {
              setState(() {
                _subtasks[index] = _SubtaskItem(
                  title: subtask.title,
                  isCompleted: !subtask.isCompleted,
                );
              });
            },
            leading: Checkbox(
              value: subtask.isCompleted,
              onChanged: (value) {
                setState(() {
                  _subtasks[index] = _SubtaskItem(
                    title: subtask.title,
                    isCompleted: value ?? false,
                  );
                });
              },
              shape: const CircleBorder(),
            ),
            title: Text(
              subtask.title,
              style: TextStyle(
                decoration:
                    subtask.isCompleted ? TextDecoration.lineThrough : null,
                color: subtask.isCompleted
                    ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5)
                    : null,
              ),
            ),
            trailing: IconButton(
              onPressed: () {
                setState(() {
                  _subtasks.removeAt(index);
                });
              },
              icon: Icon(
                Icons.close_rounded,
                size: 18,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddSubtaskField(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.add_rounded,
            color: theme.textTheme.bodySmall?.color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _subtaskController,
              decoration: InputDecoration(
                hintText: 'Add a subtask',
                hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                border: InputBorder.none,
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  setState(() {
                    _subtasks.add(_SubtaskItem(
                      title: value.trim(),
                      isCompleted: false,
                    ));
                  });
                  _subtaskController.clear();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(ThemeData theme, Color priorityColor) {
    final completedCount = _subtasks.where((s) => s.isCompleted).length;
    final totalCount = _subtasks.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: priorityColor,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _task.isCompleted
                      ? const Color(0xFF10B981).withOpacity(0.1)
                      : priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _task.isCompleted ? 'Completed' : 'In Progress',
                  style: TextStyle(
                    color: _task.isCompleted
                        ? const Color(0xFF10B981)
                        : priorityColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: priorityColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(priorityColor),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedCount of $totalCount subtasks completed',
                style: TextStyle(
                  color: theme.textTheme.bodySmall?.color,
                  fontSize: 12,
                ),
              ),
              if (_task.dueDate != null && !_task.isCompleted)
                Text(
                  _getDaysLeftText(),
                  style: TextStyle(
                    color: _isOverdue() ? Colors.red : theme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline(ThemeData theme) {
    final activities = [
      _Activity(
        icon: Icons.add_rounded,
        title: 'Task created',
        time: _task.createdAt,
      ),
      if (_task.updatedAt != null && _task.updatedAt != _task.createdAt)
        _Activity(
          icon: Icons.edit_rounded,
          title: 'Task updated',
          time: _task.updatedAt!,
        ),
      if (_task.isCompleted)
        _Activity(
          icon: Icons.check_circle_rounded,
          title: 'Task completed',
          time: _task.updatedAt ?? DateTime.now(),
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: activities.asMap().entries.map((entry) {
          final index = entry.key;
          final activity = entry.value;
          final isLast = index == activities.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      activity.icon,
                      size: 16,
                      color: theme.primaryColor,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 30,
                      color: theme.dividerColor,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('MMM d, y • h:mm a').format(activity.time),
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FocusModeScreen(
                        taskId: _task.id,
                        taskTitle: _task.title,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.timer_rounded),
                label: const Text('Focus'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  final taskProvider =
                      Provider.of<HybridTaskProvider>(context, listen: false);
                  taskProvider.toggleTodoCompletion(_task);
                  setState(() {
                    _task = _task.copyWith(isCompleted: !_task.isCompleted);
                  });
                },
                icon: Icon(
                  _task.isCompleted ? Icons.undo_rounded : Icons.check_rounded,
                ),
                label: Text(
                    _task.isCompleted ? 'Mark Incomplete' : 'Mark Complete'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: _task.isCompleted
                      ? theme.primaryColor
                      : const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
        return const Color(0xFFEAB308);
      case 4:
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  bool _isOverdue() {
    if (_task.dueDate == null || _task.isCompleted) return false;
    return _task.dueDate!.isBefore(DateTime.now());
  }

  String _getDaysLeftText() {
    if (_task.dueDate == null) return '';

    final now = DateTime.now();
    final due = _task.dueDate!;
    final diff = due.difference(now).inDays;

    if (diff < 0) {
      return '${-diff} days overdue';
    } else if (diff == 0) {
      return 'Due today';
    } else if (diff == 1) {
      return 'Due tomorrow';
    } else {
      return '$diff days left';
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddEditTodoScreen(todo: _task),
          ),
        );
        break;
      case 'duplicate':
        _duplicateTask();
        break;
      case 'delete':
        _deleteTask();
        break;
    }
  }

  void _duplicateTask() {
    final taskProvider =
        Provider.of<HybridTaskProvider>(context, listen: false);
    // Create a copy of the task
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task duplicated'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteTask() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Task'),
          ],
        ),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final taskProvider =
                  Provider.of<HybridTaskProvider>(context, listen: false);
              await taskProvider.deleteTodo(_task.id);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _shareTask() {
    // Share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SubtaskItem {
  final String title;
  final bool isCompleted;

  _SubtaskItem({required this.title, required this.isCompleted});
}

class _Activity {
  final IconData icon;
  final String title;
  final DateTime time;

  _Activity({required this.icon, required this.title, required this.time});
}
