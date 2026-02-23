import 'package:dio/dio.dart';
import '../auth/token_storage.dart';

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
        handler.next(options);
      },
      onError: (e, handler) async {
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
