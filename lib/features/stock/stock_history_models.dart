class StockHistoryEntry {
  final int id;
  final int productId;
  final String productSku;
  final String productName;
  final String productUnit;
  final String changeType;
  final double quantityChange;
  final double stockBefore;
  final double stockAfter;
  final int? orderId;
  final String? notes;
  final int? createdById;
  final String? createdByName;
  final DateTime createdAt;

  StockHistoryEntry({
    required this.id,
    required this.productId,
    required this.productSku,
    required this.productName,
    required this.productUnit,
    required this.changeType,
    required this.quantityChange,
    required this.stockBefore,
    required this.stockAfter,
    this.orderId,
    this.notes,
    this.createdById,
    this.createdByName,
    required this.createdAt,
  });

  factory StockHistoryEntry.fromJson(Map<String, dynamic> json) {
    return StockHistoryEntry(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      productId: json['product'] is int
          ? json['product']
          : int.parse(json['product'].toString()),
      productSku: json['product_sku'] as String? ?? '',
      productName: json['product_name'] as String? ?? '',
      productUnit: json['product_unit'] as String? ?? '',
      changeType: json['change_type'] as String? ?? '',
      quantityChange: _parseDouble(json['quantity_change']),
      stockBefore: _parseDouble(json['stock_before']),
      stockAfter: _parseDouble(json['stock_after']),
      orderId: json['order_id'] != null
          ? (json['order_id'] is int
                ? json['order_id']
                : int.tryParse(json['order_id'].toString()))
          : null,
      notes: json['notes'] as String?,
      createdById: json['created_by'] != null
          ? (json['created_by'] is int
                ? json['created_by']
                : int.tryParse(json['created_by'].toString()))
          : null,
      createdByName: json['created_by_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String get changeTypeDisplay {
    switch (changeType) {
      case 'MANUAL_ADJUSTMENT':
        return 'Manual Adjustment';
      case 'ORDER_APPROVED':
        return 'Order Approved';
      case 'ORDER_CANCELLED':
        return 'Order Cancelled';
      case 'INITIAL_STOCK':
        return 'Initial Stock';
      default:
        return changeType;
    }
  }

  bool get isIncrease => quantityChange > 0;
  bool get isDecrease => quantityChange < 0;
}
