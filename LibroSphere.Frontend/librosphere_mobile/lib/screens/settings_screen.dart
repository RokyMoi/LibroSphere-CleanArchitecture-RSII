import 'package:flutter/material.dart';

import '../features/session/presentation/session_scope.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.session;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      children: [
        const Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: const Color(0xFFF7F9FF), borderRadius: BorderRadius.circular(22)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session.currentUser?.fullName ?? 'Unknown User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(session.currentUser?.email ?? '', style: TextStyle(color: Colors.grey.shade700)),
              const SizedBox(height: 18),
              PrimaryPillButton(
                label: 'Logout',
                onPressed: () async => session.logout(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
