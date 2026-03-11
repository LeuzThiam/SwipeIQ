import 'package:flutter/material.dart';

import 'ui/navigation/app_shell_page.dart';

void main() {
  runApp(const SwipeIqApp());
}

class SwipeIqApp extends StatelessWidget {
  const SwipeIqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwipeIQ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B6E4F)),
      ),
      home: const AppShellPage(),
    );
  }
}
