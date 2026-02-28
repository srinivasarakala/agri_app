import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/auth/session.dart';
import '../../core/auth/token_storage.dart';
import '../../main.dart' show analytics;

class AuthService {
  final DioClient client;
  final TokenStorage storage;

  AuthService({required this.client, required this.storage});

  String formatPhoneNumber(String input) {
    String trimmed = input.trim();
    if (!trimmed.startsWith("+91")) {
      trimmed = trimmed.replaceFirst(RegExp(r'^0+'), '');
      return "+91$trimmed";
    }
    return trimmed;
  }

  Future<void> sendOtp(String phone) async {
    final formattedPhone = formatPhoneNumber(phone);
    await client.dio.post(
      '/auth/send-otp',
      data: {'phone': formattedPhone},
      options: Options(contentType: 'application/json'),
    );
  }

  Future<Session> verifyOtp(String phone, String otp, {String? password, Map<String, dynamic>? deviceInfo, String? firebaseIdToken}) async {
    final formattedPhone = formatPhoneNumber(phone);
    final data = {
      'phone': formattedPhone,
      'otp': otp,
      if (password != null && password.isNotEmpty) 'password': password,
      if (firebaseIdToken != null) 'firebase_id_token': firebaseIdToken,
    };
    if (deviceInfo != null) {
      final deviceInfoStr = deviceInfo.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      data.addAll(deviceInfoStr);
    }
    final res = await client.dio.post(
      '/auth/verify-otp',
      data: data,
      options: Options(contentType: 'application/json'),
    );

    final access = res.data['access'] as String;
    final refresh = res.data['refresh'] as String;
    final user = res.data['user'] as Map<String, dynamic>;

    final role = user['role'] as String;
    final subdealerId = user['subdealer_id'] as int?;

    await storage.saveSession(
      access: access,
      refresh: refresh,
      role: role,
      subdealerId: subdealerId,
      phone: formattedPhone,
    );

    // After successful login:
    // - Set FirebaseAnalytics user ID
    // - Log login event
    // - Include user role as parameter
    if (analytics != null) {
      await analytics!.setUserId(id: formattedPhone);
      await analytics!.logEvent(
        name: 'login',
        parameters: {
          'role': role,
          'phone': phone,
        },
      );
    }

    return Session(
      accessToken: access,
      refreshToken: refresh,
      role: role,
      subdealerId: subdealerId,
      phone: phone,
    );
  }

  Future<Session> verifyPassword(String phone, String password) async {
    final formattedPhone = formatPhoneNumber(phone);
    final res = await client.dio.post(
      '/auth/verify-password',
      data: {
        'phone': formattedPhone,
        'password': password,
      },
      options: Options(contentType: 'application/json'),
    );
    final access = res.data['access'] as String;
    final refresh = res.data['refresh'] as String;
    final user = res.data['user'] as Map<String, dynamic>;
    final role = user['role'] as String;
    final subdealerId = user['subdealer_id'] as int?;
    await storage.saveSession(
      access: access,
      refresh: refresh,
      role: role,
      subdealerId: subdealerId,
      phone: formattedPhone,
    );
    if (analytics != null) {
      await analytics!.setUserId(id: formattedPhone);
      await analytics!.logEvent(
        name: 'login',
        parameters: {
          'role': role,
          'phone': formattedPhone,
        },
      );
    }
    return Session(
      accessToken: access,
      refreshToken: refresh,
      role: role,
      subdealerId: subdealerId,
      phone: phone,
    );
  }

  Future<Session?> restore() async {
    final data = await storage.readAll();
    final access = data['access'];
    final refresh = data['refresh'];
    final role = data['role'];
    final phone = data['phone'];

    if (access == null || refresh == null || role == null) return null;

    final subdealerId = int.tryParse(data['subdealer_id'] ?? '');

    return Session(
      accessToken: access,
      refreshToken: refresh,
      role: role,
      subdealerId: subdealerId,
      phone: phone,
    );
  }

  Future<void> logout() async {
    // Read phone before clearing storage
    final data = await storage.readAll();
    final phone = data['phone'];
    await storage.clear();
    // Log logout event to Firebase Analytics
    if (analytics != null) {
      await analytics!.logEvent(
        name: 'logout',
        parameters: {
          if (phone != null) 'phone': phone,
        },
      );
    }
}

}
