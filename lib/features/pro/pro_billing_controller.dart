import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfocus/core/analytics/app_analytics.dart';
import 'package:syncfocus/core/crash/crash_reporter.dart';

import 'pro_billing_service.dart';

const _proTestOverrideBuildFlag = bool.fromEnvironment(
  'SYNC_FOCUS_PRO',
  defaultValue: false,
);

enum ProBillingStatus {
  loading,
  ready,
  unavailable,
  purchasing,
  restoring,
  pending,
  active,
  error,
}

abstract interface class ProEntitlementStore {
  Future<bool> isActive();

  Future<void> setActive(bool active);
}

class SharedPreferencesProEntitlementStore implements ProEntitlementStore {
  const SharedPreferencesProEntitlementStore();

  static const _activeKey = 'sync_focus_pro_subscription_active';

  @override
  Future<bool> isActive() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_activeKey) ?? false;
  }

  @override
  Future<void> setActive(bool active) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setBool(_activeKey, active);
    if (!saved) throw StateError('Unable to save the Pro subscription state.');
  }
}

class ProBillingController extends ChangeNotifier {
  ProBillingController({ProBillingService? service, ProEntitlementStore? store})
    : _service = service ?? InAppPurchaseProBillingService(),
      _store = store ?? const SharedPreferencesProEntitlementStore();

  final ProBillingService _service;
  final ProEntitlementStore _store;
  StreamSubscription<List<ProPurchaseUpdate>>? _purchaseSubscription;
  Future<void>? _loadFuture;
  List<ProPurchaseOption> _options = const [];
  final Set<String> _loggedRevenueIdentifiers = <String>{};
  ProPurchasePlan? _selectedPlan;
  ProBillingStatus _status = ProBillingStatus.loading;
  String? _message;
  bool _isPro = false;
  bool _purchaseRetryAvailable = false;
  bool _disposed = false;

  /// Enables Pro paths for local debug builds when SYNC_FOCUS_PRO is true.
  /// This override never changes or persists the Play entitlement.
  bool get isTestOverrideActive => kDebugMode && _proTestOverrideBuildFlag;

  ProBillingStatus get status =>
      isTestOverrideActive ? ProBillingStatus.active : _status;
  bool get isPro => _isPro || isTestOverrideActive;
  List<ProPurchaseOption> get options => List.unmodifiable(_options);
  ProPurchasePlan? get selectedPlan => _selectedPlan;
  ProPurchaseOption? get selectedOption {
    for (final option in _options) {
      if (option.plan == _selectedPlan) return option;
    }
    return null;
  }

  String get priceLabel => selectedOption?.localizedPrice ?? '';
  String get recurringPeriodLabel => switch (_selectedPlan) {
    ProPurchasePlan.yearly => 'year',
    ProPurchasePlan.lifetime => '',
    null => 'year',
  };
  String get pricingDisclosure =>
      selectedOption?.pricingDisclosure ??
      'Price and subscription terms are provided by Google Play.';
  String? get message => _message;
  bool get hasOffer => _options.isNotEmpty;
  bool get canPurchase =>
      selectedOption != null &&
      (_status == ProBillingStatus.ready ||
          (_status == ProBillingStatus.error && _purchaseRetryAvailable)) &&
      !isPro;
  bool get isBusy =>
      !isTestOverrideActive &&
      (_status == ProBillingStatus.loading ||
          _status == ProBillingStatus.purchasing ||
          _status == ProBillingStatus.restoring);

  Future<void> load() => _loadFuture ??= _load();

