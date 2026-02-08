import '../../core/api/dio_client.dart';
import 'user_profile.dart';

class ProfileService {
  final DioClient _dio;

  ProfileService(this._dio);

  Future<UserProfile> getProfile() async {
    final res = await _dio.dio.get('/me');
    return UserProfile.fromJson(res.data);
  }

  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    final res = await _dio.dio.put('/profile', data: data);
    return UserProfile.fromJson(res.data);
  }
}
