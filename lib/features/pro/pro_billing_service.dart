import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

const syncFocusProProductId = 'syncfocus_pro';
const syncFocusProBasePlanId = '01-syncfocus-pro';
const syncFocusProYearlyBasePlanId = '02-syncfocus-pro-yearly';
const syncFocusProLifetimeProductId = 'syncfocus_pro_lifetime';

enum ProPurchasePlan { yearly, lifetime }

enum ProPurchaseUpdateStatus { purchased, restored, pending, canceled, error }

class ProPurchaseUpdate {
  const ProPurchaseUpdate({
    required this.productId,
    required this.status,
    this.errorMessage,
    this.rawPurchase,
  });

  final String productId;
  final ProPurchaseUpdateStatus status;
  final String? errorMessage;
  final PurchaseDetails? rawPurchase;

  bool get pendingCompletePurchase =>
      rawPurchase?.pendingCompletePurchase ?? false;
}

class ProOwnershipSnapshot {
  const ProOwnershipSnapshot({
    required this.isActive,
    this.isPending = false,
    this.errorMessage,
    this.purchasesToComplete = const [],
  });

  final bool isActive;
  final bool isPending;
  final String? errorMessage;
  final List<ProPurchaseUpdate> purchasesToComplete;

  bool get isAuthoritative => errorMessage == null;
}

enum ProPricingRecurrence { finite, infinite, oneTime }

class ProPricingPhase {
  const ProPricingPhase({
    required this.formattedPrice,
    required this.billingPeriod,
    required this.recurrence,
    required this.billingCycleCount,
    required this.isFree,
  });

  final String formattedPrice;
  final String billingPeriod;
  final ProPricingRecurrence recurrence;
  final int billingCycleCount;
  final bool isFree;

  String get interval => readableBillingPeriod(billingPeriod);
}

class ProPurchaseOption {
  const ProPurchaseOption({
    required this.plan,
    required this.product,
    required this.localizedPrice,
    required this.pricingDisclosure,
    this.offerToken,
  });

  final ProPurchasePlan plan;
  final ProductDetails product;
  final String localizedPrice;
  final String pricingDisclosure;
  final String? offerToken;

  PurchaseParam get purchaseParam => GooglePlayPurchaseParam(
    productDetails: product,
    offerToken: plan == ProPurchasePlan.yearly ? offerToken : null,
  );
}

abstract interface class ProBillingService {
  Stream<List<ProPurchaseUpdate>> get purchaseUpdates;

  Future<bool> isAvailable();

  Future<List<ProPurchaseOption>> loadOptions();

  Future<void> buy(ProPurchaseOption option);

  Future<ProOwnershipSnapshot> queryOwnership();

  Future<void> completePurchase(ProPurchaseUpdate update);
}

/// Returns only the matching base-plan index. Unrelated plans are not fallbacks.
int? selectSubscriptionOfferIndex(
  List<String> basePlanIds,
  String requestedBasePlanId,
) {
  if (basePlanIds.isEmpty) return null;
  final matchingIndex = basePlanIds.indexOf(requestedBasePlanId);
  return matchingIndex < 0 ? null : matchingIndex;
}