  Future<void> _load() async {
    _purchaseSubscription = _service.purchaseUpdates.listen(
      (updates) => unawaited(_handlePurchaseUpdates(updates)),
      onError: (Object error, StackTrace stackTrace) {
        _setMessage('Google Play purchase updates were interrupted.');
        if (!_isPro) _status = ProBillingStatus.error;
        _notify();
      },
    );

    try {
      _isPro = await _store.isActive();
    } on Exception {
      _isPro = false;
      _message = 'Unable to read saved Pro status. Google Play will retry.';
    }
    if (_disposed) return;

    var available = false;
    try {
      available = await _service.isAvailable();
    } on Exception {
      available = false;
    }
    if (_disposed) return;

    if (!available) {
      _purchaseRetryAvailable = false;
      _status = _isPro ? ProBillingStatus.active : ProBillingStatus.unavailable;
      _message = _isPro
          ? 'Pro is active. Google Play could not verify it right now.'
          : 'Google Play billing is unavailable. Try again later.';
      _notify();
      return;
    }

    try {
      _options = await _service.loadOptions();
      _selectedPlan = _initialPlanFor(_options);
    } on Exception {
      _options = const [];
      _selectedPlan = null;
      _message = 'Unable to load Sync Focus Pro purchase options.';
    }
    if (_disposed) return;

    final ownership = await _service.queryOwnership();
    if (_disposed) return;
    await _applyOwnership(ownership);
    if (!_isPro && !_disposed && _options.isEmpty && _message == null) {
      _status = ProBillingStatus.unavailable;
      _message =
          'Sync Focus Pro purchase options are unavailable in Google Play.';
    }
    _notify();
  }

  Future<void> buy() async {
    final option = selectedOption;
    if (!canPurchase || option == null || _disposed) return;
    _status = ProBillingStatus.purchasing;
    _purchaseRetryAvailable = false;
    _message = null;
    _notify();
    try {
      await _service.buy(option);
    } on Object catch (error) {
      if (_disposed) return;
      _status = _isPro ? ProBillingStatus.active : ProBillingStatus.error;
      _purchaseRetryAvailable = !_isPro;
      _message = error is StateError
          ? error.message.toString()
          : 'Google Play could not start the purchase. Please retry.';
      _notify();
    }
  }

  void selectPlan(ProPurchasePlan plan) {
    if (_disposed || !_options.any((option) => option.plan == plan)) return;
    if (_selectedPlan == plan) return;
    _selectedPlan = plan;
    _notify();
  }

  Future<void> restore() async {
    if (_disposed || _status == ProBillingStatus.restoring) return;
    _status = ProBillingStatus.restoring;
    _purchaseRetryAvailable = false;
    _message = null;
    _notify();
    final snapshot = await _service.queryOwnership();
    if (_disposed) return;
    await _applyOwnership(
      snapshot,
      emptyMessage: 'No active Pro subscription was found.',
    );
    _notify();
  }

  Future<void> _handlePurchaseUpdates(List<ProPurchaseUpdate> updates) async {
    for (final update in updates) {
      if (_disposed) continue;
      if (!isSyncFocusProProductId(update.productId)) {
        if (update.productId.isEmpty &&
            _status == ProBillingStatus.purchasing &&
            update.status != ProPurchaseUpdateStatus.pending) {
          _handleProductlessTerminalUpdate(update);
        }
        continue;
      }
      switch (update.status) {
        case ProPurchaseUpdateStatus.purchased:
        case ProPurchaseUpdateStatus.restored:
          final isNewPurchase =
              update.status == ProPurchaseUpdateStatus.purchased;
          _isPro = true;
          _status = ProBillingStatus.active;
          _purchaseRetryAvailable = false;
          _message = null;
          await _persistEntitlement(true);
          if (isNewPurchase) unawaited(_logPurchaseRevenue(update));
          break;
        case ProPurchaseUpdateStatus.pending:
          if (!_isPro) {
            _status = ProBillingStatus.pending;
            _purchaseRetryAvailable = false;
            _message =
                'Purchase pending. Pro unlocks after payment is confirmed.';
          }
          break;
        case ProPurchaseUpdateStatus.canceled:
          _status = _isPro ? ProBillingStatus.active : _readyStatus;
          _purchaseRetryAvailable = false;
          _message = null;
          break;
        case ProPurchaseUpdateStatus.error:
          _status = _isPro ? ProBillingStatus.active : ProBillingStatus.error;
          _purchaseRetryAvailable = !_isPro;
          _message =
              update.errorMessage ??
              'The purchase did not complete. Please retry.';
          break;
      }

      if (update.pendingCompletePurchase &&
          update.status != ProPurchaseUpdateStatus.pending) {
        try {
          await _service.completePurchase(update);
        } on Exception {
          _setMessage('Pro is active. Google Play confirmation will retry.');
        }
      }
    }
    _notify();
  }

