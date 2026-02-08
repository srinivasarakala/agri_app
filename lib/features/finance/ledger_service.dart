import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import 'ledger_models.dart';

class LedgerService {
  final DioClient _dio;

  LedgerService(this._dio);

  /// Get ledger transactions
  /// Admin: can pass userId to filter by user, or null to get all
  /// Subdealer: always gets their own transactions
  Future<List<LedgerTransaction>> getLedgerTransactions({int? userId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) {
        queryParams['user_id'] = userId.toString();
      }

      final response = await _dio.dio.get(
        '/api/finance/ledger/',
        queryParameters: queryParams,
      );

      final List<dynamic> data = response.data as List;
      return data.map((json) => LedgerTransaction.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load ledger transactions: ${e.message}');
    }
  }

  /// Get balance for a user
  /// Admin: must provide userId
  /// Subdealer: gets their own balance (userId ignored)
  Future<UserBalance> getUserBalance({int? userId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (userId != null) {
        queryParams['user_id'] = userId.toString();
      }

      final response = await _dio.dio.get(
        '/api/finance/balance/',
        queryParameters: queryParams,
      );

      return UserBalance.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to load user balance: ${e.message}');
    }
  }

  /// Get all user balances (Admin only)
  Future<List<UserBalance>> getAllBalances() async {
    try {
      final response = await _dio.dio.get('/api/finance/balances/');

      final List<dynamic> data = response.data as List;
      return data.map((json) => UserBalance.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load all balances: ${e.message}');
    }
  }

  /// Record a payment (Admin only)
  Future<LedgerTransaction> recordPayment(RecordPaymentRequest request) async {
    try {
      final response = await _dio.dio.post(
        '/api/finance/record-payment/',
        data: request.toJson(),
      );

      return LedgerTransaction.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to record payment: ${e.message}');
    }
  }
}
