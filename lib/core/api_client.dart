import 'package:dio/dio.dart';
import 'token_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ApiClient {
  final Dio dio;
  final TokenStorage storage;

  // Change this if your backend uses a different refresh URL
  static const String refreshPath = '/auth/refresh';

  ApiClient({required String baseUrl, required this.storage})
      : dio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _attachInterceptors();
  }

  void _attachInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final access = await storage.getAccess();
          if (access != null && access.isNotEmpty) {
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
          // Only handle 401
          if (e.response?.statusCode != 401) {
            return handler.next(e);
          }

          // Avoid infinite refresh loop
          final alreadyTried = e.requestOptions.extra['retried'] == true;
          if (alreadyTried) return handler.next(e);

          final refresh = await storage.getRefresh();
          if (refresh == null || refresh.isEmpty) {
            return handler.next(e);
          }

          try {
            // Refresh access token
            final refreshRes = await Dio(BaseOptions(baseUrl: dio.options.baseUrl)).post(
              refreshPath,
              data: {'refresh': refresh},
            );

            final newAccess = refreshRes.data['access'] as String;
            await storage.saveAccess(newAccess);

            // Retry original request with new access token
            final opts = e.requestOptions;
            opts.extra['retried'] = true;
            opts.headers['Authorization'] = 'Bearer $newAccess';
            // Add X-App-Version header to retried request
            try {
              final packageInfo = await PackageInfo.fromPlatform();
              opts.headers['X-App-Version'] = packageInfo.version;
            } catch (_) {
              opts.headers['X-App-Version'] = 'unknown';
            }

            final response = await dio.fetch(opts);
            return handler.resolve(response);
          } catch (_) {
            // Refresh failed -> let caller handle logout
            return handler.next(e);
          }
        },
      ),
    );
  }
}
