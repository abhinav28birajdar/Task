import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_loading_overlay.dart';
import '../../widgets/app_dialog.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  @override
  void dispose() {
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(
      currentPassword: _currentPwdCtrl.text,
      newPassword: _newPwdCtrl.text,
    );

    if (mounted) {
      if (success) {
        AppSnackbar.showSuccess(context, 'Password changed successfully');
        Navigator.pop(context);
      } else {
        AppSnackbar.showError(
            context, auth.error ?? 'Failed to change password');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AppLoadingOverlay(
      isLoading: auth.isLoading,
      child: Scaffold(
        appBar: AppBar(title: const Text('Change Password')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Your new password must be different from previous used passwords.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Current Password',
                  hint: '••••••••',
                  controller: _currentPwdCtrl,
                  obscureText: true,
                  validator: AppValidators.password,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'New Password',
                  hint: '••••••••',
                  controller: _newPwdCtrl,
                  obscureText: true,
                  validator: AppValidators.strongPassword,
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Confirm New Password',
                  hint: '••••••••',
                  controller: _confirmPwdCtrl,
                  obscureText: true,
                  validator: (v) =>
                      AppValidators.confirmPassword(v, _newPwdCtrl.text),
                ),
                const SizedBox(height: 48),
                AppButton(
                  label: 'Update Password',
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
