import '../../core/api/dio_client.dart';
import 'product.dart';
import 'category.dart';
import 'product_video.dart';
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

  Future<List<Category>> listCategories() async {
    try {
      final res = await client.dio.get('/api/categories');
      final list = (res.data as List).cast<Map<String, dynamic>>();
      return list.map(Category.fromJson).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Category>> listDynamicCategories() async {
    try {
      final res = await client.dio.get('/api/categories/dynamic');
      final list = (res.data as List).cast<Map<String, dynamic>>();
      return list.map(Category.fromJson).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Category> adminCreateCategory(Map<String, dynamic> payload) async {
    final res = await client.dio.post('/api/admin/categories', data: payload);
    return Category.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Category> adminUpdateCategory(int categoryId, Map<String, dynamic> payload) async {
    final res = await client.dio.put('/api/admin/categories/$categoryId', data: payload);
    return Category.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> adminDeleteCategory(int categoryId) async {
    await client.dio.delete('/api/admin/categories/$categoryId');
  }

  Future<Product> adminCreateProduct(Map<String, dynamic> payload) async {
    final res = await client.dio.post('/api/admin/products', data: payload);
    return Product.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Product> adminUpdateProduct(int productId, Map<String, dynamic> payload) async {
    final res = await client.dio.put('/api/admin/products/$productId', data: payload);
    return Product.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> adminDeleteProduct(int productId) async {
    await client.dio.delete('/api/admin/products/$productId');
  }

  Future<void> adminStockAdjust(int productId, double delta) async {
    await client.dio.post('/api/admin/products/$productId/stock-adjust', data: {
      "delta": delta,
      "note": "adjust from app",
    });
  }

  // Favorites API
  Future<List<int>> getFavorites() async {
    try {
      final res = await client.dio.get('/favorites');
      final data = res.data as Map<String, dynamic>;
      final ids = (data['favorite_product_ids'] as List?)?.cast<int>() ?? [];
      return ids;
    } catch (e) {
      return [];
    }
  }

  Future<bool> toggleFavorite(int productId) async {
    try {
      final res = await client.dio.post('/favorites/$productId/toggle');
      final data = res.data as Map<String, dynamic>;
      return (data['is_favorite'] as bool?) ?? false;
    } catch (e) {
      throw Exception("Failed to toggle favorite: $e");
    }
  }

  // Product Videos API
  Future<List<ProductVideo>> listProductVideos() async {
    final res = await client.dio.get('/api/product-videos');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(ProductVideo.fromJson).toList();
  }

  Future<ProductVideo> adminCreateProductVideo(Map<String, dynamic> payload) async {
    final res = await client.dio.post('/api/admin/product-videos', data: payload);
    return ProductVideo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ProductVideo> adminUpdateProductVideo(int videoId, Map<String, dynamic> payload) async {
    final res = await client.dio.put('/api/admin/product-videos/$videoId', data: payload);
    return ProductVideo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> adminDeleteProductVideo(int videoId) async {
    await client.dio.delete('/api/admin/product-videos/$videoId');
  }
}
