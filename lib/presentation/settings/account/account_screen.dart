import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../providers/user_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/app_snackbar.dart';
import '../../../core/constants/app_colors.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = userProvider.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Personal Info',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Name', user?.name ?? 'Loading...'),
          _buildInfoRow('Email', user?.email ?? 'Loading...'),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Edit Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/account/edit'),
          ),
          ListTile(
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/account/password'),
          ),
          const SizedBox(height: 32),
          const Text(
            'Danger Zone',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.error),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Delete Account',
            isOutlined: true,
            color: AppColors.error,
            onPressed: () async {
              final confirm = await AppDialog.confirm(
                context,
                'Delete Account',
                'This action is irreversible. All your tasks and data will be permanently deleted.',
              );
              if (confirm == true) {
                final password = await AppDialog.reauth(context);
                if (password != null) {
                  final success = await authProvider.deleteAccount(password);
                  if (success) {
                    if (context.mounted) context.go('/auth/signin');
                  } else {
                    if (context.mounted)
                      AppSnackbar.showError(context,
                          authProvider.error ?? 'Failed to delete account');
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