List<ProPurchaseOption> proPurchaseOptionsFromProducts(
  List<ProductDetails> products,
) {
  final options = <ProPurchaseOption>[];
  final subscriptionProducts = products
      .whereType<GooglePlayProductDetails>()
      .where((product) => product.id == syncFocusProProductId)
      .toList(growable: false);
  final yearlyIndex = selectSubscriptionOfferIndex(
    subscriptionProducts.map(_basePlanIdFor).toList(growable: false),
    syncFocusProYearlyBasePlanId,
  );

  if (yearlyIndex != null) {
    final yearlyProduct = subscriptionProducts[yearlyIndex];
    final offerIndex = yearlyProduct.subscriptionIndex;
    final offers = yearlyProduct.productDetails.subscriptionOfferDetails;
    if (offerIndex != null && offers != null && offerIndex < offers.length) {
      final offer = offers[offerIndex];
      final phases = offer.pricingPhases
          .map(
            (phase) => ProPricingPhase(
              formattedPrice: phase.formattedPrice,
              billingPeriod: phase.billingPeriod,
              recurrence: switch (phase.recurrenceMode) {
                RecurrenceMode.finiteRecurring => ProPricingRecurrence.finite,
                RecurrenceMode.infiniteRecurring =>
                  ProPricingRecurrence.infinite,
                RecurrenceMode.nonRecurring => ProPricingRecurrence.oneTime,
              },
              billingCycleCount: phase.billingCycleCount,
              isFree: phase.priceAmountMicros == 0,
            ),
          )
          .toList(growable: false);
      if (phases.isNotEmpty) {
        final recurring = phases.lastWhere(
          (phase) => phase.recurrence == ProPricingRecurrence.infinite,
          orElse: () => phases.last,
        );
        options.add(
          ProPurchaseOption(
            plan: ProPurchasePlan.yearly,
            product: yearlyProduct,
            offerToken: offer.offerIdToken,
            localizedPrice: recurring.formattedPrice,
            pricingDisclosure: pricingDisclosureFor(phases),
          ),
        );
      }
    }
  }

  ProductDetails? lifetimeProduct;
  for (final product in products) {
    if (product.id == syncFocusProLifetimeProductId) {
      lifetimeProduct = product;
      break;
    }
  }
  if (lifetimeProduct != null) {
    options.add(
      ProPurchaseOption(
        plan: ProPurchasePlan.lifetime,
        product: lifetimeProduct,
        localizedPrice: lifetimeProduct.price,
        pricingDisclosure: 'One-time purchase. Does not renew.',
      ),
    );
  }
  return options;
}

ProOwnershipSnapshot proOwnershipFromPurchases(
  Iterable<PurchaseDetails> purchases,
) {
  final proPurchases = purchases
      .where((purchase) => isSyncFocusProProductId(purchase.productID))
      .toList(growable: false);
  return ProOwnershipSnapshot(
    isActive: proPurchases.any(
      (purchase) =>
          purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored,
    ),
    isPending: proPurchases.any(
      (purchase) => purchase.status == PurchaseStatus.pending,
    ),
    purchasesToComplete: proPurchases
        .where(
          (purchase) =>
              purchase.pendingCompletePurchase &&
              (purchase.status == PurchaseStatus.purchased ||
                  purchase.status == PurchaseStatus.restored),
        )
        .map(_purchaseUpdateFrom)
        .toList(growable: false),
  );
}

ProPurchaseUpdate _purchaseUpdateFrom(PurchaseDetails purchase) =>
    ProPurchaseUpdate(
      productId: purchase.productID,
      status: switch (purchase.status) {
        PurchaseStatus.purchased => ProPurchaseUpdateStatus.purchased,
        PurchaseStatus.restored => ProPurchaseUpdateStatus.restored,
        PurchaseStatus.pending => ProPurchaseUpdateStatus.pending,
        PurchaseStatus.canceled => ProPurchaseUpdateStatus.canceled,
        PurchaseStatus.error => ProPurchaseUpdateStatus.error,
      },
      errorMessage: purchase.error?.message,
      rawPurchase: purchase,
    );

bool isSyncFocusProProductId(String productId) =>
    productId == syncFocusProProductId ||
    productId == syncFocusProLifetimeProductId;

String _basePlanIdFor(GooglePlayProductDetails product) {
  final index = product.subscriptionIndex;
  final offers = product.productDetails.subscriptionOfferDetails;
  if (index == null || offers == null || index >= offers.length) return '';
  return offers[index].basePlanId;
}

