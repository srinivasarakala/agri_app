import '../../core/api/dio_client.dart';
import 'order_models.dart';

class OrdersService {
  final DioClient client;
  OrdersService(this.client);

  Future<List<Order>> myOrders() async {
    final res = await client.dio.get('/api/orders');
    return (res.data as List).map((x) => Order.fromJson(x)).toList().cast<Order>();
  }

  Future<Order> createOrder({
    String? note,
    required List<Map<String, dynamic>> items, // [{product_id, qty}]
  }) async {
    final res = await client.dio.post('/api/orders/create', data: {
      "note": note ?? "",
      "items": items,
    });
    return Order.fromJson(res.data);
  }

  Future<List<Order>> adminOrders() async {
    final res = await client.dio.get('/api/admin/orders');
    return (res.data as List).map((x) => Order.fromJson(x)).toList().cast<Order>();
  }

  Future<Order> adminApprove(int orderId, List<Map<String, dynamic>> items, {String? note}) async {
    final res = await client.dio.post('/api/admin/orders/$orderId/approve', data: {
      "note": note ?? "",
      "items": items, // [{item_id, approved_qty}]
    });
    return Order.fromJson(res.data);
  }

  Future<Order> adminReject(int orderId) async {
    final res = await client.dio.post('/api/admin/orders/$orderId/reject');
    return Order.fromJson(res.data);
  }
}
