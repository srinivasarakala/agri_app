import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../shell/app_shell.dart';

/// Handles two flows:
///   1. First-time login  — [isFirstLogin] == true, admin has no password yet
///   2. Forgot password   — [isFirstLogin] == false, admin verified OTP
///
/// Both flows use the [otpSessionToken] (5-min cache token issued by backend
/// after OTP verification) instead of requiring the current password.
class SetPasswordPage extends StatefulWidget {
  final String phone;
  final String otpSessionToken;
  final bool isFirstLogin;

  const SetPasswordPage({
    super.key,
    required this.phone,
    required this.otpSessionToken,
    required this.isFirstLogin,
  });

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await appAuth.client.dio.post(
        '/auth/reset-password',
        data: {
          'phone': widget.phone,
          'otp_session_token': widget.otpSessionToken,
          'new_password': _newCtrl.text.trim(),
        },
        options: Options(contentType: 'application/json'),
      );

      final access = res.data['access'] as String;
      final refresh = res.data['refresh'] as String;
      final user = res.data['user'] as Map<String, dynamic>;
      final role = user['role'] as String;
      final subdealerId = user['subdealer_id'] as int?;

      await appAuth.storage.saveSession(
        access: access,
        refresh: refresh,
        role: role,
        subdealerId: subdealerId,
        phone: widget.phone,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isFirstLogin
              ? 'Password set! Welcome.'
              : 'Password reset successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      appTabIndex.value = 0;
      context.go('/app');
    } on DioException catch (e) {
      final data = e.response?.data;
      final statusCode = e.response?.statusCode;
      String msg;
      if (statusCode == 401) {
        msg = 'Session expired. Please go back and verify OTP again.';
      } else {
        msg = (data is Map ? (data['error'] ?? data['message']) : null) as String?
            ?? 'Failed. Please try again.';
      }
      setState(() {
        _error = msg;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Unexpected error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isFirstLogin ? 'Set Your Password' : 'Reset Password';
    final subtitle = widget.isFirstLogin
        ? 'This is your first login. Please set a password to secure your admin account.'
        : 'OTP verified. Set a new password for your account.';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        // Prevent back navigation — user must complete this step
        automaticallyImplyLeading: !widget.isFirstLogin,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.isFirstLogin
                      ? Colors.blue.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: widget.isFirstLogin
                        ? Colors.blue.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      widget.isFirstLogin
                          ? Icons.lock_open_outlined
                          : Icons.lock_reset_outlined,
                      color: widget.isFirstLogin
                          ? Colors.blue.shade700
                          : Colors.orange.shade700,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        subtitle,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Phone display (read-only)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        color: Colors.grey.shade600, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      widget.phone,
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // New password
              TextFormField(
                controller: _newCtrl,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: const OutlineInputBorder(),
                  helperText: 'Minimum 6 characters',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Enter a new password';
                  if (v.trim().length < 6)
                    return 'Password must be at least 6 characters';
                  return null;
                },
              ),
              const SizedBox(height: 18),

              // Confirm password
              TextFormField(
                controller: _confirmCtrl,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_reset_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Please confirm your password';
                  if (v.trim() != _newCtrl.text.trim())
                    return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Error box
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                              color: Colors.red.shade700, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Submit button
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        widget.isFirstLogin ? 'Set Password & Login' : 'Reset Password & Login',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
