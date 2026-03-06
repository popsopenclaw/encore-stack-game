import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'ui_kit.dart';

class MenuTileButton extends StatelessWidget {
  const MenuTileButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppPalette.neonBlue.withValues(alpha: 0.45),
                    AppPalette.surfaceInset,
                  ],
                ),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppPalette.borderLight),
              ),
              child: Icon(icon, size: 21, color: AppPalette.textOnDark),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subtitle.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.bodyMuted),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.chevron_right,
              color: AppPalette.neonCyan,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
