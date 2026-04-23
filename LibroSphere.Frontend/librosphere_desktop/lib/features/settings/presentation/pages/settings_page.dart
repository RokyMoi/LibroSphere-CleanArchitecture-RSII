import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/localization/admin_language_controller.dart';
import '../../../../core/localization/admin_language_scope.dart';
import '../../../../features/session/presentation/viewmodels/admin_session_viewmodel.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../viewmodels/settings_viewmodel.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    super.key,
    required this.viewModel,
    required this.session,
    required this.languageController,
  });

  final SettingsViewModel viewModel;
  final AdminSessionViewModel session;
  final AdminLanguageController languageController;

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
        SnackBar(
          content: Text(
            context.tr(
              english: 'Password changed successfully.',
              bosnian: 'Lozinka je uspjesno promijenjena.',
            ),
          ),
        ),
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
            context.tr(
              english: 'Admin account created successfully.',
              bosnian: 'Admin nalog je uspjesno kreiran.',
            ),
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
        title: Text(widget.languageController.language.isEnglish ? 'Log out' : 'Odjava'),
        content: Text(
          widget.languageController.language.isEnglish
              ? 'Are you sure you want to log out?'
              : 'Da li ste sigurni da zelite da se odjavite?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              widget.languageController.language.isEnglish ? 'Cancel' : 'Odustani',
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              widget.languageController.language.isEnglish ? 'Log out' : 'Odjava',
            ),
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
      listenable: Listenable.merge([
        widget.viewModel,
        widget.languageController,
      ]),
      builder: (context, _) {
        final language = widget.languageController.language;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(
                    width: 120,
                  ),
                  Text(
                    language.isEnglish ? 'Settings' : 'Postavke',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _confirmLogout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: Text(
                      language.isEnglish ? 'Log out' : 'Odjava',
                      style: const TextStyle(color: Colors.white),
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
                  _buildChangePasswordCard(language),
                  _buildCreateAdminCard(language),
                  _buildLanguageCard(language),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChangePasswordCard(AdminLanguage language) {
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
            Text(
              language.isEnglish ? 'Change Password' : 'Promjena lozinke',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            AppTextField(
              controller: _currentPasswordController,
              hintText: language.isEnglish ? 'Current Password' : 'Trenutna lozinka',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _newPasswordController,
              hintText: language.isEnglish ? 'New Password' : 'Nova lozinka',
              obscureText: true,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _confirmPasswordController,
              hintText: language.isEnglish
                  ? 'Confirm New Password'
                  : 'Potvrdite novu lozinku',
              obscureText: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                label: language.isEnglish ? 'Change Password' : 'Promijeni lozinku',
                onPressed: widget.viewModel.isLoading ? null : _submit,
                isLoading: widget.viewModel.isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateAdminCard(AdminLanguage language) {
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
          Text(
            language.isEnglish ? 'Create New Admin' : 'Kreiraj novog admina',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _adminFirstNameController,
            hintText: language.isEnglish ? 'First Name' : 'Ime',
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _adminLastNameController,
            hintText: language.isEnglish ? 'Last Name' : 'Prezime',
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
            hintText: language.isEnglish ? 'Password' : 'Lozinka',
            obscureText: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: language.isEnglish ? 'Create Admin' : 'Kreiraj admina',
              onPressed:
                  widget.viewModel.isCreatingAdmin ? null : _createAdmin,
              isLoading: widget.viewModel.isCreatingAdmin,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(AdminLanguage language) {
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
          Text(
            language.isEnglish ? 'Language' : 'Jezik',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            language.isEnglish
                ? 'Choose the admin interface language.'
                : 'Izaberite jezik admin interfejsa.',
            style: const TextStyle(
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: AdminLanguage.values.map((option) {
              final selected = option == language;
              return Padding(
                padding: EdgeInsets.only(
                  right: option == AdminLanguage.bosnian ? 12 : 0,
                ),
                child: OutlinedButton(
                  onPressed: () => widget.languageController.setLanguage(option),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: selected ? Colors.white : Colors.white54,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    option.label,
                    style: TextStyle(
                      color: selected ? desktopPrimary : Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
