class StockHistoryEntry {
  final int id;
  final int productId;
  final String productSku;
  final String productName;
  final String productUnit;
  final String changeType;
  final int quantityChange;
  final int stockBefore;
  final int stockAfter;
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
      quantityChange: json['quantity_change'] is int
          ? json['quantity_change']
          : int.tryParse(json['quantity_change']?.toString() ?? '') ?? 0,
      stockBefore: json['stock_before'] is int
          ? json['stock_before']
          : int.tryParse(json['stock_before']?.toString() ?? '') ?? 0,
      stockAfter: json['stock_after'] is int
          ? json['stock_after']
          : int.tryParse(json['stock_after']?.toString() ?? '') ?? 0,
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
