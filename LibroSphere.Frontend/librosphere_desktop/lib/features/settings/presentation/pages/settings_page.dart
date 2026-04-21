import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../features/session/presentation/viewmodels/admin_session_viewmodel.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../viewmodels/settings_viewmodel.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.viewModel,
    required this.session,
  });

  final SettingsViewModel viewModel;
  final AdminSessionViewModel session;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _adminFirstNameController = TextEditingController();
  final _adminLastNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _adminFirstNameController.dispose();
    _adminLastNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await widget.viewModel.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmNewPassword: _confirmPasswordController.text,
    );

    if (success && mounted) {
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.viewModel.successMessage ?? 'Success!')),
      );
    } else if (!success && mounted && widget.viewModel.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.error!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createAdmin() async {
    final success = await widget.viewModel.createAdmin(
      firstName: _adminFirstNameController.text.trim(),
      lastName: _adminLastNameController.text.trim(),
      email: _adminEmailController.text.trim(),
      password: _adminPasswordController.text,
    );

    if (!mounted) return;

    if (success) {
      _adminFirstNameController.clear();
      _adminLastNameController.clear();
      _adminEmailController.clear();
      _adminPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.viewModel.createAdminSuccess ??
                'Admin nalog je uspjesno kreiran.',
          ),
          backgroundColor: const Color(0xFF1F8B4C),
        ),
      );
    } else if (widget.viewModel.createAdminError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.viewModel.createAdminError!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Da li ste sigurni da zelite da se odjavite?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await widget.session.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Logout',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white54),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  _buildChangePasswordCard(),
                  _buildCreateAdminCard(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChangePasswordCard() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: desktopPrimaryLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Change Password',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _currentPasswordController,
              hintText: 'Current Password',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _newPasswordController,
              hintText: 'New Password',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirmPasswordController,
              hintText: 'Confirm New Password',
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: 'Change Password',
                onPressed: widget.viewModel.isLoading ? null : _submit,
                isLoading: widget.viewModel.isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAdminCard() {
    return Container(
      width: 400,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: desktopPrimaryLight.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Create New Admin',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _adminFirstNameController,
            hintText: 'First Name',
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _adminLastNameController,
            hintText: 'Last Name',
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _adminEmailController,
            hintText: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _adminPasswordController,
            hintText: 'Password',
            obscureText: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: 'Create Admin',
              onPressed:
                  widget.viewModel.isCreatingAdmin ? null : _createAdmin,
              isLoading: widget.viewModel.isCreatingAdmin,
            ),
          ),
        ],
      ),
    );
  }
}
