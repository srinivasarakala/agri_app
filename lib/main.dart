import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:flutter/foundation.dart';
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
import 'package:flutter/foundation.dart';
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
late final CatalogSearchBus catalogSearchBus;

FirebaseAnalytics? analytics;

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
GoRouter? globalRouter;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase in all modes (debug and release)
  await Firebase.initializeApp();
  analytics = FirebaseAnalytics.instance;

  // Initialize SharedPreferences for cart storage
  await initCartStorage();

  final storage = TokenStorage();
  final client = DioClient(
    baseUrl: 'https://myhitechagro.in', 
    // production
     //baseUrl: 'http://10.0.2.2:8000', //lcoal
    // baseUrl: 'http://192.168.1.7:8000', 
    // local IP for testing on real device
    storage: storage,
  );

  catalogSearchBus = CatalogSearchBus();
  appAuth = AuthService(client: client, storage: storage);
  catalogApi = CatalogService(client);
  cartApi = CartService(client);
  profileApi = ProfileService(client);
  ledgerApi = LedgerService(client);
  stockHistoryApi = StockHistoryService(client);
  ordersApi = OrdersService(client);

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

class AgriApp extends StatelessWidget {
  const AgriApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final router = buildRouter();
    globalRouter = router;
    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.themeData,
      // Optionally set navigatorKey if needed for dialogs
    );
  }
}

