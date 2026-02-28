import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';

import 'features/auth/phone_page.dart';
// import 'features/auth/otp_page.dart'; // OTP disabled
import 'features/shell/app_shell.dart';
import 'features/splash/splash_screen.dart';
import 'main.dart'; // contains appAuth + currentSession
import 'features/update_required_page.dart';

GoRouter buildRouter({FirebaseAnalytics? analytics}) {
  return GoRouter(
    observers: [
      if (analytics != null) FirebaseAnalyticsObserver(analytics: analytics),
    ],
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const PhonePage()),
      GoRoute(
        path: '/update-required',
        builder: (_, __) => const UpdateRequiredPage(),
      ),
      GoRoute(
        path: '/app',
        builder: (_, __) {
          // currentSession is set by redirect()
          final role = currentSession?.role ?? "SUBDEALER";
          return AppShell(role: role); // ✅ NO const
        },
      ),
    ],

    redirect: (context, state) async {
      final loc = state.uri.toString();

      // Allow splash screen without redirect
      if (loc == '/') return null;

      final isAuth = (loc == '/login'); // Removed /otp since it's disabled

      // Restore session once per navigation; cache it globally
      currentSession = await appAuth.restore();

      // Not logged in -> force login
      if (currentSession == null) {
        return isAuth ? null : '/login';
      }

      // Logged in -> always go to /app if on auth screens
      if (isAuth) return '/app';

      // Already logged in and trying other routes -> allow
      return null;
    },
  );
}
