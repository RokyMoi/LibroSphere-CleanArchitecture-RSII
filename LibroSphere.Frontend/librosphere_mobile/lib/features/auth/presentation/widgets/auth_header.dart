import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.isLoginMode});

  final bool isLoginMode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        final iconSize = compact ? 58.0 : 72.0;
        final titleSize = compact ? 24.0 : 28.0;
        final spacing = compact ? 12.0 : 14.0;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(compact ? 16 : 20),
              child: Image.asset(
                'assets/librosphere_logo.png',
                width: iconSize,
                height: iconSize,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: Text(
                isLoginMode ? 'Welcome Back' : 'Create Account',
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
