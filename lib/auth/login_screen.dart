import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/auth_validators.dart';
import '../admin/admin_dashboard_screen.dart';
import '../teacher/teacher_dashboard_screen.dart';
import '../student/student_dashboard_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  AuthService? _authService;

  AuthService get _authServiceInstance => _authService ??= AuthService();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1) Sign in with Firebase Auth
      final credential = await _authServiceInstance.loginWithEmailPassword(
        email: _emailCtrl.text.trim().toLowerCase(),
        password: _passwordCtrl.text,
      );

      // 2) Get current user UID
      final user = credential.user ?? _authServiceInstance.currentUser;
      if (user == null) {
        throw Exception('Login succeeded but no user found.');
      }

      // 3) Fetch user document from Firestore and read role
      final profile = await _authServiceInstance.fetchCurrentUserProfile();
      if (profile == null) {
        throw Exception('User profile not found.');
      }
      if (profile.approvalStatus == 'pending') {
        throw Exception('Registration pending admin approval.');
      }
      if (profile.approvalStatus == 'rejected') {
        throw Exception('Registration was rejected by admin.');
      }
      final role = profile.role.toLowerCase();

      if (!mounted) return;

      Widget target;
      if (role == 'admin') {
        target = const AdminDashboardScreen();
      } else if (role == 'teacher') {
        target = const TeacherDashboardScreen();
      } else if (role == 'student') {
        target = const StudentDashboardScreen();
      } else {
        throw Exception('Unknown or missing role for this user.');
      }

      // 4) Navigate based on role
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => target));
    } on Exception catch (e) {
      setState(() => _error = e.toString());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Login failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),
            Text('Welcome back', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Email (@gmail.com only)',
                      border: OutlineInputBorder(),
                    ),
                    validator: AuthValidators.validateGmailEmail,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (v) {
                      final value = v ?? '';
                      if (value.isEmpty) return 'Enter password';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: Text(_isLoading ? 'Signing in...' : 'Login'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      );
                    },
                    child: const Text('Don’t have an account? Sign up'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
