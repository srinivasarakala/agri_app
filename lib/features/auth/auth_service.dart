import '../../core/api/dio_client.dart';
import '../../core/auth/session.dart';
import '../../core/auth/token_storage.dart';

class AuthService {
  final DioClient client;
  final TokenStorage storage;

  AuthService({required this.client, required this.storage});

  Future<void> sendOtp(String phone) async {
    await client.dio.post('/auth/send-otp', data: {'phone': phone});
  }

  Future<Session> verifyOtp(String phone, String otp) async {
    final res = await client.dio.post('/auth/verify-otp', data: {
      'phone': phone,
      'otp': otp,
    });

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
    );

    return Session(
      accessToken: access,
      refreshToken: refresh,
      role: role,
      subdealerId: subdealerId,
    );
  }

  Future<Session?> restore() async {
    final data = await storage.readAll();
    final access = data['access'];
    final refresh = data['refresh'];
    final role = data['role'];

    if (access == null || refresh == null || role == null) return null;

    final subdealerId = int.tryParse(data['subdealer_id'] ?? '');

    return Session(
      accessToken: access,
      refreshToken: refresh,
      role: role,
      subdealerId: subdealerId,
    );
  }

  Future<void> logout() async {
  await storage.clear();
}

}
