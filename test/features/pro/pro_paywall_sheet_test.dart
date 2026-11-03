import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:syncfocus/features/pro/pro_billing_controller.dart';
import 'package:syncfocus/features/pro/pro_billing_service.dart';
import 'package:syncfocus/features/pro/pro_paywall_sheet.dart';
import 'package:syncfocus/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const flagEnabled = bool.fromEnvironment(
    'SYNC_FOCUS_PRO',
    defaultValue: false,
  );
  final overrideExpected = kDebugMode && flagEnabled;

  testWidgets('Pro test flag is labeled as test access in the checkout', (
    tester,
  ) async {
    final controller = ProBillingController(
      service: _ReadyBillingService(),
      store: _MemoryEntitlementStore(),
    );
    await controller.load();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: ProPaywallSheet(billing: controller)),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Pro testing access is enabled for this debug build.'),
      overrideExpected ? findsOneWidget : findsNothing,
    );
    expect(
      find.text('Your Sync Focus Pro subscription is active.'),
      findsNothing,
    );
  });

  testWidgets('shows Yearly and Lifetime choices without Monthly', (
    tester,
  ) async {
    final controller = ProBillingController(
      service: _ReadyBillingService(),
      store: _MemoryEntitlementStore(),
    );
    await controller.load();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 800,
              child: ProPaywallSheet(billing: controller),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (overrideExpected) {
      expect(
        find.text('Pro testing access is enabled for this debug build.'),
        findsOneWidget,
      );
      expect(find.text('Restore purchase'), findsNothing);
    } else {
      expect(find.text('Unlock Sync Focus Pro'), findsOneWidget);
      expect(find.text('Focus Guard & Do Not Disturb'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);
      expect(find.text('Lifetime'), findsOneWidget);
      expect(find.textContaining('Monthly'), findsNothing);
      expect(find.text('Start Pro · \$39.99 / year'), findsOneWidget);
      expect(find.text('Restore purchase'), findsOneWidget);
      expect(
        find.text('Price and payment handled by Google Play'),
        findsOneWidget,
      );
    }
  });

  testWidgets('shows selected localized terms and updates the CTA', (
    tester,
  ) async {
    final controller = ProBillingController(
      service: _ReadyBillingService(),
      store: _MemoryEntitlementStore(),
    );
    await controller.load();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_paywall(controller));
    await tester.pumpAndSettle();

    expect(
      find.text('\$39.99 per year. Renews automatically.'),
      findsOneWidget,
    );
    expect(find.text('Start Pro · \$39.99 / year'), findsOneWidget);
    expect(find.byKey(const Key('pro-plan-yearly-semantics')), findsOneWidget);
    final yearlySemantics = tester.getSemantics(
      find.byKey(const Key('pro-plan-yearly-semantics')),
    );
    expect(yearlySemantics.label, contains('\$39.99'));
    expect(yearlySemantics.label, contains('Renews annually'));
    expect(
      yearlySemantics.flagsCollection.isChecked == CheckedState.isTrue,
      isTrue,
    );

    await tester.tap(find.byKey(const Key('pro-plan-lifetime')));
    await tester.pumpAndSettle();

    expect(find.text('One-time purchase. Does not renew.'), findsOneWidget);
    expect(find.text('Buy Lifetime · \$99.99'), findsOneWidget);
    expect(
      find.byKey(const Key('pro-plan-lifetime-semantics')),
      findsOneWidget,
    );
    final lifetimeSemantics = tester.getSemantics(
      find.byKey(const Key('pro-plan-lifetime-semantics')),
    );
    expect(lifetimeSemantics.label, contains('\$99.99'));
    expect(lifetimeSemantics.label, contains('One-time purchase'));
    expect(
      lifetimeSemantics.flagsCollection.isChecked == CheckedState.isTrue,
      isTrue,
    );
  }, skip: overrideExpected);

  testWidgets('keeps an unavailable plan visible and disabled', (tester) async {
    final controller = ProBillingController(
      service: _ReadyBillingService(options: [_yearlyOption()]),
      store: _MemoryEntitlementStore(),
    );
    await controller.load();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_paywall(controller));
    await tester.pumpAndSettle();

    final lifetimeCard = tester.widget<InkWell>(
      find.byKey(const Key('pro-plan-lifetime')),
    );
    expect(find.text('Lifetime'), findsOneWidget);
    expect(lifetimeCard.onTap, isNull);
    expect(
      find.byKey(const Key('pro-plan-lifetime-semantics')),
      findsOneWidget,
    );
    expect(
      tester
              .getSemantics(
                find.byKey(const Key('pro-plan-lifetime-semantics')),
              )
              .flagsCollection
              .isEnabled ==
          Tristate.isTrue,
      isFalse,
    );
    expect(find.text('Unavailable'), findsOneWidget);
    expect(controller.selectedPlan, ProPurchasePlan.yearly);
  }, skip: overrideExpected);

  testWidgets('uses generic wording for restored Pro access', (tester) async {
    final controller = ProBillingController(
      service: _ReadyBillingService(
        ownership: const ProOwnershipSnapshot(isActive: true),
      ),
      store: _MemoryEntitlementStore(),
    );
    await controller.load();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_paywall(controller));
    await tester.pumpAndSettle();

    expect(
      find.text('Your Sync Focus Pro access is active.'),
      overrideExpected ? findsNothing : findsOneWidget,
    );
    expect(
      find.text('Your Sync Focus Pro subscription is active.'),
      findsNothing,
    );
  });

  testWidgets('keeps the checkout footer pinned while benefits scroll', (
    tester,
  ) async {
    final controller = ProBillingController(
      service: _ReadyBillingService(),
      store: _MemoryEntitlementStore(),
    );
    await controller.load();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              height: 800,
              child: ProPaywallSheet(billing: controller),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final footer = tester.getTopLeft(
      find.byKey(const Key('pro-checkout-footer')),
    );
    await tester.drag(
      find.byKey(const Key('pro-paywall-scroll')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const Key('pro-checkout-footer'))),
      footer,
    );
  });
}

Widget _paywall(ProBillingController controller) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: 400,
        height: 800,
        child: ProPaywallSheet(billing: controller),
      ),
    ),
  ),
);

class _ReadyBillingService implements ProBillingService {
  _ReadyBillingService({
    this.ownership = const ProOwnershipSnapshot(isActive: false),
    List<ProPurchaseOption>? options,
  }) : options = options ?? [_yearlyOption(), _lifetimeOption()];

  final Stream<List<ProPurchaseUpdate>> _updates = const Stream.empty();
  final ProOwnershipSnapshot ownership;
  final List<ProPurchaseOption> options;

  @override
  Stream<List<ProPurchaseUpdate>> get purchaseUpdates => _updates;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<List<ProPurchaseOption>> loadOptions() async => options;

  @override
  Future<void> buy(ProPurchaseOption option) async {}

  @override
  Future<ProOwnershipSnapshot> queryOwnership() async => ownership;

  @override
  Future<void> completePurchase(ProPurchaseUpdate update) async {}
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

class _MemoryEntitlementStore implements ProEntitlementStore {
  @override
  Future<bool> isActive() async => false;

  @override
  Future<void> setActive(bool active) async {}
}
