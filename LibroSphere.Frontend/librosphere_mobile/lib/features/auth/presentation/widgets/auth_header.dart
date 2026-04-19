import 'package:flutter/material.dart';

import '../../../../core/app_constants.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.isLoginMode,
  });

  final bool isLoginMode;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(color: brandBlue, shape: BoxShape.circle),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: ClipOval(
              child: Image.asset(
                'assets/librosphere_logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            isLoginMode ? 'Welcome Back' : 'Create Account',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
