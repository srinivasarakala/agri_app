// Create a Flutter service class called AnalyticsService.
// Requirements:
// - Use FirebaseAnalytics instance
// - Create methods:
//     logLogin()
//     logProductView(productId, productName)
//     logAddToCart(productId)
//     logOrderPlaced(orderId, amount)
// - Each method should call logEvent with proper parameters
// - Should be reusable across app
// - Only log events in release mode
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  final FirebaseAnalytics? _analytics;

  AnalyticsService(this._analytics);

  void logLogin({String method = 'unknown'}) {
    if (kReleaseMode && _analytics != null) {
      _analytics!.logLogin(loginMethod: method);
    }
  }

  void logProductView(String productId, String productName) {
    if (kReleaseMode && _analytics != null) {
      _analytics!.logEvent(
        name: 'view_product',
        parameters: {
          'product_id': productId,
          'product_name': productName,
        },
      );
    }
  }

  void logAddToCart(String productId) {
    if (kReleaseMode && _analytics != null) {
      _analytics!.logEvent(
        name: 'add_to_cart',
        parameters: {'product_id': productId},
      );
    }
  }

  void logOrderPlaced(String orderId, double amount) {
    if (kReleaseMode && _analytics != null) {
      _analytics!.logEvent(
        name: 'order_placed',
        parameters: {
          'order_id': orderId,
          'amount': amount,
        },
      );
    }
  }
}
