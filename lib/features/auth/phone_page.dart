import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart'; // to access app services

class PhonePage extends StatefulWidget {
  const PhonePage({super.key});

  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
  final phoneCtrl = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> sendOtp() async {
    setState(() { loading = true; error = null; });
    try {
      final phone = phoneCtrl.text.trim();
      await appAuth.sendOtp(phone);
      if (!mounted) return;
      context.go('/otp', extra: {'phone': phone});
    } catch (_) {
      setState(() => error = 'Failed to send OTP');
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
              decoration: const InputDecoration(labelText: 'Phone number'),
            ),
            const SizedBox(height: 12),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loading ? null : sendOtp,
              child: loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send OTP'),
            )
          ],
        ),
      ),
    );
  }
}
