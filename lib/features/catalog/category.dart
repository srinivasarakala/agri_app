class Category {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int productCount;
  final List<String> productImages;
  final bool is_active;
  final bool isDynamic; // true for tag-based, false for manual categories

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.productCount,
    required this.productImages,
    required this.is_active,
    this.isDynamic = false,
  });

  factory Category.fromJson(Map<String, dynamic> j) => Category(
        id: j['id'] as int,
        name: (j['name'] ?? '').toString(),
        description: j['description']?.toString(),
        imageUrl: j['image_url'] as String?,
        productCount: (j['product_count'] ?? 0) as int,
        productImages: List<String>.from(
          (j['product_images'] as List?)?.whereType<String>() ?? [],
        ),
        is_active: (j['is_active'] ?? true) as bool,
        isDynamic: (j['is_dynamic'] ?? false) as bool,
      );
}
