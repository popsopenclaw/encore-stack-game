import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class CommonCard extends StatelessWidget {
  const CommonCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: child,
      ),
    );
  }
}
