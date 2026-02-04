import '../../core/api/dio_client.dart';
import 'product.dart';
import 'package:dio/dio.dart';

class CatalogService {
  final DioClient client;
  CatalogService(this.client);

  Future<Product> adminUploadProductImage(int productId, String filePath) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
    });

    final res = await client.dio.post(
      '/api/admin/products/$productId/image',
      data: form,
    );

    return Product.fromJson(res.data);
  }

  Future<List<Product>> listProducts() async {
    final res = await client.dio.get('/api/products');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(Product.fromJson).toList();
  }

  Future<Product> adminCreateProduct(Map<String, dynamic> payload) async {
    final res = await client.dio.post('/api/admin/products', data: payload);
    return Product.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> adminStockAdjust(int productId, double delta) async {
    await client.dio.post('/api/admin/products/$productId/stock-adjust', data: {
      "delta": delta,
      "note": "adjust from app",
    });
  }

  

  

}
