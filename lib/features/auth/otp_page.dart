import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../shell/app_shell.dart';
import '../subdealer/subdealer_shell.dart';
import '../../core/cart/cart_state.dart';

class OtpPage extends StatefulWidget {
  final String phone;
  final String verificationId;
  final bool requiresPassword;
  final void Function(String otp, String? password) onSubmit;
  const OtpPage({super.key, required this.phone, required this.verificationId, required this.onSubmit, this.requiresPassword = false});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
    int cooldown = 0;
    late final ValueNotifier<int> cooldownNotifier;

    @override
    void initState() {
      super.initState();
      cooldownNotifier = ValueNotifier<int>(0);
    }

    void startCooldown() {
      cooldown = 60;
      cooldownNotifier.value = cooldown;
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 1));
        cooldown--;
        cooldownNotifier.value = cooldown;
        return cooldown > 0;
      });
    }
  final otpCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool obscurePassword = true;
  bool loading = false;
  String? error;

  void _submit() {
    widget.onSubmit(
      otpCtrl.text.trim(),
      widget.requiresPassword ? passwordCtrl.text.trim() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Enter the OTP sent to ${widget.phone}'),
            const SizedBox(height: 16),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
              ),
            ),
            if (widget.requiresPassword) ...[
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setState) => TextField(
                  controller: passwordCtrl,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Admin Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                      onPressed: () => setState(() => obscurePassword = !obscurePassword),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: loading ? null : _submit,
              child: loading ? const CircularProgressIndicator() : const Text('Verify'),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: TextStyle(color: AppTheme.errorColor)),
            ],
            const SizedBox(height: 24),
            ValueListenableBuilder<int>(
              valueListenable: cooldownNotifier,
              builder: (context, value, _) {
                return ElevatedButton(
                  onPressed: value > 0 ? null : () {
                    // Call resend OTP logic here
                    startCooldown();
                  },
                  child: value > 0
                      ? Text('Resend OTP in ${value}s')
                      : const Text('Resend OTP'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
