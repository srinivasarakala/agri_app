import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

class OtpPage extends StatefulWidget {
  final String phone;
  final String verificationId;
  final bool requiresPassword;
  // Returns null on success (navigation happened), or an error string to display.
  final Future<String?> Function(String otp, String? password) onSubmit;

  const OtpPage({
    super.key,
    required this.phone,
    required this.verificationId,
    required this.onSubmit,
    this.requiresPassword = false,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  static const int _otpLength = 6;
  static const int _cooldownSeconds = 60;

  final List<TextEditingController> _ctrls =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _nodes =
      List.generate(_otpLength, (_) => FocusNode());

  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _error;

  late final ValueNotifier<int> _cooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _cooldown = ValueNotifier(_cooldownSeconds);
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldown.dispose();
    for (final c in _ctrls) c.dispose();
    for (final n in _nodes) n.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    _cooldown.value = _cooldownSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldown.value <= 1) {
        _cooldown.value = 0;
        t.cancel();
      } else {
        _cooldown.value--;
      }
    });
  }

  String get _otpValue => _ctrls.map((c) => c.text).join();
  bool get _otpComplete => _otpValue.length == _otpLength;

  void _onOtpChanged(int index, String value) {
    // Handle paste: if 6 digits pasted into any field, distribute them
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.length >= _otpLength) {
        for (int i = 0; i < _otpLength; i++) {
          _ctrls[i].text = digits[i];
        }
        _nodes[_otpLength - 1].requestFocus();
        setState(() {});
        return;
      }
    }
    if (value.isNotEmpty && index < _otpLength - 1) {
      _nodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _ctrls[index].text.isEmpty &&
        index > 0) {
      _nodes[index - 1].requestFocus();
      _ctrls[index - 1].clear();
      setState(() {});
    }
  }

  void _submit() async {
    if (!_otpComplete || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.onSubmit(
      _otpValue,
      widget.requiresPassword ? _passwordCtrl.text.trim() : null,
    );
    if (!mounted) return;
    // null = success (page navigated away); non-null = error message
    if (result != null) {
      setState(() {
        _error = result;
        _loading = false;
      });
    }
  }

  void _resend() {
    for (final c in _ctrls) c.clear();
    _nodes[0].requestFocus();
    _startCooldown();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Image.asset('assets/images/logo.png', height: 110),
            const SizedBox(height: 28),
            Text(
              'OTP Sent',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the 6-digit code sent to',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              widget.phone,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 28),

            // OTP boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_otpLength, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: SizedBox(
                    width: 46,
                    height: 56,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (e) => _onKeyEvent(i, e),
                      child: TextField(
                        controller: _ctrls[i],
                        focusNode: _nodes[i],
                        autofocus: i == 0,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _ctrls[i].text.isNotEmpty
                                  ? theme.colorScheme.primary
                                  : Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: _ctrls[i].text.isNotEmpty
                              ? theme.colorScheme.primary.withOpacity(0.06)
                              : Colors.grey.shade50,
                        ),
                        onChanged: (v) => _onOtpChanged(i, v),
                      ),
                    ),
                  ),
                );
              }),
            ),

            // Resend cooldown hint
            const SizedBox(height: 16),
            ValueListenableBuilder<int>(
              valueListenable: _cooldown,
              builder: (_, value, __) => value > 0
                  ? Text(
                      'Resend OTP in ${value}s',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 13),
                    )
                  : TextButton(
                      onPressed: _resend,
                      child: const Text('Resend OTP'),
                    ),
            ),

            // Password field (admin only)
            if (widget.requiresPassword) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Admin Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
            ],

            // Error
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style:
                    TextStyle(color: AppTheme.errorColor, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 28),

            // Verify button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _otpComplete && !_loading ? _submit : null,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify OTP'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

