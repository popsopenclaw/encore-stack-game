import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/app_shell.dart';
import '../widgets/common_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppShell(
      title: 'Profile',
      child: Center(
        child: SizedBox(
          width: 560,
          child: CommonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Profile', style: AppTextStyles.title),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'GitHub account profile info will be shown here.',
                  style: AppTextStyles.bodyMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
