import 'package:flutter/material.dart';

import 'app_button.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    this.foregroundColor = Colors.white,
  });

  final String message;
  final Future<void> Function() onRetry;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: foregroundColor,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Retry',
              onPressed: () => onRetry(),
              width: 140,
            ),
          ],
        ),
      ),
    );
  }
}
