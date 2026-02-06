import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';

class OtpPage extends StatefulWidget {
  final String phone;
  const OtpPage({super.key, required this.phone});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final otpCtrl = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> verify() async {
    setState(() { loading = true; error = null; });
    try {
      await appAuth.verifyOtp(widget.phone, otpCtrl.text.trim());
      if (!mounted) return;
      context.go('/app');
    } catch (_) {
      setState(() => error = 'Invalid OTP');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('OTP sent to ${widget.phone}'),
            TextField(
              controller: otpCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '6-digit OTP'),
            ),
            const SizedBox(height: 12),
            if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: loading ? null : verify,
              child: loading
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Verify'),
            )
          ],
        ),
      ),
    );
  }
}
