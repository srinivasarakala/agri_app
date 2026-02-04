import 'package:flutter/material.dart';
import 'app_router.dart';
import 'core/api/dio_client.dart';
import 'core/auth/token_storage.dart';
import 'features/auth/auth_service.dart';
import 'features/catalog/catalog_service.dart';
import 'features/orders/orders_service.dart';
import 'core/state/catalog_search_bus.dart';


late final OrdersService ordersApi;
late final AuthService appAuth;
late final CatalogService catalogApi;
late final CatalogSearchBus catalogSearchBus;


void main() {
  final storage = TokenStorage();
  final client = DioClient(
    baseUrl: 'http://10.0.2.2:8000', // emulator -> PC
    storage: storage,
  );
  
  catalogSearchBus = CatalogSearchBus();
  appAuth = AuthService(client: client, storage: storage);
  catalogApi = CatalogService(client);
  ordersApi = OrdersService(client);


  runApp(const AgriApp());
}

class AgriApp extends StatelessWidget {
  const AgriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
  title: 'Agri B2B',

  theme: ThemeData(
    useMaterial3: false, // fixes many light color issues
    primarySwatch: Colors.green,
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
    ),
  ),

  routerConfig: buildRouter(),
);

  }
}
