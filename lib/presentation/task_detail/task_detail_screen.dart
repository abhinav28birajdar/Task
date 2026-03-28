import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/task_provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_utils.dart';
import '../home/widgets/priority_dot_widget.dart';
import '../home/sheets/edit_task_sheet.dart';
import '../widgets/app_dialog.dart';

class TaskDetailScreen extends StatelessWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final task = taskProvider.tasks.firstWhere((t) => t.id == taskId,
        orElse: () => throw Exception('Task not found'));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => EditTaskSheet(task: task),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: () async {
              final confirm = await AppDialog.confirm(context, 'Delete Task',
                  'Are you sure you want to delete this task?');
              if (confirm == true) {
                await taskProvider.deleteTask(task);
                if (context.mounted) context.pop();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    task.category.toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
                const SizedBox(width: 12),
                PriorityDotWidget(priority: task.priority),
                const SizedBox(width: 6),
                Text(
                  task.priority.toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const Spacer(),
                Switch(
                  value: task.isCompleted,
                  onChanged: (v) => taskProvider.toggleTask(task.id, v),
                  activeColor: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              task.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    decoration:
                        task.isCompleted ? TextDecoration.lineThrough : null,
                  ),
            ),
            const SizedBox(height: 16),
            if (task.description.isNotEmpty) ...[
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 32),
            ],
            const Divider(),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              Icons.calendar_today_outlined,
              'Due Date',
              task.dueDate != null
                  ? AppDateUtils.formatDate(task.dueDate!)
                  : 'Not set',
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              Icons.access_time_outlined,
              'Time',
              task.dueTime ?? 'Not set',
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              context,
              Icons.notifications_outlined,
              'Reminder',
              task.reminder
                  ? 'Enabled (${task.reminderMinutesBefore}m before)'
                  : 'Disabled',
            ),
            if (task.reminder) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                context,
                Icons.alarm,
                'Alarm',
                task.alarmEnabled ? 'Loud Alarm' : 'Standard Notification',
              ),
            ],
            const SizedBox(height: 32),
            const Text(
              'Sub-tasks',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (task.subTasks.isEmpty)
              Text(
                'No sub-tasks added',
                style: TextStyle(
                    color: Colors.grey.shade500, fontStyle: FontStyle.italic),
              )
            else
              ...task.subTasks.map((sub) => CheckboxListTile(
                    title: Text(
                      sub.title,
                      style: TextStyle(
                        decoration:
                            sub.isCompleted ? TextDecoration.lineThrough : null,
                        color: sub.isCompleted ? Colors.grey : null,
                      ),
                    ),
                    value: sub.isCompleted,
                    onChanged: (v) =>
                        taskProvider.toggleSubTask(task.id, sub.id, v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  )),
            const SizedBox(height: 40),
            Center(
              child: Text(
                'Created on ${DateFormat('MMM d, y, hh:mm a').format(task.createdAt)}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        ),
      ],
    );
  }
}
