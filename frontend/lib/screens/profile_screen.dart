import 'package:flutter/material.dart';

import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Profile',
      child: CommonCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GitHub account profile info will be shown here.'),
          ],
        ),
      ),
    );
  }
}
