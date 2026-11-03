import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:syncfocus/features/pro/pro_billing_controller.dart';
import 'package:syncfocus/features/pro/pro_billing_service.dart';

const _testProOverrideEnabled =
    kDebugMode && bool.fromEnvironment('SYNC_FOCUS_PRO', defaultValue: false);

void main() {
  group('ProBillingController', () {
    test('selects Yearly by default when both plans are available', () async {
      final yearly = _yearlyOption();
      final lifetime = _lifetimeOption();
      final controller = ProBillingController(
        service: _FakeBillingService(options: [yearly, lifetime]),
        store: _FakeEntitlementStore(),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.selectedPlan, ProPurchasePlan.yearly);
      expect(controller.selectedOption, same(yearly));
    });

    test('selects Lifetime when Yearly is unavailable', () async {
      final lifetime = _lifetimeOption();
      final controller = ProBillingController(
        service: _FakeBillingService(options: [lifetime]),
        store: _FakeEntitlementStore(),
      );
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.selectedPlan, ProPurchasePlan.lifetime);
      expect(controller.selectedOption, same(lifetime));
    });

    test('ignores selection of an unavailable plan', () async {
      final yearly = _yearlyOption();
      final controller = ProBillingController(
        service: _FakeBillingService(options: [yearly]),
        store: _FakeEntitlementStore(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      controller.selectPlan(ProPurchasePlan.lifetime);

      expect(controller.selectedPlan, ProPurchasePlan.yearly);
      expect(controller.selectedOption, same(yearly));
    });

    test('dispatches purchase for the selected plan', () async {
      final lifetime = _lifetimeOption();
      final service = _FakeBillingService(options: [_yearlyOption(), lifetime]);
      final controller = ProBillingController(
        service: service,
        store: _FakeEntitlementStore(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      controller.selectPlan(ProPurchasePlan.lifetime);
      await controller.buy();

      expect(service.purchasedOption, same(lifetime));
    }, skip: _testProOverrideEnabled);

    test('a Play cancellation without a product ID ends the spinner', () async {
      final service = _FakeBillingService();
      final controller = ProBillingController(
        service: service,
        store: _FakeEntitlementStore(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.buy();
      service.emit(
        const ProPurchaseUpdate(
          productId: '',
          status: ProPurchaseUpdateStatus.canceled,
        ),
      );
      await _flushPurchaseStream();

      expect(controller.status, ProBillingStatus.ready);
      expect(controller.isBusy, isFalse);
      expect(controller.canPurchase, isTrue);
    }, skip: _testProOverrideEnabled);

    test('a productless successful callback never grants Pro', () async {
      final service = _FakeBillingService();
      final store = _FakeEntitlementStore();
      final controller = ProBillingController(service: service, store: store);
      addTearDown(controller.dispose);

      await controller.load();
      await controller.buy();
      service.emit(
        const ProPurchaseUpdate(
          productId: '',
          status: ProPurchaseUpdateStatus.purchased,
        ),
      );
      await _flushPurchaseStream();

      expect(controller.isPro, isFalse);
      expect(store.active, isFalse);
      expect(controller.status, ProBillingStatus.error);
      expect(controller.canPurchase, isTrue);
    }, skip: _testProOverrideEnabled);

    test('a productless Play error leaves an actionable retry', () async {
      final service = _FakeBillingService();
      final controller = ProBillingController(
        service: service,
        store: _FakeEntitlementStore(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.buy();
      service.emit(
        const ProPurchaseUpdate(
          productId: '',
          status: ProPurchaseUpdateStatus.error,
          errorMessage: 'Play failed to complete the purchase.',
        ),
      );
      await _flushPurchaseStream();

      expect(controller.status, ProBillingStatus.error);
      expect(controller.message, 'Play failed to complete the purchase.');
      expect(controller.canPurchase, isTrue);
    }, skip: _testProOverrideEnabled);

    test('a failed Play purchase update leaves an actionable retry', () async {
      final service = _FakeBillingService();
      final controller = ProBillingController(
        service: service,
        store: _FakeEntitlementStore(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.buy();
      service.emit(
        const ProPurchaseUpdate(
          productId: syncFocusProProductId,
          status: ProPurchaseUpdateStatus.error,
          errorMessage: 'The purchase did not complete.',
        ),
      );
      await _flushPurchaseStream();

      expect(controller.status, ProBillingStatus.error);
      expect(controller.message, 'The purchase did not complete.');
      expect(controller.canPurchase, isTrue);
    }, skip: _testProOverrideEnabled);

    test('a failed purchase can be retried without losing the error', () async {
      final service = _FakeBillingService()
        ..buyError = StateError('Play could not start checkout.');
      final controller = ProBillingController(
        service: service,
        store: _FakeEntitlementStore(),
      );
      addTearDown(controller.dispose);

      await controller.load();
      await controller.buy();

      expect(controller.status, ProBillingStatus.error);
      expect(controller.message, 'Play could not start checkout.');
      expect(controller.canPurchase, isTrue);
    }, skip: _testProOverrideEnabled);

    test(
      'a recovered Lifetime purchase retries Play acknowledgement',
      () async {
        final recoveredPurchase = _unacknowledgedLifetimePurchase();
        final service = _FakeBillingService(
          ownership: ProOwnershipSnapshot(
            isActive: true,
            purchasesToComplete: [recoveredPurchase],
          ),
        )..failCompletion = true;
        final store = _FakeEntitlementStore();
        final controller = ProBillingController(service: service, store: store);
        addTearDown(controller.dispose);

        await controller.load();

        expect(controller.isPro, isTrue);
        expect(store.active, isTrue);
        expect(service.completedUpdates, [recoveredPurchase]);
        expect(
          controller.message,
          'Pro is active. Google Play confirmation will retry.',
        );

        service.failCompletion = false;
        await controller.restore();

        expect(service.completedUpdates, [
          recoveredPurchase,
          recoveredPurchase,
        ]);
        expect(controller.message, isNull);
        expect(controller.isPro, isTrue);
      },
    );

    test('pending Lifetime purchase does not unlock Pro', () async {
      final service = _FakeBillingService();
      final store = _FakeEntitlementStore();
      final controller = ProBillingController(service: service, store: store);
      addTearDown(controller.dispose);

      await controller.load();
      service.emit(
        const ProPurchaseUpdate(
          productId: syncFocusProLifetimeProductId,
          status: ProPurchaseUpdateStatus.pending,
        ),
      );
      await _flushPurchaseStream();

      expect(controller.isPro, _testProOverrideEnabled);
      expect(
        controller.status,
        _testProOverrideEnabled
            ? ProBillingStatus.active
            : ProBillingStatus.pending,
      );
      expect(store.active, isFalse);
    });

    test('confirmed Lifetime purchase enables and saves Pro', () async {
      final service = _FakeBillingService();
      final store = _FakeEntitlementStore();
      final controller = ProBillingController(service: service, store: store);
      addTearDown(controller.dispose);

      await controller.load();
      service.emit(
        const ProPurchaseUpdate(
          productId: syncFocusProLifetimeProductId,
          status: ProPurchaseUpdateStatus.purchased,
        ),
      );
      await _flushPurchaseStream();

      expect(controller.isPro, isTrue);
      expect(controller.status, ProBillingStatus.active);
      expect(store.active, isTrue);
    });

    test(
      'compile-time Pro testing flag unlocks features without entitlement',
      () async {
        final service = _FakeBillingService();
        final store = _FakeEntitlementStore();
        final controller = ProBillingController(service: service, store: store);
        addTearDown(controller.dispose);

        await controller.load();

        expect(controller.isPro, _testProOverrideEnabled);
        expect(
          controller.status,
          _testProOverrideEnabled
              ? ProBillingStatus.active
              : ProBillingStatus.ready,
        );
        expect(controller.canPurchase, !_testProOverrideEnabled);
        expect(store.active, isFalse);
      },
    );

    test('a pending purchase does not unlock Pro', () async {
      final service = _FakeBillingService();
      final store = _FakeEntitlementStore();
      final controller = ProBillingController(service: service, store: store);
      addTearDown(controller.dispose);

      await controller.load();
      service.emit(
        const ProPurchaseUpdate(
          productId: syncFocusProProductId,
          status: ProPurchaseUpdateStatus.pending,
        ),
      );
      await _flushPurchaseStream();

      expect(controller.isPro, _testProOverrideEnabled);
      expect(
        controller.status,
        _testProOverrideEnabled
            ? ProBillingStatus.active
            : ProBillingStatus.pending,
      );
      expect(store.active, isFalse);
    });

    test('a confirmed purchase enables Pro and saves entitlement', () async {
      final service = _FakeBillingService();
      final store = _FakeEntitlementStore();
      final controller = ProBillingController(service: service, store: store);
      addTearDown(controller.dispose);

      await controller.load();
      service.emit(
        const ProPurchaseUpdate(
          productId: syncFocusProProductId,
          status: ProPurchaseUpdateStatus.purchased,
        ),
      );
      await _flushPurchaseStream();

      expect(controller.isPro, isTrue);
      expect(controller.status, ProBillingStatus.active);
      expect(store.active, isTrue);
    });

    test(
      'an authoritative restore with no subscription clears cached Pro',
      () async {
        final service = _FakeBillingService(
          ownership: const ProOwnershipSnapshot(isActive: false),
        );
        final store = _FakeEntitlementStore(active: true);
        final controller = ProBillingController(service: service, store: store);
        addTearDown(controller.dispose);

        await controller.load();
        expect(controller.isPro, _testProOverrideEnabled);
        expect(store.active, isFalse);
      },
    );

    test('a restore query error retains cached Pro access', () async {
      final service = _FakeBillingService(
        ownership: const ProOwnershipSnapshot(
          isActive: false,
          errorMessage: 'Google Play is unavailable.',
        ),
      );
      final store = _FakeEntitlementStore(active: true);
      final controller = ProBillingController(service: service, store: store);
      addTearDown(controller.dispose);

      await controller.load();

      expect(controller.isPro, isTrue);
      expect(controller.status, ProBillingStatus.active);
      expect(store.active, isTrue);
    });
  });
}

Future<void> _flushPurchaseStream() async {
  await Future<void>.delayed(const Duration(milliseconds: 1));
}

class _FakeBillingService implements ProBillingService {
  _FakeBillingService({
    this.ownership = const ProOwnershipSnapshot(isActive: false),
    List<ProPurchaseOption>? options,
  }) : options = options ?? [_yearlyOption()];

  final StreamController<List<ProPurchaseUpdate>> _updates =
      StreamController<List<ProPurchaseUpdate>>.broadcast(sync: true);
  final ProOwnershipSnapshot ownership;
  final List<ProPurchaseOption> options;
  final List<ProPurchaseUpdate> completedUpdates = [];
  ProPurchaseOption? purchasedOption;
  Object? buyError;
  bool failCompletion = false;

  void emit(ProPurchaseUpdate update) => _updates.add([update]);

  @override
  Stream<List<ProPurchaseUpdate>> get purchaseUpdates => _updates.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<ProPurchaseOption>> loadOptions() async => options;

  @override
  Future<void> buy(ProPurchaseOption option) async {
    final error = buyError;
    if (error != null) throw error;
    purchasedOption = option;
  }

  @override
  Future<ProOwnershipSnapshot> queryOwnership() async => ownership;

  @override
  Future<void> completePurchase(ProPurchaseUpdate update) async {
    completedUpdates.add(update);
    if (failCompletion) throw Exception('Could not acknowledge purchase.');
  }
}

ProPurchaseOption _yearlyOption() => ProPurchaseOption(
  plan: ProPurchasePlan.yearly,
  product: ProductDetails(
    id: syncFocusProProductId,
    title: 'Sync Focus Pro',
    description: 'Yearly subscription',
    price: '\$39.99',
    rawPrice: 39.99,
    currencyCode: 'USD',
  ),
  offerToken: 'yearly-offer',
  localizedPrice: '\$39.99',
  pricingDisclosure: '\$39.99 per year. Renews automatically.',
);

ProPurchaseUpdate _unacknowledgedLifetimePurchase() {
  final rawPurchase = PurchaseDetails(
    productID: syncFocusProLifetimeProductId,
    verificationData: PurchaseVerificationData(
      localVerificationData: 'local',
      serverVerificationData: 'server',
      source: 'Google Play',
    ),
    transactionDate: '2026-11-03',
    status: PurchaseStatus.restored,
  )..pendingCompletePurchase = true;
  return ProPurchaseUpdate(
    productId: syncFocusProLifetimeProductId,
    status: ProPurchaseUpdateStatus.restored,
    rawPurchase: rawPurchase,
  );
}

ProPurchaseOption _lifetimeOption() => ProPurchaseOption(
  plan: ProPurchasePlan.lifetime,
  product: ProductDetails(
    id: syncFocusProLifetimeProductId,
    title: 'Sync Focus Pro Lifetime',
    description: 'One-time purchase',
    price: '\$99.99',
    rawPrice: 99.99,
    currencyCode: 'USD',
  ),
  localizedPrice: '\$99.99',
  pricingDisclosure: 'One-time purchase. Does not renew.',
);

class _FakeEntitlementStore implements ProEntitlementStore {
  _FakeEntitlementStore({this.active = false});

  bool active;

  @override
  Future<bool> isActive() async => active;

  @override
  Future<void> setActive(bool value) async => active = value;
}
