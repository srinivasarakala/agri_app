import 'package:dio/dio.dart';
import '../auth/token_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';
import 'dart:convert';
import '../../main.dart' show showUpdateRequiredPage, showDeviceBlockedPage, showSessionExpiredPage;

class DioClient {
  final Dio dio;
  final TokenStorage storage;

  // Refresh-lock: ensures only one token-refresh is in-flight at a time.
  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshQueue = [];

  DioClient({required String baseUrl, required this.storage})
      : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip the proactive refresh for auth endpoints to avoid loops
        final isAuthPath = options.path.contains('/auth/');

        final data = await storage.readAll();
        final access = data['access'];

        // ── Proactive token refresh ───────────────────────────────────────
        // Decode the JWT exp claim locally. If the access token is already
        // expired (or will expire within 60 s), refresh BEFORE sending the
        // request so the server never sees a stale token.
        if (!isAuthPath && access != null && access.isNotEmpty && _isJwtExpired(access)) {
          final newAccess = await _refreshOrQueue(data);
          if (newAccess != null) {
            options.headers['Authorization'] = 'Bearer $newAccess';
          } else {
            // Refresh failed — clear session.  showSessionExpiredPage() was
            // already called inside _refreshOrQueue.
            return handler.reject(DioException(
              requestOptions: options,
              error: 'Session expired',
            ));
          }
        } else if (access != null && access.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $access';
        }

        // Add X-App-Version header
        try {
          final packageInfo = await PackageInfo.fromPlatform();
          options.headers['X-App-Version'] = packageInfo.version;
        } catch (_) {
          options.headers['X-App-Version'] = 'unknown';
        }

        handler.next(options);
      },

      onError: (e, handler) async {
        final path = e.requestOptions.path;
        final statusCode = e.response?.statusCode;

        // Handle version mismatch (426) globally
        if (statusCode == 426) {
          if (!path.contains('/auth/')) {
            showUpdateRequiredPage();
          }
          return handler.reject(e);
        }

        // Handle device blocked (403 device_blocked)
        final responseData = e.response?.data;
        final errorCode = responseData is Map ? responseData['error'] : null;
        if (statusCode == 403 && errorCode == 'device_blocked') {
          await storage.clear();
          showDeviceBlockedPage();
          return handler.reject(e);
        }

        // If refresh token is invalid (e.g. JWT SIGNING_KEY changed),
        // /auth/refresh returns 401. We must immediately route to login.
        if (statusCode == 401 && path.contains('/auth/')) {
          await storage.clear();
          showSessionExpiredPage();
          return handler.next(e);
        }

        // Some backends return 403 for missing/invalid auth instead of 401.
        if (statusCode == 403 && !path.contains('/auth/') && _isAuthRelatedForbidden(responseData)) {
          await storage.clear();
          showSessionExpiredPage();
          return handler.next(e);
        }

        if (statusCode != 401) return handler.next(e);

        // Never retry auth endpoints
        if (path.contains('/auth/')) {
          await storage.clear();
          showSessionExpiredPage();
          return handler.next(e);
        }

        if (e.requestOptions.extra['retried'] == true) {
          await storage.clear();
          showSessionExpiredPage();
          return handler.next(e);
        }

        final data = await storage.readAll();
        final refresh = data['refresh'];
        if (refresh == null || refresh.isEmpty) {
          await storage.clear();
          showSessionExpiredPage();
          return handler.next(e);
        }

        // ── Fallback refresh (for any 401 the proactive check missed) ────
        final newAccess = await _refreshOrQueue(data);
        if (newAccess == null || newAccess.isEmpty) {
          return handler.next(e);
        }

        final ro = e.requestOptions;
        ro.extra['retried'] = true;
        ro.headers['Authorization'] = 'Bearer $newAccess';
        try {
          final packageInfo = await PackageInfo.fromPlatform();
          ro.headers['X-App-Version'] = packageInfo.version;
        } catch (_) {
          ro.headers['X-App-Version'] = 'unknown';
        }
        final resp = await dio.fetch(ro);
        return handler.resolve(resp);
      },
    ));
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Returns true if the JWT access token is expired or will expire within
  /// 60 seconds (gives a small buffer to avoid race conditions).
  bool _isJwtExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;
      // JWT payload is base64url-encoded; add padding if needed
      var payload = parts[1];
      payload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      final decoded = utf8.decode(base64Url.decode(payload));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      final exp = json['exp'];
      if (exp == null) return false;
      final expiry = DateTime.fromMillisecondsSinceEpoch((exp as int) * 1000);
      return DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 60)));
    } catch (_) {
      return false; // Cannot parse → don't preemptively block the request
    }
  }

  /// Performs the token refresh, respecting the refresh-lock so concurrent
  /// requests share a single refresh call.  Returns the new access token, or
  /// null on failure (and handles navigation to login internally).
  Future<String?> _refreshOrQueue(Map<String, String?> storageData) async {
    if (_isRefreshing) {
      // Another call is already refreshing — wait for its result
      final completer = Completer<String?>();
      _refreshQueue.add(completer);
      return completer.future;
    }

    final refresh = storageData['refresh'];
    if (refresh == null || refresh.isEmpty) {
      await storage.clear();
      showSessionExpiredPage();
      return null;
    }

    _isRefreshing = true;
    try {
      String appVersion = 'unknown';
      try {
        final packageInfo = await PackageInfo.fromPlatform();
        appVersion = packageInfo.version;
      } catch (_) {}

      final r = await Dio(BaseOptions(
        baseUrl: dio.options.baseUrl,
        headers: {'X-App-Version': appVersion},
      )).post('/auth/refresh', data: {'refresh': refresh});

      final newAccess = r.data['access'] as String?;
      final newRefresh = r.data['refresh'] as String? ?? refresh;

      if (newAccess == null || newAccess.isEmpty) {
        _isRefreshing = false;
        for (final c in _refreshQueue) { c.complete(null); }
        _refreshQueue.clear();
        await storage.clear();
        showSessionExpiredPage();
        return null;
      }

      await storage.saveSession(
        access: newAccess,
        refresh: newRefresh,
        role: storageData['role'] ?? 'Dealer',
        subdealerId: int.tryParse(storageData['subdealer_id'] ?? ''),
      );

      _isRefreshing = false;
      for (final c in _refreshQueue) { c.complete(newAccess); }
      _refreshQueue.clear();
      return newAccess;
    } catch (_) {
      _isRefreshing = false;
      for (final c in _refreshQueue) { c.complete(null); }
      _refreshQueue.clear();
      await storage.clear();
      showSessionExpiredPage();
      return null;
    }
  }

  bool _isAuthRelatedForbidden(dynamic responseData) {
    if (responseData is! Map) return false;

    final detail = (responseData['detail'] ?? '').toString().toLowerCase();
    final code = (responseData['code'] ?? '').toString().toLowerCase();
    final error = (responseData['error'] ?? '').toString().toLowerCase();

    if (code == 'not_authenticated' || code == 'token_not_valid') return true;
    if (error == 'token_not_valid') return true;

    return detail.contains('authentication credentials were not provided') ||
        detail.contains('not authenticated') ||
        detail.contains('token is invalid') ||
        detail.contains('token not valid');
  }
}
