import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../widgets/ui_kit.dart';

class CommonCard extends StatelessWidget {
  const CommonCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return AppPanel(padding: padding, child: child);
  }
}
