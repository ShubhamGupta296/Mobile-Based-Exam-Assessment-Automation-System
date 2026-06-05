import 'package:flutter/material.dart';

import 'screens/app_bootstrap_screen.dart';

class ExamAssessmentApp extends StatelessWidget {
  const ExamAssessmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exam Assessment Automation System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const AppBootstrapScreen(),
    );
  }
}

