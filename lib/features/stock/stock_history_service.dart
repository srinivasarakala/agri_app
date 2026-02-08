import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import 'stock_history_models.dart';

class StockHistoryService {
  final DioClient _dio;

  StockHistoryService(this._dio);

  Future<List<StockHistoryEntry>> getStockHistory({
    int? productId,
    String? changeType,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (productId != null) queryParams['product_id'] = productId.toString();
      if (changeType != null) queryParams['change_type'] = changeType;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _dio.dio.get(
        '/api/admin/stock-history',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );

      final List<dynamic> data = response.data as List;
      return data.map((json) => StockHistoryEntry.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to load stock history: ${e.message}');
    }
  }

  Future<List<StockHistoryEntry>> getProductStockHistory(int productId) async {
    return getStockHistory(productId: productId);
  }
}