String readableBillingPeriod(String billingPeriod) {
  final match = RegExp(r'^P(\d+)([DWMY])$').firstMatch(billingPeriod);
  if (match == null) return 'billing period';
  final count = int.tryParse(match.group(1)!) ?? 1;
  final unit = switch (match.group(2)) {
    'D' => 'day',
    'W' => 'week',
    'M' => 'month',
    'Y' => 'year',
    _ => 'billing period',
  };
  return count == 1 ? unit : '$count ${unit}s';
}

String pricingDisclosureFor(List<ProPricingPhase> phases) {
  if (phases.isEmpty) {
    return 'Monthly subscription. Renews automatically. Cancel anytime in Google Play.';
  }

  final recurringIndex = phases.lastIndexWhere(
    (phase) => phase.recurrence == ProPricingRecurrence.infinite,
  );
  final recurring = recurringIndex >= 0 ? phases[recurringIndex] : phases.last;
  final introductory = phases
      .take(recurringIndex < 0 ? phases.length - 1 : recurringIndex)
      .map(_introductoryPhaseDescription)
      .toList();
  final recurringDescription = recurring.isFree
      ? 'free per ${recurring.interval}'
      : '${recurring.formattedPrice} per ${recurring.interval}';
  final pricing = introductory.isEmpty
      ? recurringDescription
      : '${introductory.join(', ')}, then $recurringDescription';
  return '$pricing. Renews automatically. Cancel anytime in Google Play.';
}

String _introductoryPhaseDescription(ProPricingPhase phase) {
  if (phase.isFree) return 'Free for ${phase.interval}';
  if (phase.recurrence == ProPricingRecurrence.oneTime) {
    return '${phase.formattedPrice} once';
  }
  final cycleCount = phase.billingCycleCount;
  if (cycleCount <= 0) return '${phase.formattedPrice} per ${phase.interval}';
  final cycleWord = cycleCount == 1 ? 'cycle' : 'cycles';
  return '${phase.formattedPrice} per ${phase.interval} for $cycleCount $cycleWord';
}

class InAppPurchaseProBillingService implements ProBillingService {
  InAppPurchaseProBillingService({InAppPurchase? billing})
    : _billing = billing ?? InAppPurchase.instance;

  final InAppPurchase _billing;

  @override
  Stream<List<ProPurchaseUpdate>> get purchaseUpdates => _billing.purchaseStream
      .map((purchases) => purchases.map(_mapPurchase).toList(growable: false));

  @override
  Future<bool> isAvailable() async {
    if (defaultTargetPlatform != TargetPlatform.android) return false;
    return _billing.isAvailable();
  }

  @override
  Future<List<ProPurchaseOption>> loadOptions() async {
    final response = await _billing.queryProductDetails(const {
      syncFocusProProductId,
      syncFocusProLifetimeProductId,
    });
    return proPurchaseOptionsFromProducts(response.productDetails);
  }

  @override
  Future<void> buy(ProPurchaseOption option) async {
    final launched = await _billing.buyNonConsumable(
      purchaseParam: option.purchaseParam,
    );
    if (!launched) throw StateError('Google Play did not start the purchase.');
  }

  @override
  Future<ProOwnershipSnapshot> queryOwnership() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const ProOwnershipSnapshot(
        isActive: false,
        errorMessage: 'Google Play subscriptions are available on Android.',
      );
    }
    try {
      final response = await _billing
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>()
          .queryPastPurchases();
      if (response.error != null) {
        return ProOwnershipSnapshot(
          isActive: false,
          errorMessage: response.error!.message,
        );
      }
      return proOwnershipFromPurchases(response.pastPurchases);
    } on Exception catch (error) {
      return ProOwnershipSnapshot(
        isActive: false,
        errorMessage: error.toString(),
      );
    }
  }

  @override
  Future<void> completePurchase(ProPurchaseUpdate update) async {
    final purchase = update.rawPurchase;
    if (purchase == null || !purchase.pendingCompletePurchase) return;
    await _billing.completePurchase(purchase);
  }

  ProPurchaseUpdate _mapPurchase(PurchaseDetails purchase) {
    return _purchaseUpdateFrom(purchase);
  }
}
