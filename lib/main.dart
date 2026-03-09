import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'app_router.dart';
import 'core/api/dio_client.dart';
import 'core/auth/token_storage.dart';
import 'features/auth/auth_service.dart';
import 'features/catalog/catalog_service.dart';
import 'features/orders/orders_service.dart';
import 'core/state/catalog_search_bus.dart';
import 'core/auth/session.dart';
import 'core/cart/cart_state.dart';
import 'core/cart/cart_service.dart';
import 'features/profile/profile_service.dart';
import 'features/finance/ledger_service.dart';
import 'features/stock/stock_history_service.dart';
import 'features/admin/dealer_whitelist_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'features/update_required_page.dart';
import 'features/splash/splash_screen.dart';
import 'package:go_router/go_router.dart';

Session? currentSession;

late final OrdersService ordersApi;
late final AuthService appAuth;
late final CatalogService catalogApi;
late final CartService cartApi;
late final ProfileService profileApi;
late final LedgerService ledgerApi;
late final StockHistoryService stockHistoryApi;
late final DealerWhitelistService dealerWhitelistApi;
late final CatalogSearchBus catalogSearchBus;

FirebaseAnalytics? analytics;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
GoRouter? globalRouter;

/// Returns the correct backend base URL for debug runs:
/// - Android emulator  → http://10.0.2.2:8000   (host loopback alias)
/// - iOS simulator     → http://127.0.0.1:8000
/// - Real device       → http://192.168.1.7:8000 (your local Wi-Fi IP)
Future<String> _resolveBaseUrl() async {
  const realDeviceUrl = 'http://192.168.1.7:8000';
  try {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await info.androidInfo;
      return android.isPhysicalDevice ? realDeviceUrl : 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      final ios = await info.iosInfo;
      return ios.isPhysicalDevice ? realDeviceUrl : 'http://127.0.0.1:8000';
    }
  } catch (_) {}
  return realDeviceUrl;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase in all modes (debug and release)
  await Firebase.initializeApp();
  analytics = FirebaseAnalytics.instance;

  // Initialize SharedPreferences for cart storage
  await initCartStorage();

  final storage = TokenStorage();
  final client = DioClient(
    baseUrl: kReleaseMode
        ? 'https://myhitechagro.in'          // release build  → cloud
        : await _resolveBaseUrl(),           // debug           → auto-detect
    storage: storage,
  );

  catalogSearchBus = CatalogSearchBus();
  appAuth = AuthService(client: client, storage: storage);
  catalogApi = CatalogService(client);
  cartApi = CartService(client);
  profileApi = ProfileService(client);
  ledgerApi = LedgerService(client);
  stockHistoryApi = StockHistoryService(client);
  dealerWhitelistApi = DealerWhitelistService(client);
  ordersApi = OrdersService(client);

  // Restore cart and favorites for logged-in user
  final phone = currentSession?.phone;
  if (phone != null) {
    await loadUserCart(phone);
  }
  runApp(const AgriApp());
}

void showUpdateRequiredPage() {
  if (globalRouter != null) {
    globalRouter!.go('/update-required');
  } else {
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => UpdateRequiredPage(),
      ),
      (route) => false,
    );
  }
}

/// Called when the backend reports this device has been blocked.
/// Clears all local state and returns the user to the login screen.
void showDeviceBlockedPage() {
  currentSession = null;
  _goLogin();
}

/// Called when the JWT access token has expired and the refresh token is also
/// expired or invalid. Clears all local state and returns the user to login.
void showSessionExpiredPage() {
  currentSession = null;
  _goLogin();
}

/// Navigate to /login using GoRouter; falls back to the raw Navigator if the
/// router is not yet available (e.g. called very early during startup).
void _goLogin() {
  if (globalRouter != null) {
    globalRouter!.go('/login');
  } else {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
  }
}

class AgriApp extends StatefulWidget {
  const AgriApp({Key? key}) : super(key: key);

  @override
  State<AgriApp> createState() => _AgriAppState();
}

class _AgriAppState extends State<AgriApp> {
  // Router is created once and reused — recreating it on every build would
  // reset the entire navigation stack and produce stale globalRouter refs.
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = buildRouter();
    globalRouter = _router;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      theme: AppTheme.themeData,
    );
  }
}

