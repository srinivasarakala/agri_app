double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  return 0;
}

class OrderItem {
  final int id;
  final int product;
  final String sku;
  final String productName;
  final String unit;
  final double requestedQty;
  final double approvedQty;
  final double soldQty;
  final DateTime? soldAt;
  final double price;

  OrderItem({
    required this.id,
    required this.product,
    required this.sku,
    required this.productName,
    required this.unit,
    required this.requestedQty,
    required this.approvedQty,
    required this.soldQty,
    this.soldAt,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
    id: j['id'],
    product: j['product'],
    sku: (j['sku'] ?? '').toString(),
    productName: (j['product_name'] ?? '').toString(),
    unit: (j['unit'] ?? 'pcs').toString(),
    requestedQty: _toDouble(j['requested_qty']),
    approvedQty: _toDouble(j['approved_qty']),
    soldQty: _toDouble(j['sold_qty'] ?? 0),
    soldAt: j['sold_at'] != null ? DateTime.tryParse(j['sold_at']) : null,
    price: _toDouble(j['price']),
  );
}

class Order {
  final int id;
  final String status;
  final String deliveryStatus;
  final String? note;
  final String phone;
  final List<OrderItem> items;
  final DateTime? decidedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;

  Order({
    required this.id,
    required this.status,
    required this.deliveryStatus,
    required this.note,
    required this.phone,
    required this.items,
    this.decidedAt,
    this.shippedAt,
    this.deliveredAt,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
    id: j['id'],
    status: (j['status'] ?? '').toString(),
    deliveryStatus: (j['delivery_status'] ?? 'NOT_APPLICABLE').toString(),
    note: j['note']?.toString(),
    phone: (j['phone'] ?? '').toString(),
    items: ((j['items'] ?? []) as List)
        .map((x) => OrderItem.fromJson(x as Map<String, dynamic>))
        .toList(),
    decidedAt: j['decided_at'] != null
        ? DateTime.tryParse(j['decided_at'])
        : null,
    shippedAt: j['shipped_at'] != null
        ? DateTime.tryParse(j['shipped_at'])
        : null,
    deliveredAt: j['delivered_at'] != null
        ? DateTime.tryParse(j['delivered_at'])
        : null,
  );
}
