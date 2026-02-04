double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

class Product {
  final int id;
  final String sku;
  final String name;
  final String? brand;
  final String unit;
  final double mrp;
  final double sellingPrice;
  final double globalStock;
  final bool isActive;
  final String? imageUrl;
  

  Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.brand,
    required this.unit,
    required this.mrp,
    required this.sellingPrice,
    required this.globalStock,
    required this.isActive,
    required this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as int,
        sku: (j['sku'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
        brand: j['brand']?.toString(),
        unit: (j['unit'] ?? 'pcs').toString(),
        mrp: _toDouble(j['mrp']),
        sellingPrice: _toDouble(j['selling_price']),
        globalStock: _toDouble(j['global_stock']),
        isActive: (j['is_active'] ?? true) as bool,
        imageUrl: j['image_url'] as String?,

      );
}
