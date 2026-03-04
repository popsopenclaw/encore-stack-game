import 'package:flutter/material.dart';

import 'app/router.dart';
import 'theme/app_theme.dart';

void main() => runApp(const EncoreApp());

class EncoreApp extends StatelessWidget {
  const EncoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Encore',
      theme: AppTheme.light,
      routes: AppRouter.routes,
      initialRoute: AppRoutes.gate,
    );
  }
}
