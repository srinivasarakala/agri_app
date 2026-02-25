class Brand {
  final int id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int productCount;
  final bool is_active;

  Brand({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.productCount,
    required this.is_active,
  });

  factory Brand.fromJson(Map<String, dynamic> j) => Brand(
        id: j['id'] as int,
        name: (j['name'] ?? '').toString(),
        description: j['description']?.toString(),
        imageUrl: j['image_url'] as String?,
        productCount: (j['product_count'] ?? 0) as int,
        is_active: (j['is_active'] ?? true) as bool,
      );
}
