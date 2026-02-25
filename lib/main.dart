import 'package:flutter/material.dart';
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

Session? currentSession;

late final OrdersService ordersApi;
late final AuthService appAuth;
late final CatalogService catalogApi;
late final CartService cartApi;
late final ProfileService profileApi;
late final LedgerService ledgerApi;
late final StockHistoryService stockHistoryApi;
late final CatalogSearchBus catalogSearchBus;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences for cart storage
  await initCartStorage();

  final storage = TokenStorage();
  final client = DioClient(
    //baseUrl: 'https://myhitechagro.in', // production
    baseUrl: 'http://10.0.2.2:8000', //lcoal
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

class AgriApp extends StatelessWidget {
  const AgriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Agri B2B',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: false, // fixes many light color issues
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        canvasColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.green,
        ).copyWith(
          surface: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
        ),
      ),

      builder: (context, child) {
        return ColoredBox(
          color: Colors.white,
          child: child ?? const SizedBox(),
        );
      },

      routerConfig: buildRouter(),
    );
  }
}
