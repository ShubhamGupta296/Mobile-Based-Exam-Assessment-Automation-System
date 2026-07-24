import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import '../services/auth_service.dart';

/// Red logout button for dashboards.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key, this.compact = false});

  final bool compact;

  Future<void> _logout(BuildContext context) async {
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return TextButton.icon(
        onPressed: () => _logout(context),
        style: TextButton.styleFrom(foregroundColor: Colors.red),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Logout'),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: FilledButton.icon(
        onPressed: () => _logout(context),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        icon: const Icon(Icons.logout, size: 18),
        label: const Text('Logout'),
      ),
    );
  }
}
