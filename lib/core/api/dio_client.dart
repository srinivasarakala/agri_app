import 'package:dio/dio.dart';
import '../auth/token_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:developer' as developer;
import '../../main.dart' show showUpdateRequiredPage;

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
          showUpdateRequiredPage();
          return;
        }

        if (e.response?.statusCode != 401) return handler.next(e);
        if (e.requestOptions.extra['retried'] == true) {
          // Refresh already failed, clear session
          await storage.clear();
          return handler.next(e);
        }

        final data = await storage.readAll();
        final refresh = data['refresh'];
        if (refresh == null || refresh.isEmpty) {
          await storage.clear();
          return handler.next(e);
        }

        try {
          // refresh access
          final r = await Dio(BaseOptions(baseUrl: dio.options.baseUrl)).post(
            '/auth/refresh',
            data: {'refresh': refresh},
          );

          final newAccess = r.data['access'] as String?;
          if (newAccess == null || newAccess.isEmpty) {
            await storage.clear();
            return handler.next(e);
          }

          // save new access, keep refresh + role values intact
          await storage.saveSession(
            access: newAccess,
            refresh: refresh,
            role: data['role'] ?? 'SUBDEALER',
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
          // Refresh token is invalid/expired, clear session
          await storage.clear();
          return handler.next(e);
        }
      },
    ));
  }
}
