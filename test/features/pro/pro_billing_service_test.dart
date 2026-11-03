import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfocus/features/pro/pro_billing_service.dart';

void main() {
  group('selectSubscriptionOfferIndex', () {
    test('selects the configured base plan when it is available', () {
      expect(
        selectSubscriptionOfferIndex([
          'legacy-plan',
          syncFocusProBasePlanId,
          'other-plan',
        ], syncFocusProBasePlanId),
        1,
      );
    });

    test(
      'does not select an unrelated plan when the requested plan is absent',
      () {
        expect(
          selectSubscriptionOfferIndex([
            'legacy-plan',
            'other-plan',
          ], syncFocusProBasePlanId),
          isNull,
        );
      },
    );

    test('returns null when Play returns no offers', () {
      expect(selectSubscriptionOfferIndex([], syncFocusProBasePlanId), isNull);
    });

    test('does not fall back to Monthly when the Yearly plan is missing', () {
      expect(
        selectSubscriptionOfferIndex([
          syncFocusProBasePlanId,
        ], '02-syncfocus-pro-yearly'),
        isNull,
      );
    });
  });

  test('offers localized Yearly and Lifetime prices with accurate terms', () {
    final options = proPurchaseOptionsFromProducts(_playProducts());

    expect(options.map((option) => option.plan), [
      ProPurchasePlan.yearly,
      ProPurchasePlan.lifetime,
    ]);
    expect(options[0].localizedPrice, r'$29.99');
    expect(
      options[0].pricingDisclosure,
      r'$29.99 per year. Renews automatically. Cancel anytime in Google Play.',
    );
    expect(options[1].localizedPrice, r'$89.99');
    expect(options[1].pricingDisclosure, 'One-time purchase. Does not renew.');
  });

  test('purchase parameters use the Yearly token and no Lifetime token', () {
    final options = proPurchaseOptionsFromProducts(_playProducts());
    final yearly = options.firstWhere(
      (option) => option.plan == ProPurchasePlan.yearly,
    );
    final lifetime = options.firstWhere(
      (option) => option.plan == ProPurchasePlan.lifetime,
    );

    expect(yearly.purchaseParam, isA<GooglePlayPurchaseParam>());
    expect(
      (yearly.purchaseParam as GooglePlayPurchaseParam).offerToken,
      'yearly-offer-token',
    );
    expect(lifetime.purchaseParam, isA<GooglePlayPurchaseParam>());
    expect(
      (lifetime.purchaseParam as GooglePlayPurchaseParam).offerToken,
      isNull,
    );
  });

  test(
    'restores Pro from the existing Monthly product and Lifetime product',
    () {
      for (final productId in [
        syncFocusProProductId,
        'syncfocus_pro_lifetime',
      ]) {
        expect(
          proOwnershipFromPurchases([_purchase(productId)]).isActive,
          isTrue,
          reason: '$productId must keep or grant Pro access',
        );
      }
    },
  );

  test(
    'queues confirmed unacknowledged Sync Focus purchases for completion',
    () {
      final snapshot = proOwnershipFromPurchases([
        _purchase(
          syncFocusProLifetimeProductId,
          status: PurchaseStatus.restored,
          pendingCompletePurchase: true,
        ),
        _purchase(syncFocusProProductId, status: PurchaseStatus.purchased),
        _purchase(
          'unrelated_product',
          status: PurchaseStatus.purchased,
          pendingCompletePurchase: true,
        ),
        _purchase(
          syncFocusProLifetimeProductId,
          status: PurchaseStatus.pending,
          pendingCompletePurchase: true,
        ),
      ]);

      List<ProPurchaseUpdate> readCompletionQueue() =>
          (snapshot as dynamic).purchasesToComplete as List<ProPurchaseUpdate>;
      expect(
        readCompletionQueue,
        returnsNormally,
        reason: 'Ownership snapshots must preserve purchases needing ack.',
      );
      final purchasesToComplete = readCompletionQueue();
      expect(purchasesToComplete.map((purchase) => purchase.productId), [
        syncFocusProLifetimeProductId,
      ]);
      expect(purchasesToComplete.single.pendingCompletePurchase, isTrue);
    },
  );
}

List<ProductDetails> _playProducts() {
  final subscription = ProductDetailsWrapper(
    description: 'Focus tools',
    name: 'Sync Focus Pro',
    productId: syncFocusProProductId,
    productType: ProductType.subs,
    title: 'Sync Focus Pro',
    subscriptionOfferDetails: [
      _subscriptionOffer(
        basePlanId: syncFocusProBasePlanId,
        offerToken: 'monthly-offer-token',
        phase: _phase(price: r'$4.99', period: 'P1M'),
      ),
      _subscriptionOffer(
        basePlanId: '02-syncfocus-pro-yearly',
        offerToken: 'yearly-offer-token',
        phase: _phase(price: r'$29.99', period: 'P1Y'),
      ),
    ],
  );
  final lifetime = ProductDetailsWrapper(
    description: 'One-time Sync Focus Pro access',
    name: 'Sync Focus Pro Lifetime',
    oneTimePurchaseOfferDetails: const OneTimePurchaseOfferDetailsWrapper(
      formattedPrice: r'$89.99',
      priceAmountMicros: 89990000,
      priceCurrencyCode: 'USD',
    ),
    productId: 'syncfocus_pro_lifetime',
    productType: ProductType.inapp,
    title: 'Sync Focus Pro Lifetime',
  );
  return [
    ...GooglePlayProductDetails.fromProductDetails(subscription),
    ...GooglePlayProductDetails.fromProductDetails(lifetime),
  ];
}

SubscriptionOfferDetailsWrapper _subscriptionOffer({
  required String basePlanId,
  required String offerToken,
  required PricingPhaseWrapper phase,
}) => SubscriptionOfferDetailsWrapper(
  basePlanId: basePlanId,
  offerTags: const [],
  offerIdToken: offerToken,
  pricingPhases: [phase],
);

PricingPhaseWrapper _phase({required String price, required String period}) =>
    PricingPhaseWrapper(
      billingCycleCount: 0,
      billingPeriod: period,
      formattedPrice: price,
      priceAmountMicros: price == r'$29.99' ? 29990000 : 4990000,
      priceCurrencyCode: 'USD',
      recurrenceMode: RecurrenceMode.infiniteRecurring,
    );

PurchaseDetails _purchase(
  String productId, {
  PurchaseStatus status = PurchaseStatus.restored,
  bool pendingCompletePurchase = false,
}) => PurchaseDetails(
  productID: productId,
  verificationData: PurchaseVerificationData(
    localVerificationData: 'local',
    serverVerificationData: 'server',
    source: 'Google Play',
  ),
  transactionDate: '2026-11-03',
  status: status,
)..pendingCompletePurchase = pendingCompletePurchase;
