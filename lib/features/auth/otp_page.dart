import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

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
      // Uniform button style for OTP actions
      final ButtonStyle uniformButtonStyle = ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      );
    int cooldown = 0;
    late final ValueNotifier<int> cooldownNotifier;

    @override
    void initState() {
      super.initState();
      cooldownNotifier = ValueNotifier<int>(0);
      startCooldown();
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
  final List<TextEditingController> otpCtrls = List.generate(6, (_) => TextEditingController());
  int otpIndex = 0;
  final passwordCtrl = TextEditingController();
  bool obscurePassword = true;
  bool loading = false;
  String? error;

  void _submit() {
    final otp = otpCtrls.map((c) => c.text).join();
    widget.onSubmit(
      otp,
      widget.requiresPassword ? passwordCtrl.text.trim() : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Image.asset(
              'assets/images/logo.png',
              height: 90,
            ),
            const SizedBox(height: 20),
            Text('Enter the OTP sent to ${widget.phone}'),
            const SizedBox(height: 16),
            ValueListenableBuilder<int>(
              valueListenable: cooldownNotifier,
              builder: (context, value, _) {
                return Text('Enter OTP within ${value}s', style: const TextStyle(color: Colors.grey));
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) => SizedBox(
                width: 40,
                child: TextField(
                  controller: otpCtrls[i],
                  autofocus: i == 0,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  decoration: const InputDecoration(counterText: '', border: OutlineInputBorder()),
                  onChanged: (val) {
                    if (val.length == 1 && i < 5) {
                      FocusScope.of(context).nextFocus();
                    } else if (val.isEmpty && i > 0) {
                      FocusScope.of(context).previousFocus();
                    }
                    setState(() {});
                  },
                ),
              )),
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
              onPressed: loading || cooldownNotifier.value <= 0 || otpCtrls.any((c) => c.text.isEmpty)
                ? null
                : () {
                    final otp = otpCtrls.map((c) => c.text).join();
                    widget.onSubmit(otp, widget.requiresPassword ? passwordCtrl.text.trim() : null);
                  },
              style: uniformButtonStyle,
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
                  onPressed: value == 0 ? () {
                    // Call resend OTP logic here
                    startCooldown();
                    otpCtrls.forEach((c) => c.clear());
                  } : null,
                  style: uniformButtonStyle,
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
