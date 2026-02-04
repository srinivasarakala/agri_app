import 'package:dio/dio.dart';
import 'token_storage.dart';

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
