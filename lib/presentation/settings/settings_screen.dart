import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          _buildSettingsHeader('Personal'),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline,
            title: 'Account',
            subtitle: 'Personal info, security, delete account',
            onTap: () => context.push('/settings/account'),
          ),
          _buildSettingsHeader('App Settings'),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_none,
            title: 'Notifications',
            subtitle: 'Reminders, daily summary, sounds',
            onTap: () => context.push('/settings/notifications'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'Theme mode, font size, accent color',
            onTap: () => context.push('/settings/appearance'),
          ),
          _buildSettingsTile(
            context,
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            subtitle: 'App lock, data privacy, policy',
            onTap: () => context.push('/settings/privacy'),
          ),
          _buildSettingsHeader('Support'),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'FAQs, contact us, feedback',
            onTap: () {},
          ),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'Version 1.0.0, license',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
    );
  }
}
