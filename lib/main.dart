import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
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
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'features/update_required_page.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:dio/dio.dart';
import 'features/admin/pages/admin_orders_page.dart';
import 'features/dealer/pages/sd_my_orders_page.dart';

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


// Initialize once in main()
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
const AndroidNotificationChannel _defaultNotificationChannel =
    AndroidNotificationChannel(
      'default_channel',
      'Default',
      description: 'General order and app notifications',
      importance: Importance.max,
    );
const int _maxNotificationId = 0x7fffffff;

Map<String, dynamic>? _pendingNotificationData;
bool _isHandlingNotificationTap = false;

int _buildNotificationId(RemoteMessage message) {
  final source =
      message.messageId ??
      message.data['order_id']?.toString() ??
      '${message.sentTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}:${message.notification?.title ?? ''}:${message.notification?.body ?? ''}';

  var hash = 0;
  for (final codeUnit in source.codeUnits) {
    hash = ((hash * 31) + codeUnit) & _maxNotificationId;
  }

  return hash == 0
      ? DateTime.now().millisecondsSinceEpoch.remainder(_maxNotificationId)
      : hash;
}

Future<void> _showForegroundNotification(RemoteMessage message) async {
  final notification = message.notification;
  final data = message.data;
  final title = notification?.title ?? data['title']?.toString() ?? 'Notification';
  final body = notification?.body ?? data['body']?.toString() ?? '';

  await flutterLocalNotificationsPlugin.show(
    id: _buildNotificationId(message),
    title: title,
    body: body,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'default_channel',
        'Default',
        channelDescription: 'General order and app notifications',
        icon: 'ic_notification',
        color: Color(0xFF2E7D32),
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    ),
    payload: jsonEncode(data),
  );
}

Future<void> _registerFcmTokenIfLoggedIn(String token) async {
  if (token.isEmpty) return;

  currentSession ??= await appAuth.restore();
  if (currentSession == null) return;

  try {
    await appAuth.client.dio.post(
      '/api/notifications/save-device-token/',
      data: {'device_token': token},
      options: Options(contentType: 'application/json'),
    );
  } catch (_) {
    // Best-effort only: notification registration should never block app flow.
  }
}

Future<void> _setupFcmTokenSync(FirebaseMessaging messaging) async {
  // Sync the current token on startup for already logged-in users.
  final token = await messaging.getToken();
  if (token != null) {
    await _registerFcmTokenIfLoggedIn(token);
  }

  // Sync any future token rotation automatically.
  messaging.onTokenRefresh.listen((newToken) async {
    await _registerFcmTokenIfLoggedIn(newToken);
  });
}

Future<void> _handleOrderNotificationTap(Map<String, dynamic> data) async {
  final type = (data['type'] ?? '').toString();
  if (type != 'order') return;

  final orderId = int.tryParse((data['order_id'] ?? '').toString());
  if (orderId == null) return;

  if (_isHandlingNotificationTap) return;
  _isHandlingNotificationTap = true;

  try {
    currentSession ??= await appAuth.restore();
    if (currentSession == null) {
      _goLogin();
      return;
    }

    globalRouter?.go('/app');
    await Future.delayed(const Duration(milliseconds: 250));

    final nav = navigatorKey.currentState;
    if (nav == null) {
      _pendingNotificationData = data;
      return;
    }

    final isAdmin = (currentSession?.role ?? '').toLowerCase() == 'admin';
    await nav.push(
      MaterialPageRoute(
        builder: (_) => isAdmin
            ? AdminOrdersPage(initialOrderId: orderId)
            : SdMyOrdersPage(initialOrderId: orderId),
      ),
    );
  } finally {
    _isHandlingNotificationTap = false;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase in all modes (debug and release)
  await Firebase.initializeApp();
  analytics = FirebaseAnalytics.instance;

  // Initialize Firebase Messaging for push notifications
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request notification permissions (iOS, Android 13+)
  await messaging.requestPermission();

  // Initialize local notifications and handle local notification tap.
  const androidInit = AndroidInitializationSettings('@mipmap/launcher_icon');
  await flutterLocalNotificationsPlugin.initialize(
    settings: const InitializationSettings(android: androidInit),
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      final payload = response.payload;
      if (payload == null || payload.isEmpty) return;
      try {
        final decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          await _handleOrderNotificationTap(decoded);
        }
      } catch (_) {}
    },
  );

  final androidNotifications = flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  await androidNotifications?.createNotificationChannel(_defaultNotificationChannel);

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    print('Received foreground notification: ${message.notification?.title ?? message.data['title']}');
    await _showForegroundNotification(message);
  });

  // Handle background and terminated messages
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    print('Notification opened: ${message.notification?.title}');
    await _handleOrderNotificationTap(message.data);
  });

  final initialMessage = await messaging.getInitialMessage();
  if (initialMessage != null) {
    _pendingNotificationData = initialMessage.data;
  }

  // Get and print device token (send this to backend for targeting)
  String? fcmToken = await messaging.getToken();
  print('FCM Token: ${fcmToken}');

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

  final phone = currentSession?.phone;
  print('main(): Session phone: $phone');  // Debug

  // Restore session FIRST
  currentSession ??= await appAuth.restore();
  print('main(): Restored session: ${currentSession?.phone}');

  await _setupFcmTokenSync(messaging);

  // NOW load cart with guaranteed session
  if (currentSession?.phone != null) {
    print('main(): Loading cart for ${currentSession!.phone}');
    Future.microtask(() {
      loadUserCart(currentSession!.phone!);
    });
  } else {
    print('main(): No session, cart remains empty');
  }
  runApp(const AgriApp());
}

// create an function to sort an array


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
    final context = navigatorKey.currentContext;
    if (context != null) {
      GoRouter.of(context).go('/login');
    }
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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final pendingData = _pendingNotificationData;
      if (pendingData == null) return;
      _pendingNotificationData = null;
      await _handleOrderNotificationTap(pendingData);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      theme: AppTheme.themeData,
    );
  }
}

