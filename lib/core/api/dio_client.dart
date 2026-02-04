import 'package:dio/dio.dart';
import '../auth/token_storage.dart';

class DioClient {
  final Dio dio;
  final TokenStorage storage;

  DioClient({
    required String baseUrl,
    required this.storage,
  }) : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 30),
          headers: {'Content-Type': 'application/json'},
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final data = await storage.readAll();
        final token = data['access'];
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }
}
