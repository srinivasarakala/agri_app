import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../main.dart'; // to access app services
import '../shell/app_shell.dart'; // for appTabIndex

class PhonePage extends StatefulWidget {
  const PhonePage({super.key});

  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool loading = false;
  String? error;
  bool requiresPassword = false;
  bool obscurePassword = true;

  Future<void> sendOtp() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final phone = phoneCtrl.text.trim();
      final password = passwordCtrl.text.trim();

      // OTP Verification Disabled - Direct Login
      // Skip sending OTP and directly verify with dummy OTP
      await appAuth.verifyOtp(
        phone,
        '000000',
        password: requiresPassword ? password : null,
      ); // Any OTP works since backend bypasses check

      if (!mounted) return;

      // Reset tab to Home (index 0)
      appTabIndex.value = 0;

      // Navigate to home after successful login
      context.go('/app');
    } on DioException catch (e) {
      if (e.response?.statusCode == 400 || e.response?.statusCode == 401) {
        final data = e.response?.data;
        if (data is Map && data['requires_password'] == true) {
          setState(() {
            requiresPassword = true;
            error = data['error'] ?? 'Password required for admin login';
          });
          return;
        }
      }
      setState(() => error = 'Login failed: ${e.toString()}');
    } catch (e) {
      setState(() => error = 'Login failed: ${e.toString()}');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                border: OutlineInputBorder(),
              ),
              enabled: !requiresPassword,
            ),
            const SizedBox(height: 16),
            if (requiresPassword) ...[
              TextField(
                controller: passwordCtrl,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Admin Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => obscurePassword = !obscurePassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Admin account requires password verification',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : sendOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(requiresPassword ? 'Login with Password' : 'Login'),
              ),
            ),
            if (requiresPassword) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    requiresPassword = false;
                    error = null;
                    passwordCtrl.clear();
                  });
                },
                child: const Text('Back to phone login'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
