import 'package:go_router/go_router.dart';
import 'features/auth/phone_page.dart';
import 'features/auth/otp_page.dart';
import 'features/admin/admin_shell.dart';
import 'features/subdealer/subdealer_shell.dart';
import 'main.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (_, __) => const PhonePage(),
      ),
      GoRoute(
        path: '/otp',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OtpPage(phone: extra['phone'] as String);
        },
      ),
      // ✅ IMPORTANT: /admin must load AdminShell (with bottom nav)
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminShell(),
      ),
      GoRoute(
        path: '/subdealer',
        builder: (_, __) => const SubdealerShell(),
      ),
    ],
    redirect: (context, state) async {
      final loc = state.uri.toString();
      final isAuth = (loc == '/login' || loc == '/otp');

      final session = await appAuth.restore();
      if (session == null) return isAuth ? null : '/login';

      if (isAuth) return session.isAdmin ? '/admin' : '/subdealer';
      return null;
    },
  );
}
