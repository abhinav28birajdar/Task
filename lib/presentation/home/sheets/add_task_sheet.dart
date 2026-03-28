import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/task_model.dart';
import '../../../../providers/task_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_snackbar.dart';

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({Key? key}) : super(key: key);

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _category = 'Work';
  String _priority = 'Medium';
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  bool _reminder = true;
  bool _alarm = false;
  int _reminderMinutes = 10;

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
      firstDate: now,
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

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final task = TaskModel(
      id: '', // Will be set in provider
      uid: uid,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category.toLowerCase(),
      priority: _priority.toLowerCase(),
      isCompleted: false,
      dueDate: _dueDate,
      dueTime: _dueTime != null
          ? '${_dueTime!.hour}:${_dueTime!.minute.toString().padLeft(2, '0')}'
          : null,
      reminder: _reminder,
      alarmEnabled: _alarm,
      reminderMinutesBefore: _reminderMinutes,
      subTasks: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await context.read<TaskProvider>().addTask(task);
      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.showSuccess(context, 'Task added successfully');
      }
    } catch (e) {
      if (mounted) AppSnackbar.showError(context, 'Failed to add task: $e');
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
                'Add New Task',
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
              AppButton(label: 'Save Task', onPressed: _submit),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
