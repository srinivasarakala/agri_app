double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

class SparePart {
  final int id;
  final String sku;
  final String name;
  final String? description;
  final String? brand;
  final String unit;
  final double mrp;
  final double sellingPrice;
  final double minQty;
  final double globalStock;
  final bool isActive;
  final String? imageUrl;
  final DateTime createdAt;
  final int? categoryId;
  final String? categoryName;
  final String? tags; // Comma-separated tags
  final bool isSparePart; // Flag to identify spare parts

  SparePart({
    required this.id,
    required this.sku,
    required this.name,
    required this.description,
    required this.brand,
    required this.unit,
    required this.mrp,
    required this.sellingPrice,
    required this.minQty,
    required this.globalStock,
    required this.isActive,
    required this.imageUrl,
    required this.createdAt,
    this.categoryId,
    this.categoryName,
    this.tags,
    this.isSparePart = true,
  });

  factory SparePart.fromJson(Map<String, dynamic> j) => SparePart(
        id: j['id'] as int,
        sku: (j['sku'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        description: j['description']?.toString(),
        brand: j['brand_name']?.toString(),
        unit: (j['unit'] ?? 'pcs').toString(),
        mrp: _toDouble(j['mrp']),
        sellingPrice: _toDouble(j['selling_price']),
        minQty: _toDouble(j['min_qty'] ?? 1),
        globalStock: _toDouble(j['global_stock']),
        isActive: (j['is_active'] ?? true) as bool,
        imageUrl: j['image_url'] as String?,
        createdAt: j['created_at'] != null ? DateTime.parse(j['created_at'].toString()) : DateTime.now(),
        categoryId: j['category'] as int?,
        categoryName: j['category_name']?.toString(),
        tags: j['tags']?.toString(),
        isSparePart: j['is_spare_part'] ?? true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sku': sku,
        'name': name,
        'description': description,
        'brand_name': brand,
        'unit': unit,
        'mrp': mrp,
        'selling_price': sellingPrice,
        'min_qty': minQty,
        'global_stock': globalStock,
        'is_active': isActive,
        'image_url': imageUrl,
        'created_at': createdAt.toIso8601String(),
        'category': categoryId,
        'category_name': categoryName,
        'tags': tags,
        'is_spare_part': isSparePart,
      };
}
