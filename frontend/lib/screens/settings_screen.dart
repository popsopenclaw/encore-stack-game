import 'package:flutter/material.dart';

import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Settings',
      child: CommonCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Backend & gameplay settings will live here.'),
          ],
        ),
      ),
    );
  }
}
