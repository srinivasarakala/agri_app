import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:pavan_agro/services/device_service.dart';
import '../../main.dart'; // to access app services
import '../shell/app_shell.dart'; // for appTabIndex
import 'firebase_phone_auth_service.dart';
import 'otp_page.dart';
import 'set_password_page.dart';

class PhonePage extends StatefulWidget {
  const PhonePage({super.key});

  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
      // Uniform button style for login/OTP actions
      final ButtonStyle uniformButtonStyle = ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
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
  String? _otpSessionToken;
  bool _mustSetPassword = false;

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

    // Fetch device info early so we can send device_id to check-access
    Map<String, dynamic> deviceInfo = {};
    try {
      deviceInfo = await DeviceService().getDeviceInfo();
    } catch (_) {}

    // --- Whitelist pre-check ---
    // Only hard-block on an explicit 403 not_whitelisted response.
    // Any other error (endpoint not deployed yet, network hiccup, etc.) falls
    // through so the OTP flow continues; the backend verify-otp enforces the
    // whitelist as the authoritative second layer.
    try {
      final checkRes = await appAuth.client.dio.post(
        '/auth/check-access',
        data: {
          'phone': phone,
          if (deviceInfo['device_id'] != null) 'device_id': deviceInfo['device_id'],
        },
        options: Options(contentType: 'application/json'),
      );
      if (checkRes.data['allowed'] != true) {
        if (!mounted) return;
        setState(() {
          error = checkRes.data['message'] ??
              'Access denied. Please contact the administrator for access.';
          loading = false;
        });
        return;
      }
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final errorCode = e.response?.data is Map ? e.response?.data['error'] : null;
      if (status == 426) {
        if (!mounted) return;
        setState(() {
          loading = false;
          error = 'Please upgrade the app to continue. Contact Administrator for help.';
        });
        return;
      }
      if (status == 403 && errorCode == 'not_whitelisted') {
        if (!mounted) return;
        setState(() {
          error = (e.response?.data['message'] as String?) ??
              'Access denied. Please contact the administrator for access.';
          loading = false;
        });
        return;
      }
      if (status == 403 && errorCode == 'device_blocked') {
        if (!mounted) return;
        setState(() {
          error = (e.response?.data['message'] as String?) ??
              'This device has been blocked. Please contact the administrator.';
          loading = false;
        });
        return;
      }
      // Endpoint not deployed yet or other transient error — fall through.
      // verify-otp on the backend will enforce the whitelist.
      print('[checkAccess] non-blocking error: $status ${e.message}');
    } catch (e) {
      // Unexpected error — fall through for same reason.
      print('[checkAccess] unexpected error: $e');
    }
    // --- End whitelist pre-check ---

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
              onSubmit: (otp, _) => _verifyOtpAndLogin(otp),
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

  /// Returns null on success (navigation happened), or an error string.
  Future<String?> _verifyOtpAndLogin(String otp) async {
    final phone = formatPhoneNumber(phoneCtrl.text.trim());
    final firebaseService = FirebasePhoneAuthService();
    try {
      final userCred = await firebaseService.signInWithOtp(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      if (userCred == null) return 'Invalid OTP. Please try again.';
      final idToken = await firebaseService.getIdToken();
      if (idToken == null) return 'Failed to get Firebase token. Please retry.';
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
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        if (!mounted) return null;

        final sessionToken = res.data['otp_session_token'] as String?;
        final mustSet = res.data['must_set_password'] == true;

        setState(() {
          _otpSessionToken = sessionToken;
          _mustSetPassword = mustSet;
          userRole = res.data['user']?['role'];
        });

        if (mustSet && sessionToken != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SetPasswordPage(
                phone: phone,
                otpSessionToken: sessionToken,
                isFirstLogin: true,
              ),
            ),
          );
          return null; // navigation handled
        }

        setState(() {
          showPasswordField = true;
          requiresPassword = true;
        });
        return null; // navigation handled (password field shown)
      }
      // Normal user: save session and navigate
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
      if (!mounted) return null;
      appTabIndex.value = 0;
      context.go('/app');
      return null;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 426) {
        return 'Please upgrade the app to continue. Contact Administrator for help.';
      }
      if (e is DioException && e.response?.statusCode == 403) {
        return (e.response?.data is Map ? e.response?.data['message'] : null)
            ?? 'Access denied. Please contact the administrator for access.';
      }
      return 'Login failed. Please try again.';
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
      if (e is DioException && e.response?.statusCode == 426) {
        setState(() {
          loading = false;
          error = 'Please upgrade the app to continue. Contact Administrator for help.';
        });
        return;
      }
      if (e is DioException) {
        final status = e.response?.statusCode;
        setState(() => error = switch (status) {
          401 => 'Incorrect password. Please try again.',
          403 => 'Access denied. Your account does not have admin privileges.',
          404 => 'Account not found. Please contact your Administrator.',
          429 => 'Too many failed attempts. Please wait and try again.',
          _ => 'Login failed. Please check your credentials and try again.',
        });
      } else {
        setState(() => error = 'Something went wrong. Please try again.');
      }
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 32),
            Image.asset(
              'assets/images/logo.png',
              height: 120,
            ),
            const SizedBox(height: 36),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Text('+91', style: TextStyle(fontSize: 16)),
                ),
                Expanded(
                  child: TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Phone number',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                    enabled: !showPasswordField,
                    onChanged: (_) => setState(() {}),
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
              // Forgot Password link — only shown when we have a valid OTP session token
              if (_otpSessionToken != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SetPasswordPage(
                            phone: formatPhoneNumber(phoneCtrl.text.trim()),
                            otpSessionToken: _otpSessionToken!,
                            isFirstLogin: false,
                          ),
                        ),
                      );
                    },
                    child: const Text('Forgot Password?'),
                  ),
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
                  : (phoneCtrl.text.length != 10 || showPasswordField)
                    ? (showPasswordField ? _submitWithPassword : null)
                    : sendOtp,
                style: uniformButtonStyle,
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
