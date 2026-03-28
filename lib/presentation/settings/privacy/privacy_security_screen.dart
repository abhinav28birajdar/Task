import 'package:flutter/material.dart';
import '../../../services/local_auth_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../widgets/app_snackbar.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _biometricEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'App Security',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Biometric Authentication'),
            subtitle: const Text('Use Face ID or Fingerprint to open app'),
            value: _biometricEnabled,
            onChanged: (v) async {
              final auth = LocalAuthService.instance;
              final isAvailable = await auth.isBiometricAvailable();
              if (isAvailable) {
                final authenticated = await auth.authenticate(
                  reason: 'Please authenticate to enable biometric lock',
                );
                if (authenticated) {
                  setState(() => _biometricEnabled = v);
                  if (context.mounted)
                    AppSnackbar.showSuccess(context,
                        'Biometric lock ${v ? "enabled" : "disabled"}');
                }
              } else {
                if (context.mounted)
                  AppSnackbar.showError(
                      context, 'Biometrics not available on this device');
              }
            },
            activeColor: AppColors.primary,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Data Privacy',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildOption(
            context,
            'Clear App Data',
            Icons.delete_sweep_outlined,
            'Delete locally cached data and preferences',
            () {},
          ),
          _buildOption(
            context,
            'Download My Data',
            Icons.download_outlined,
            'Get a copy of all your tasks in JSON format',
            () {},
          ),
          _buildOption(
            context,
            'Privacy Policy',
            Icons.policy_outlined,
            'Read how we handle your data',
            () {},
          ),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, String title, IconData icon,
      String subtitle, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
