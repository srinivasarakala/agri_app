import '../../core/api/dio_client.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class WhitelistEntry {
  final int id;
  final String phone;
  final String name;
  final String notes;
  final bool isActive;
  final String? createdAt;
  final int? userId;
  final String? lastLogin;

  const WhitelistEntry({
    required this.id,
    required this.phone,
    required this.name,
    required this.notes,
    required this.isActive,
    this.createdAt,
    this.userId,
    this.lastLogin,
  });

  factory WhitelistEntry.fromJson(Map<String, dynamic> j) => WhitelistEntry(
        id: j['id'] as int,
        phone: j['phone'] as String? ?? '',
        name: j['name'] as String? ?? '',
        notes: j['notes'] as String? ?? '',
        isActive: j['is_active'] as bool? ?? false,
        createdAt: j['created_at'] as String?,
        userId: j['user_id'] as int?,
        lastLogin: j['last_login'] as String?,
      );
}

class DealerUser {
  final int userId;
  final String phone;
  final String? name;
  final String? dateJoined;
  final String? lastLogin;
  final int? whitelistId;
  final bool isWhitelisted;
  final bool isActive;

  const DealerUser({
    required this.userId,
    required this.phone,
    this.name,
    this.dateJoined,
    this.lastLogin,
    this.whitelistId,
    required this.isWhitelisted,
    required this.isActive,
  });

  factory DealerUser.fromJson(Map<String, dynamic> j) => DealerUser(
        userId: j['user_id'] as int,
        phone: j['phone'] as String? ?? '',
        name: j['name'] as String?,
        dateJoined: j['date_joined'] as String?,
        lastLogin: j['last_login'] as String?,
        whitelistId: j['whitelist_id'] as int?,
        isWhitelisted: j['is_whitelisted'] as bool? ?? false,
        isActive: j['is_active'] as bool? ?? false,
      );
}

// ─── Service ─────────────────────────────────────────────────────────────────

class DealerWhitelistService {
  final DioClient client;
  const DealerWhitelistService(this.client);

  // GET /api/admin/dealers/whitelist/
  Future<List<WhitelistEntry>> listWhitelist({String? q}) async {
    final resp = await client.dio.get(
      '/api/admin/dealers/whitelist/',
      queryParameters: q != null && q.isNotEmpty ? {'q': q} : null,
    );
    return (resp.data as List).map((e) => WhitelistEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  // POST /api/admin/dealers/whitelist/
  Future<WhitelistEntry> addToWhitelist(String phone, {String name = '', String notes = ''}) async {
    final resp = await client.dio.post(
      '/api/admin/dealers/whitelist/',
      data: {'phone': phone, 'name': name, 'notes': notes},
    );
    return WhitelistEntry.fromJson(resp.data as Map<String, dynamic>);
  }

  // PATCH /api/admin/dealers/whitelist/<id>/ — toggle or set is_active
  Future<WhitelistEntry> toggleWhitelist(int id, {bool? isActive}) async {
    final body = isActive != null ? {'is_active': isActive} : <String, dynamic>{};
    final resp = await client.dio.patch(
      '/api/admin/dealers/whitelist/$id/',
      data: body,
    );
    return WhitelistEntry.fromJson(resp.data as Map<String, dynamic>);
  }

  // DELETE /api/admin/dealers/whitelist/<id>/
  Future<void> removeFromWhitelist(int id) async {
    await client.dio.delete('/api/admin/dealers/whitelist/$id/');
  }

  // GET /api/admin/dealers/
  Future<List<DealerUser>> listDealers({String? q}) async {
    final resp = await client.dio.get(
      '/api/admin/dealers/',
      queryParameters: q != null && q.isNotEmpty ? {'q': q} : null,
    );
    return (resp.data as List).map((e) => DealerUser.fromJson(e as Map<String, dynamic>)).toList();
  }
}
