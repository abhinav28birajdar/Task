import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/task_model.dart';
import '../../../../providers/task_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_snackbar.dart';

class EditTaskSheet extends StatefulWidget {
  final TaskModel task;
  const EditTaskSheet({Key? key, required this.task}) : super(key: key);

  @override
  State<EditTaskSheet> createState() => _EditTaskSheetState();
}

class _EditTaskSheetState extends State<EditTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;

  late String _category;
  late String _priority;
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  late bool _reminder;
  late bool _alarm;
  late int _reminderMinutes;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    _descCtrl = TextEditingController(text: widget.task.description);
    _category = widget.task.category.isEmpty
        ? 'Other'
        : widget.task.category[0].toUpperCase() +
            widget.task.category.substring(1);
    _priority = widget.task.priority.isEmpty
        ? 'Medium'
        : widget.task.priority[0].toUpperCase() +
            widget.task.priority.substring(1);
    _dueDate = widget.task.dueDate;
    if (widget.task.dueTime != null) {
      final parts = widget.task.dueTime!.split(':');
      _dueTime =
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
    _reminder = widget.task.reminder;
    _alarm = widget.task.alarmEnabled;
    _reminderMinutes = widget.task.reminderMinutesBefore ?? 10;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  void _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedTask = widget.task.copyWith(
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category.toLowerCase(),
      priority: _priority.toLowerCase(),
      dueDate: _dueDate,
      dueTime: _dueTime != null
          ? '${_dueTime!.hour}:${_dueTime!.minute.toString().padLeft(2, '0')}'
          : null,
      reminder: _reminder,
      alarmEnabled: _alarm,
      reminderMinutesBefore: _reminderMinutes,
      updatedAt: DateTime.now(),
    );

    try {
      await context.read<TaskProvider>().updateTask(updatedTask);
      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.showSuccess(context, 'Task updated successfully');
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'Failed to update task: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Edit Task',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              AppTextField(
                label: 'Title',
                hint: 'What needs to be done?',
                controller: _titleCtrl,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Description',
                hint: 'Add more details...',
                controller: _descCtrl,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: _category,
                          isExpanded: true,
                          items: [
                            'Work',
                            'Personal',
                            'Shopping',
                            'Health',
                            'Other'
                          ]
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setState(() => _category = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Priority',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        DropdownButton<String>(
                          value: _priority,
                          isExpanded: true,
                          items: ['Low', 'Medium', 'High']
                              .map((e) =>
                                  DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (v) => setState(() => _priority = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_dueDate == null
                          ? 'Due Date'
                          : DateFormat('MMM d, y').format(_dueDate!)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(_dueTime == null
                          ? 'Due Time'
                          : _dueTime!.format(context)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Reminder'),
                subtitle: const Text('Get a notification before due'),
                value: _reminder,
                onChanged: (v) => setState(() => _reminder = v),
              ),
              if (_reminder)
                SwitchListTile(
                  title: const Text('Alarm'),
                  subtitle: const Text('Loud alarm for critical tasks'),
                  value: _alarm,
                  onChanged: (v) => setState(() => _alarm = v),
                ),
              const SizedBox(height: 24),
              AppButton(label: 'Update Task', onPressed: _submit),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
