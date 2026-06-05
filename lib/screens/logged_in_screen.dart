import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../auth/login_screen.dart';
import '../admin/admin_dashboard_screen.dart';
import '../teacher/teacher_dashboard_screen.dart';
import '../student/student_dashboard_screen.dart';

/// Role-based router shown after login.
///
/// Loads the current user's profile from Firestore and returns the
/// corresponding dashboard based on the `role` field.
class LoggedInScreen extends StatefulWidget {
  const LoggedInScreen({super.key});

  @override
  State<LoggedInScreen> createState() => _LoggedInScreenState();
}

class _LoggedInScreenState extends State<LoggedInScreen> {
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _authService.fetchCurrentUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }
        final profile = snapshot.data;
        if (profile == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No user profile found.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      await _authService.logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                    child: const Text('Back to login'),
                  ),
                ],
              ),
            ),
          );
        }

        final role = profile.role.toLowerCase();
        if (role == 'admin') {
          return const AdminDashboardScreen();
        } else if (role == 'teacher') {
          return const TeacherDashboardScreen();
        } else if (role == 'student') {
          return const StudentDashboardScreen();
        } else {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Unknown role: ${profile.role}'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      await _authService.logout();
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (_) => false,
                      );
                    },
                    child: const Text('Back to login'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}

