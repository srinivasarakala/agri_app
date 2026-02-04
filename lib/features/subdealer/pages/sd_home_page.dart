import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../main.dart';

class SdHomePage extends StatelessWidget {
  const SdHomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await appAuth.logout();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text('Subdealer Home (TODO)')),
    );
  }
}