  Future<void> _logPurchaseRevenue(ProPurchaseUpdate update) async {
    ProPurchaseOption? option;
    for (final candidate in _options) {
      if (candidate.product.id == update.productId) {
        option = candidate;
        break;
      }
    }
    if (option == null) return;

    final rawTransactionId = update.rawPurchase?.purchaseID?.trim();
    final transactionId = rawTransactionId?.isNotEmpty == true
        ? rawTransactionId
        : null;
    final revenueIdentifier = transactionId ?? update.productId;
    if (!_loggedRevenueIdentifiers.add(revenueIdentifier)) return;

    try {
      await AppAnalytics.logPurchaseRevenue(
        AppAnalyticsPurchaseEvent(
          productId: option.product.id,
          productName: option.product.title,
          value: option.product.rawPrice,
          currency: option.product.currencyCode,
          quantity: 1,
          transactionId: transactionId,
        ),
      );
    } on Object catch (error, stackTrace) {
      await CrashReporter.recordError(
        error,
        stackTrace,
        'Firebase purchase revenue logging failed',
      );
    }
  }

  Future<void> _applyOwnership(
    ProOwnershipSnapshot snapshot, {
    String? emptyMessage,
  }) async {
    if (!snapshot.isAuthoritative) {
      _status = _isPro ? ProBillingStatus.active : ProBillingStatus.error;
      _purchaseRetryAvailable = false;
      _message =
          snapshot.errorMessage ??
          'Unable to verify purchases with Google Play.';
      return;
    }

    if (snapshot.isActive) {
      _isPro = true;
      _status = ProBillingStatus.active;
      _purchaseRetryAvailable = false;
      _message = null;
      await _persistEntitlement(true);
      await _completeRecoveredPurchases(snapshot.purchasesToComplete);
      return;
    }

    _isPro = false;
    _purchaseRetryAvailable = false;
    await _persistEntitlement(false);
    if (snapshot.isPending) {
      _status = ProBillingStatus.pending;
      _message = 'Purchase pending. Pro unlocks after payment is confirmed.';
    } else {
      _status = _readyStatus;
      _message = emptyMessage;
    }
  }

  void _handleProductlessTerminalUpdate(ProPurchaseUpdate update) {
    if (update.status == ProPurchaseUpdateStatus.canceled) {
      _status = _isPro ? ProBillingStatus.active : _readyStatus;
      _purchaseRetryAvailable = false;
      _message = null;
      return;
    }

    _status = _isPro ? ProBillingStatus.active : ProBillingStatus.error;
    _purchaseRetryAvailable = !_isPro;
    _message = update.status == ProPurchaseUpdateStatus.error
        ? update.errorMessage ?? 'The purchase did not complete. Please retry.'
        : 'Google Play could not verify the purchase product. Please retry.';
  }

  Future<void> _completeRecoveredPurchases(
    List<ProPurchaseUpdate> purchases,
  ) async {
    for (final purchase in purchases) {
      if (!isSyncFocusProProductId(purchase.productId) ||
          !purchase.pendingCompletePurchase ||
          (purchase.status != ProPurchaseUpdateStatus.purchased &&
              purchase.status != ProPurchaseUpdateStatus.restored)) {
        continue;
      }
      try {
        await _service.completePurchase(purchase);
      } on Exception {
        _setMessage('Pro is active. Google Play confirmation will retry.');
      }
    }
  }

  ProBillingStatus get _readyStatus =>
      _options.isEmpty ? ProBillingStatus.unavailable : ProBillingStatus.ready;

  ProPurchasePlan? _initialPlanFor(List<ProPurchaseOption> options) {
    if (options.any((option) => option.plan == ProPurchasePlan.yearly)) {
      return ProPurchasePlan.yearly;
    }
    if (options.any((option) => option.plan == ProPurchasePlan.lifetime)) {
      return ProPurchasePlan.lifetime;
    }
    return null;
  }

  Future<void> _persistEntitlement(bool active) async {
    try {
      await _store.setActive(active);
    } on Exception {
      _message = active
          ? 'Pro is active, but its saved status could not be refreshed.'
          : 'Unable to clear the saved Pro status. It will be checked again.';
    }
  }

  void _setMessage(String message) => _message = message;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_purchaseSubscription?.cancel());
    super.dispose();
  }
}
