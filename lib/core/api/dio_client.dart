import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import '../auth/token_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:developer' as developer;
import '../../main.dart' show showUpdateRequiredPage, showDeviceBlockedPage, showSessionExpiredPage;

class DioClient {
  final Dio dio;
  final TokenStorage storage;

  DioClient({required String baseUrl, required this.storage})
      : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final data = await storage.readAll();
        final access = data['access'];
        if (access != null && access.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $access';
        }
        // Add X-App-Version header
        try {
          // Use package_info_plus to get app version
          final packageInfo = await PackageInfo.fromPlatform();
          options.headers['X-App-Version'] = packageInfo.version;
        } catch (_) {
          // Fallback if package_info fails
          options.headers['X-App-Version'] = 'unknown';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        // Handle version mismatch (426) globally
        if (e.response?.statusCode == 426) {
          final path = e.requestOptions.path;
          // Auth pages handle 426 inline (show error text to the user).
          // For all other pages, navigate to the full-screen UpdateRequiredPage.
          if (!path.contains('/auth/')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showUpdateRequiredPage();
            });
          }
          return handler.reject(e); // resolve the future so callers don't hang
        }

        // Handle device blocked (403 device_blocked) — clear session immediately,
        // do NOT attempt a token refresh (the new token would still be blocked).
        final responseData = e.response?.data;
        final errorCode = responseData is Map ? responseData['error'] : null;
        if (e.response?.statusCode == 403 && errorCode == 'device_blocked') {
          await storage.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDeviceBlockedPage();
          });
          return handler.reject(e);
        }

        if (e.response?.statusCode != 401) return handler.next(e);
        // Never retry auth-related endpoints to avoid infinite loops / stale-token confusion
        final path = e.requestOptions.path;
        if (path.contains('/auth/')) {
          await storage.clear();
          return handler.next(e);
        }
        if (e.requestOptions.extra['retried'] == true) {
          // Refresh already failed, clear session and redirect to login
          await storage.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showSessionExpiredPage();
          });
          return handler.next(e);
        }

        final data = await storage.readAll();
        final refresh = data['refresh'];
        if (refresh == null || refresh.isEmpty) {
          await storage.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showSessionExpiredPage();
          });
          return handler.next(e);
        }

        try {
          // refresh access
          final r = await Dio(BaseOptions(baseUrl: dio.options.baseUrl)).post(
            '/auth/refresh',
            data: {'refresh': refresh},
          );

          final newAccess = r.data['access'] as String?;
          // ROTATE_REFRESH_TOKENS=True means the backend also returns a new
          // refresh token and blacklists the old one. Must save it or every
          // subsequent refresh will fail with 401 (blacklisted token).
          final newRefresh = r.data['refresh'] as String? ?? refresh;
          if (newAccess == null || newAccess.isEmpty) {
            await storage.clear();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showSessionExpiredPage();
            });
            return handler.next(e);
          }

          // save both new access AND new refresh tokens
          await storage.saveSession(
            access: newAccess,
            refresh: newRefresh,
            role: data['role'] ?? 'Dealer',
            subdealerId: int.tryParse(data['subdealer_id'] ?? ''),
          );

          // retry original request
          final ro = e.requestOptions;
          ro.extra['retried'] = true;
          ro.headers['Authorization'] = 'Bearer $newAccess';
          // Add X-App-Version header to retried request
          try {
            final packageInfo = await PackageInfo.fromPlatform();
            ro.headers['X-App-Version'] = packageInfo.version;
          } catch (_) {
            ro.headers['X-App-Version'] = 'unknown';
          }

          final resp = await dio.fetch(ro);
          return handler.resolve(resp);
        } catch (_) {
          // Refresh token is invalid/expired, clear session and redirect to login
          await storage.clear();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showSessionExpiredPage();
          });
          return handler.next(e);
        }
      },
    ));
  }
}
