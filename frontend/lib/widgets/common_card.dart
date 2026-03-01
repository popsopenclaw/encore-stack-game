import 'package:flutter/material.dart';

class CommonCard extends StatelessWidget {
  const CommonCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}
