import 'package:firebase_analytics/firebase_analytics.dart';

typedef PurchaseRevenueLogger = Future<void> Function(
  AppAnalyticsPurchaseEvent event,
);

class AppAnalyticsPurchaseEvent {
  const AppAnalyticsPurchaseEvent({
    required this.productId,
    required this.productName,
    required this.value,
    required this.currency,
    required this.quantity,
    this.transactionId,
  });

  final String productId;
  final String productName;
  final double value;
  final String currency;
  final int quantity;
  final String? transactionId;
}

class AppAnalytics {
  const AppAnalytics._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logPurchaseRevenue(
    AppAnalyticsPurchaseEvent event, {
    PurchaseRevenueLogger logPurchase = _logPurchase,
  }) async {
    if (!event.value.isFinite || event.value <= 0 || event.currency.isEmpty) {
      return;
    }

    await logPurchase(event);
  }

  static Future<void> _logPurchase(AppAnalyticsPurchaseEvent event) async {
    await _analytics.logPurchase(
      currency: event.currency,
      value: event.value,
      transactionId: event.transactionId,
      items: [
        AnalyticsEventItem(
          itemId: event.productId,
          itemName: event.productName,
          quantity: event.quantity,
          price: event.value,
        ),
      ],
    );
  }
}
