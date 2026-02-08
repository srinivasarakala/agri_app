import '../api/dio_client.dart';

class CartService {
  final DioClient client;
  CartService(this.client);

  /// Sync local cart to backend
  Future<void> syncCart(Map<int, int> cartItems) async {
    final items = cartItems.entries
        .map((e) => {'product_id': e.key, 'quantity': e.value})
        .toList();
    
    await client.dio.post('/api/cart', data: items);
  }

  /// Load cart from backend
  Future<Map<int, int>> loadCart() async {
    final res = await client.dio.get('/api/cart');
    final items = res.data['items'] as List;
    
    final Map<int, int> cart = {};
    for (var item in items) {
      cart[item['product'] as int] = item['quantity'] as int;
    }
    
    return cart;
  }

  /// Update a single cart item
  Future<void> updateCartItem(int productId, int quantity) async {
    await client.dio.put('/api/cart/item/$productId', data: {'quantity': quantity});
  }

  /// Remove item from cart
  Future<void> removeCartItem(int productId) async {
    await client.dio.delete('/api/cart/item/$productId');
  }
}
