import 'package:flutter/material.dart';

import '../../../../core/localization/admin_language_scope.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';

class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onSubmit,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isSubmitting;
  final String? errorMessage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: emailController,
            hintText: context.tr(english: 'Email', bosnian: 'Email'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            enableSuggestions: false,
            autocorrect: false,
          ),
          const SizedBox(height: 18),
          AppTextField(
            controller: passwordController,
            hintText: context.tr(english: 'Password', bosnian: 'Lozinka'),
            obscureText: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            enableSuggestions: false,
            autocorrect: false,
            onSubmitted: (_) => onSubmit(),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: context.tr(english: 'LOGIN', bosnian: 'PRIJAVA'),
              onPressed: isSubmitting ? null : onSubmit,
              isLoading: isSubmitting,
            ),
          ),
        ],
      ),
    );
  }
}
