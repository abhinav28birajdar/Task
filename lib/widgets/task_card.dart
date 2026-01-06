import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/todo.dart';
import '../providers/hybrid_category_provider.dart';
import '../models/category.dart';

class TaskCard extends StatelessWidget {
  final Todo task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;
  final bool showDate;
  final HybridCategoryProvider? categoryProvider;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onDelete,
    this.showDate = false,
    this.categoryProvider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final category = _getCategory();

    return Dismissible(
      key: Key(task.id),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Task'),
            content: const Text('Are you sure you want to delete this task?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete?.call(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2D2D2D) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(
                color: _getPriorityColor(),
                width: 4,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: onComplete,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: task.isCompleted
                          ? theme.primaryColor
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: task.isCompleted
                            ? theme.primaryColor
                            : theme.dividerColor,
                        width: 2,
                      ),
                    ),
                    child: task.isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.isCompleted
                              ? theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.5)
                              : theme.textTheme.bodyLarge?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      // Tags Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // Category Tag
                          if (category != null)
                            _buildTag(
                              icon: category.iconData,
                              label: category.name,
                              color: category.color,
                            ),
                          // Priority Tag
                          _buildTag(
                            icon: Icons.flag_rounded,
                            label: task.priorityText,
                            color: _getPriorityColor(),
                          ),
                          // Due Date
                          if (task.dueDate != null || showDate)
                            _buildTag(
                              icon: task.isOverdue
                                  ? Icons.warning_amber_rounded
                                  : Icons.schedule_rounded,
                              label: _formatDueDate(),
                              color: task.isOverdue
                                  ? Colors.red
                                  : theme.primaryColor,
                            ),
                          // Has attachments indicator
                          if (task.notes != null && task.notes!.isNotEmpty)
                            _buildTag(
                              icon: Icons.attach_file_rounded,
                              label: '',
                              color: theme.primaryColor,
                              isIconOnly: true,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // More options
                PopupMenuButton<String>(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: theme.iconTheme.color?.withOpacity(0.5),
                    size: 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'complete',
                      child: Row(
                        children: [
                          Icon(
                            task.isCompleted
                                ? Icons.undo_rounded
                                : Icons.check_circle_outline_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(task.isCompleted
                              ? 'Mark Incomplete'
                              : 'Mark Complete'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onTap?.call();
                        break;
                      case 'complete':
                        onComplete?.call();
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
    bool isIconOnly = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isIconOnly ? 6 : 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          if (!isIconOnly && label.isNotEmpty) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getPriorityColor() {
    switch (task.priority) {
      case 1:
        return const Color(0xFFEF4444); // High - Red
      case 2:
        return const Color(0xFFF59E0B); // Medium - Orange
      case 3:
        return const Color(0xFF22C55E); // Low - Green
      default:
        return const Color(0xFF3B82F6); // Default - Blue
    }
  }

  String _formatDueDate() {
    if (task.dueDate == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDate =
        DateTime(task.dueDate!.year, task.dueDate!.month, task.dueDate!.day);
    final difference = dueDate.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference < -1) {
      return '${-difference} days ago';
    } else if (difference < 7) {
      return DateFormat('EEEE').format(task.dueDate!);
    } else {
      return DateFormat('MMM d').format(task.dueDate!);
    }
  }

  Category? _getCategory() {
    if (categoryProvider == null || task.categoryId == null) return null;
    try {
      return categoryProvider!.categories.firstWhere(
        (c) => c.id == task.categoryId,
      );
    } catch (e) {
      return null;
    }
  }
}

class CompactTaskCard extends StatelessWidget {
  final Todo task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  const CompactTaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onComplete,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: task.isCompleted
                      ? theme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: task.isCompleted
                        ? theme.primaryColor
                        : theme.dividerColor,
                    width: 2,
                  ),
                ),
                child: task.isCompleted
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                task.title,
                style: TextStyle(
                  fontSize: 14,
                  decoration:
                      task.isCompleted ? TextDecoration.lineThrough : null,
                  color: task.isCompleted
                      ? theme.textTheme.bodyMedium?.color?.withOpacity(0.5)
                      : theme.textTheme.bodyLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _getPriorityColor(),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor() {
    switch (task.priority) {
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF3B82F6);
    }
  }
}
