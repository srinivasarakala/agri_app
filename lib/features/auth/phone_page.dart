import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:pavan_agro/services/device_service.dart';
import '../../main.dart'; // to access app services
import '../shell/app_shell.dart'; // for appTabIndex
import 'firebase_phone_auth_service.dart';
import 'otp_page.dart';

class PhonePage extends StatefulWidget {
  const PhonePage({super.key});

  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
    // List of known admin/superuser phone numbers
  final phoneCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool loading = false;
  String? error;
  bool requiresPassword = false;
  bool obscurePassword = true;
  bool showPasswordField = false;
  String? userRole;

  String? _verificationId;

  String formatPhoneNumber(String input) {
    String trimmed = input.trim();
    if (!trimmed.startsWith("+91")) {
      trimmed = trimmed.replaceFirst(RegExp(r'^0+'), '');
      return "+91$trimmed";
    }
    return trimmed;
  }

  Future<void> sendOtp() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    final phone = formatPhoneNumber(phoneCtrl.text);
    final firebaseService = FirebasePhoneAuthService();
    await firebaseService.verifyPhoneNumber(
      phoneNumber: phone,
      codeSent: (verificationId) {
        if (!mounted) return;
        setState(() {
          _verificationId = verificationId;
          loading = false;
        });
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpPage(
              phone: phone,
              verificationId: verificationId,
              requiresPassword: false, // always false for OTP step
              onSubmit: (otp, _) async {
                await _verifyOtpAndLogin(otp);
              },
            ),
          ),
        );
      },
      verificationFailed: (e) {
        if (!mounted) return;
        setState(() {
          error = e.toString();
          loading = false;
        });
      },
      codeAutoRetrievalTimeout: () {
        if (!mounted) return;
        setState(() {
          loading = false;
        });
      },
      verificationCompleted: (credential) {},
    );
  }

  Future<void> _verifyOtpAndLogin(String otp) async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    final phone = formatPhoneNumber(phoneCtrl.text.trim());
    final firebaseService = FirebasePhoneAuthService();
    try {
      final userCred = await firebaseService.signInWithOtp(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      if (userCred == null) {
        if (!mounted) return;
        setState(() {
          error = 'Invalid OTP';
          loading = false;
        });
        return;
      }
      final idToken = await firebaseService.getIdToken();
      if (idToken == null) {
        if (!mounted) return;
        setState(() {
          error = 'Failed to get Firebase token';
          loading = false;
        });
        return;
      }
      final deviceInfo = await DeviceService().getDeviceInfo();
      final res = await appAuth.client.dio.post(
        '/auth/verify-otp',
        data: {
          'phone': phone,
          'otp': otp,
          'firebase_id_token': idToken,
          ...?deviceInfo,
        },
        options: Options(contentType: 'application/json'),
      );
      if (res.data['requires_password'] == true) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        if (!mounted) return;
        setState(() {
          showPasswordField = true;
          requiresPassword = true;
          userRole = res.data['user']?['role'];
          loading = false;
        });
        return;
      }
      // Normal user: save session
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
        phone: phone,
      );
      if (!mounted) return;
      appTabIndex.value = 0;
      context.go('/app');
    } catch (e) {
      if (!mounted) return;
      setState(() => error = 'Login failed: ${e.toString()}');
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  Future<void> _submitWithPassword() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });
    final phone = formatPhoneNumber(phoneCtrl.text.trim());
    final password = passwordCtrl.text.trim();
    try {
      final session = await appAuth.verifyPassword(phone, password);
      if (!mounted) return;
      appTabIndex.value = 0;
      context.go('/app');
    } catch (e) {
      if (!mounted) return;
      setState(() => error = 'Password verification failed: ${e.toString()}');
    } finally {
      if (!mounted) return;
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Text('+91', style: TextStyle(fontSize: 16)),
                ),
                Expanded(
                  child: TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      border: OutlineInputBorder(),
                    ),
                    enabled: !showPasswordField,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (showPasswordField) ...[
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
                  const Icon(Icons.info_outline, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Admin or Superuser account requires password verification',
                      style: TextStyle(fontSize: 12, color: AppTheme.primaryColor),
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
                  color: AppTheme.errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.errorColor.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppTheme.errorColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error!,
                        style: TextStyle(color: AppTheme.errorColor),
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
                onPressed: loading
                    ? null
                    : showPasswordField
                        ? _submitWithPassword
                        : sendOtp,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(showPasswordField ? 'Login with Password' : 'Send OTP'),
              ),
            ),
            if (showPasswordField) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    showPasswordField = false;
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
