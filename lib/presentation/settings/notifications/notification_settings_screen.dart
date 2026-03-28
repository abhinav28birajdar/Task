import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../core/constants/app_colors.dart';

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifyProvider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'General Notifications',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Enable or disable all notifications'),
            value: notifyProvider.pushEnabled,
            onChanged: (v) => notifyProvider.togglePush(v),
            activeColor: AppColors.primary,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Reminders',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Task Reminders'),
            subtitle: const Text('Get notified before tasks are due'),
            value: notifyProvider.remindersEnabled,
            onChanged: (v) => notifyProvider.toggleReminders(v),
            activeColor: AppColors.primary,
          ),
          SwitchListTile(
            title: const Text('Loud Alarms'),
            subtitle: const Text('Allow critical tasks to trigger alarms'),
            value: notifyProvider.alarmsEnabled,
            onChanged: (v) => notifyProvider.toggleAlarms(v),
            activeColor: AppColors.primary,
          ),
          const ListTile(
            title: Text('Reminder Time'),
            subtitle: Text('10 minutes before due'),
            trailing: Icon(Icons.chevron_right),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Daily Summary'),
            subtitle: const Text('Get a summary of your tasks every morning'),
            value: notifyProvider.dailySummary,
            onChanged: (v) => notifyProvider.toggleDailySummary(v),
            activeColor: AppColors.primary,
          ),
          const ListTile(
            title: Text('Summary Time'),
            subtitle: Text('08:00 AM'),
            trailing: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
