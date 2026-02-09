class LedgerTransaction {
  final int id;
  final int userId;
  final UserInfo? userInfo;
  final int? orderId;
  final String? orderNumber;
  final String transactionType;
  final double amount;
  final double balance;
  final String description;
  final String referenceNumber;
  final DateTime createdAt;
  final int? createdBy;
  final UserInfo? createdByInfo;

  LedgerTransaction({
    required this.id,
    required this.userId,
    this.userInfo,
    this.orderId,
    this.orderNumber,
    required this.transactionType,
    required this.amount,
    required this.balance,
    required this.description,
    required this.referenceNumber,
    required this.createdAt,
    this.createdBy,
    this.createdByInfo,
  });

  factory LedgerTransaction.fromJson(Map<String, dynamic> json) {
    return LedgerTransaction(
      id: json['id'] as int,
      userId: json['user'] as int,
      userInfo: json['user_info'] != null
          ? UserInfo.fromJson(json['user_info'])
          : null,
      orderId: json['order'] as int?,
      orderNumber: json['order_number'] as String?,
      transactionType: json['transaction_type'] as String? ?? 'UNKNOWN',
      amount: double.parse(json['amount'].toString()),
      balance: double.parse(json['balance'].toString()),
      description: json['description'] as String? ?? '',
      referenceNumber: json['reference_number'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at']),
      createdBy: json['created_by'] as int?,
      createdByInfo: json['created_by_info'] != null
          ? UserInfo.fromJson(json['created_by_info'])
          : null,
    );
  }

  String get transactionTypeDisplay {
    switch (transactionType) {
      case 'ORDER_DELIVERED':
        return 'Order Delivered';
      case 'PAYMENT_RECEIVED':
        return 'Payment Received';
      case 'ADJUSTMENT':
        return 'Adjustment';
      default:
        return transactionType;
    }
  }

  bool get isDebit => amount > 0;
  bool get isCredit => amount < 0;
}

class UserInfo {
  final int id;
  final String username;
  final String phone;
  final String firstName;
  final String lastName;
  final String fullName;

  UserInfo({
    required this.id,
    required this.username,
    required this.phone,
    required this.firstName,
    required this.lastName,
    required this.fullName,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Unknown',
    );
  }
}

class UserBalance {
  final int userId;
  final String username;
  final String phone;
  final String fullName;
  final double balance;
  final DateTime? lastTransactionDate;
  final double totalDeliveredValue;
  final double totalSoldValue;
  final double pendingItemsValue;

  UserBalance({
    required this.userId,
    required this.username,
    required this.phone,
    required this.fullName,
    required this.balance,
    this.lastTransactionDate,
    this.totalDeliveredValue = 0,
    this.totalSoldValue = 0,
    this.pendingItemsValue = 0,
  });

  factory UserBalance.fromJson(Map<String, dynamic> json) {
    return UserBalance(
      userId: json['user_id'] as int,
      username: json['username'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Unknown',
      balance: double.parse(json['balance'].toString()),
      lastTransactionDate: json['last_transaction_date'] != null
          ? DateTime.parse(json['last_transaction_date'])
          : null,
      totalDeliveredValue: double.parse((json['total_delivered_value'] ?? 0).toString()),
      totalSoldValue: double.parse((json['total_sold_value'] ?? 0).toString()),
      pendingItemsValue: double.parse((json['pending_items_value'] ?? 0).toString()),
    );
  }
}

class RecordPaymentRequest {
  final int userId;
  final double amount;
  final String referenceNumber;
  final String description;

  RecordPaymentRequest({
    required this.userId,
    required this.amount,
    required this.referenceNumber,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'amount': amount,
      'reference_number': referenceNumber,
      'description': description,
    };
  }
}
