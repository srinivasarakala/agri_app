import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _s = FlutterSecureStorage();

  static const _kAccess = 'access';
  static const _kRefresh = 'refresh';
  static const _kRole = 'role';
  static const _kSubdealerId = 'subdealer_id';

  Future<void> saveSession({
    required String access,
    required String refresh,
    required String role,
    required int? subdealerId,
  }) async {
    await _s.write(key: _kAccess, value: access);
    await _s.write(key: _kRefresh, value: refresh);
    await _s.write(key: _kRole, value: role);
    await _s.write(key: _kSubdealerId, value: subdealerId?.toString());
  }

  Future<Map<String, String?>> readAll() async {
    return {
      'access': await _s.read(key: _kAccess),
      'refresh': await _s.read(key: _kRefresh),
      'role': await _s.read(key: _kRole),
      'subdealer_id': await _s.read(key: _kSubdealerId),
    };
  }

  Future<void> clear() async => _s.deleteAll();
}
