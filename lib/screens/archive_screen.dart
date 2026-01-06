import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/hybrid_task_provider.dart';
import '../providers/hybrid_category_provider.dart';
import '../models/todo.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  String _selectedFilter = 'all';
  String _sortBy = 'completedDate';
  bool _sortAscending = false;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Archive',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _showFilterOptions,
            icon: const Icon(Icons.filter_list_rounded),
            tooltip: 'Filter',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clearAll') {
                _showClearAllDialog();
              } else if (value == 'export') {
                _exportArchive();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Export Archive'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clearAll',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever_rounded,
                        size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Clear All', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer2<HybridTaskProvider, HybridCategoryProvider>(
        builder: (context, taskProvider, categoryProvider, child) {
          final completedTasks = _getFilteredTasks(taskProvider);

          if (completedTasks.isEmpty) {
            return _buildEmptyState(theme);
          }

          // Group tasks by completion date
          final groupedTasks = _groupTasksByDate(completedTasks);

          return Column(
            children: [
              // Stats Bar
              _buildStatsBar(theme, completedTasks),

              // Filter chips
              if (_startDate != null || _endDate != null)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Chip(
                        label: Text(
                          _getDateRangeText(),
                          style: const TextStyle(fontSize: 12),
                        ),
                        deleteIcon: const Icon(Icons.close_rounded, size: 16),
                        onDeleted: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                        backgroundColor: theme.primaryColor.withOpacity(0.1),
                      ),
                    ],
                  ),
                ),

              // Task List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedTasks.length,
                  itemBuilder: (context, index) {
                    final date = groupedTasks.keys.elementAt(index);
                    final tasks = groupedTasks[date]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                  color: theme.primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _formatDateHeader(date),
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${tasks.length} tasks',
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...tasks.map((task) => _buildArchivedTaskCard(
                              context,
                              task,
                              taskProvider,
                              categoryProvider,
                            )),
                        const SizedBox(height: 8),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_rounded,
              size: 80,
              color: theme.primaryColor.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Archive is Empty',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Completed tasks will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(ThemeData theme, List<Todo> tasks) {
    final totalTasks = tasks.length;
    final highPriority = tasks.where((t) => t.priority == 1).length;
    final thisWeek = tasks
        .where((t) =>
            t.updatedAt != null &&
            t.updatedAt!
                .isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.check_circle_rounded,
            value: totalTasks.toString(),
            label: 'Total',
            color: theme.primaryColor,
          ),
          _buildStatItem(
            icon: Icons.priority_high_rounded,
            value: highPriority.toString(),
            label: 'High Priority',
            color: const Color(0xFFEF4444),
          ),
          _buildStatItem(
            icon: Icons.date_range_rounded,
            value: thisWeek.toString(),
            label: 'This Week',
            color: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildArchivedTaskCard(
    BuildContext context,
    Todo task,
    HybridTaskProvider taskProvider,
    HybridCategoryProvider categoryProvider,
  ) {
    final theme = Theme.of(context);
    final category = task.categoryId != null
        ? categoryProvider.allCategories.cast<dynamic>().firstWhere(
              (c) => c.id == task.categoryId,
              orElse: () => null,
            )
        : null;

    return Dismissible(
      key: Key('archived_${task.id}'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.restore_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Restore',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_forever_rounded, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Restore task
          await taskProvider.toggleTodoCompletion(task);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Task restored'),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: 'Undo',
                  onPressed: () {
                    taskProvider.toggleTodoCompletion(task);
                  },
                ),
              ),
            );
          }
          return true;
        } else {
          // Delete task
          final confirmed = await _showDeleteConfirmation(context);
          if (confirmed == true) {
            await taskProvider.deleteTodo(task.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task permanently deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            return true;
          }
          return false;
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF10B981),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.lineThrough,
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (category != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse(
                                      category.color.replaceAll('#', '0xFF')) &
                                  0xFFFFFFFF,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(
                                int.parse(
                                    category.color.replaceAll('#', '0xFF')),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.updatedAt != null
                            ? DateFormat.MMMd().format(task.updatedAt!)
                            : 'Unknown',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'restore') {
                  await taskProvider.toggleTodoCompletion(task);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Task restored'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } else if (value == 'delete') {
                  final confirmed = await _showDeleteConfirmation(context);
                  if (confirmed == true) {
                    await taskProvider.deleteTodo(task.id);
                  }
                }
              },
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      Icon(Icons.restore_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Restore'),
                    ],
                  ),
                ),
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
        ),
      ),
    );
  }

  List<Todo> _getFilteredTasks(HybridTaskProvider taskProvider) {
    var tasks = taskProvider.allTodos.where((t) => t.isCompleted).toList();

    // Apply date filter
    if (_startDate != null) {
      tasks = tasks
          .where(
              (t) => t.updatedAt != null && t.updatedAt!.isAfter(_startDate!))
          .toList();
    }
    if (_endDate != null) {
      tasks = tasks
          .where((t) =>
              t.updatedAt != null &&
              t.updatedAt!.isBefore(_endDate!.add(const Duration(days: 1))))
          .toList();
    }

    // Apply sort
    tasks.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'completedDate':
          comparison = (b.updatedAt ?? DateTime.now())
              .compareTo(a.updatedAt ?? DateTime.now());
          break;
        case 'priority':
          comparison = a.priority.compareTo(b.priority);
          break;
        case 'title':
          comparison = a.title.compareTo(b.title);
          break;
        default:
          comparison = 0;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return tasks;
  }

  Map<DateTime, List<Todo>> _groupTasksByDate(List<Todo> tasks) {
    final grouped = <DateTime, List<Todo>>{};

    for (final task in tasks) {
      final date = task.updatedAt != null
          ? DateTime(
              task.updatedAt!.year, task.updatedAt!.month, task.updatedAt!.day)
          : DateTime.now();

      if (grouped[date] == null) {
        grouped[date] = [];
      }
      grouped[date]!.add(task);
    }

    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key)),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return 'Today';
    } else if (date == yesterday) {
      return 'Yesterday';
    } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
      return DateFormat.EEEE().format(date);
    } else {
      return DateFormat.MMMd().format(date);
    }
  }

  String _getDateRangeText() {
    if (_startDate != null && _endDate != null) {
      return '${DateFormat.MMMd().format(_startDate!)} - ${DateFormat.MMMd().format(_endDate!)}';
    } else if (_startDate != null) {
      return 'From ${DateFormat.MMMd().format(_startDate!)}';
    } else if (_endDate != null) {
      return 'Until ${DateFormat.MMMd().format(_endDate!)}';
    }
    return '';
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Filter & Sort',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sort By',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Date'),
                  selected: _sortBy == 'completedDate',
                  onSelected: (selected) {
                    setState(() => _sortBy = 'completedDate');
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Priority'),
                  selected: _sortBy == 'priority',
                  onSelected: (selected) {
                    setState(() => _sortBy = 'priority');
                    Navigator.pop(context);
                  },
                ),
                FilterChip(
                  label: const Text('Title'),
                  selected: _sortBy == 'title',
                  onSelected: (selected) {
                    setState(() => _sortBy = 'title');
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Date Range',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _startDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      _startDate != null
                          ? DateFormat.MMMd().format(_startDate!)
                          : 'Start Date',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                      }
                    },
                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                    label: Text(
                      _endDate != null
                          ? DateFormat.MMMd().format(_endDate!)
                          : 'End Date',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Delete Task'),
          ],
        ),
        content: const Text('This action cannot be undone. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Clear Archive'),
          ],
        ),
        content: const Text(
            'This will permanently delete all archived tasks. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final taskProvider =
                  Provider.of<HybridTaskProvider>(context, listen: false);
              final completedTasks =
                  taskProvider.allTodos.where((t) => t.isCompleted).toList();

              for (final task in completedTasks) {
                await taskProvider.deleteTodo(task.id);
              }

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Archive cleared'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _exportArchive() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
