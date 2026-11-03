# Sync Focus Yearly and Lifetime Pro Options — Implementation Plan

**Goal:** Replace the new-buyer Monthly checkout choice with Yearly and Lifetime options while preserving entitlement for existing Monthly subscribers.

**Architecture:** Keep the current `syncfocus_pro` subscription product and add a yearly base plan. Add a one-time `syncfocus_pro_lifetime` product. The billing service returns plan-specific options, the controller tracks selection and entitlement, and the existing paywall renders selected-plan price and terms. Google Play remains the source for localized prices and purchase state.

**Spec:** `docs/superpowers/specs/2026-11-03-sync-focus-yearly-lifetime-design.md`

## Files and responsibilities

- `lib/features/pro/pro_billing_service.dart`: plan IDs, purchase option model, Play catalog loading, correct purchase parameters, ownership and update mapping.
- `lib/features/pro/pro_billing_controller.dart`: load options, select a plan, start its purchase, and preserve existing Pro entitlement handling.
- `lib/features/pro/pro_paywall_sheet.dart`: Yearly and Lifetime cards, selected-plan pricing/terms/CTA, and generic active-Pro copy.
- `test/features/pro/pro_billing_service_test.dart`: base-plan selection, one-time product availability, pricing-term mapping, purchase routing, and ownership identifiers.
- `test/features/pro/pro_billing_controller_test.dart`: initial selection, switching plans, purchase state transitions, and legacy/lifetime restore behavior.
- `test/features/pro/pro_paywall_sheet_test.dart`: two-option UI, localized price and terms, selected CTA, disabled unavailable option, and active-Pro state.
- `docs/superpowers/specs/2026-11-02-sync-focus-paywall-design.md`: mark the Monthly-only design as superseded by the new payment-options design.
- `docs/superpowers/specs/2026-11-03-sync-focus-yearly-lifetime-design.md`: maintain the Play Console product setup and live-billing verification requirement.

## Interfaces

The billing service exposes `Future<List<ProPurchaseOption>> loadOptions()`, `Future<void> buy(ProPurchaseOption option)`, `Future<ProOwnershipSnapshot> queryOwnership()`, and the existing purchase-update stream. Each option identifies `ProPurchasePlan.yearly` or `ProPurchasePlan.lifetime`, carries the Play `ProductDetails` and localized price, and includes a subscription offer token only for Yearly.

The controller exposes the loaded options, `selectedPlan`, `selectPlan(ProPurchasePlan)`, and the existing `buy()` action. It selects Yearly when available; if Yearly is unavailable and Lifetime is available, it selects Lifetime. It ignores `selectPlan` requests for unavailable options.

## Tasks

### Task 1: Add Yearly and Lifetime billing options

**Files:** modify `lib/features/pro/pro_billing_service.dart` and `test/features/pro/pro_billing_service_test.dart`.

- [ ] Write failing tests that select only base plan `02-syncfocus-pro-yearly` (never falling back to the legacy Monthly base plan), retain lifetime `ProductDetails` as a one-time option, route Yearly with its offer token and Lifetime without a subscription offer token, and recognize both `syncfocus_pro` and `syncfocus_pro_lifetime` as owned products.
- [ ] Run the focused billing service tests and confirm the new assertions fail for the missing two-option catalog/ownership behavior.
- [ ] Add `syncFocusProYearlyBasePlanId = '02-syncfocus-pro-yearly'` and `syncFocusProLifetimeProductId = 'syncfocus_pro_lifetime'`; introduce the purchase option model and update `ProBillingService` to load both products, select the Yearly base plan exactly, initiate each purchase type correctly, and map ownership/update IDs without dropping existing Monthly buyers.
- [ ] Run `flutter test test/features/pro/pro_billing_service_test.dart` and confirm it passes.

### Task 2: Track selected plan and entitlement in the controller

**Files:** modify `lib/features/pro/pro_billing_controller.dart` and `test/features/pro/pro_billing_controller_test.dart`.

- [ ] Add failing controller tests for Yearly as the initial available selection, Lifetime fallback when Yearly is unavailable, ignored selection of unavailable plans, purchase dispatch for the selected plan, pending Lifetime not granting Pro, and restore/confirmed updates for Lifetime and the existing Monthly product.
- [ ] Run `flutter test test/features/pro/pro_billing_controller_test.dart` and confirm the new assertions fail.
- [ ] Replace the single-offer state with the option list and selected-plan state; retain the existing `isPro`, debug override, cache, pending/error, and authoritative-restore rules.
- [ ] Run `flutter test test/features/pro/pro_billing_controller_test.dart` and confirm it passes.

### Task 3: Present the two choices in the paywall

**Files:** modify `lib/features/pro/pro_paywall_sheet.dart` and `test/features/pro/pro_paywall_sheet_test.dart`.

- [ ] Add failing widget tests that the Free checkout displays Yearly and Lifetime but no Monthly choice, shows the selected option's localized price and terms, updates the CTA after selecting Lifetime, disables unavailable choices, and uses generic active-Pro wording.
- [ ] Run `flutter test test/features/pro/pro_paywall_sheet_test.dart` and confirm the new assertions fail.
- [ ] Replace `_MonthlyPlanRow` with selectable Yearly and Lifetime rows. Show Play-localized prices, say Yearly auto-renews annually and can be canceled in Google Play, say Lifetime is a one-time purchase with no renewal, and make the CTA follow the selected option. Preserve the current colors, pinned footer, restore action, and legal links.
- [ ] Run `flutter test test/features/pro/pro_paywall_sheet_test.dart` and confirm it passes.

### Task 4: Reconcile documentation and verify the app

**Files:** modify the two design specifications listed above.

- [ ] Mark the old Monthly-only checkout specification as superseded and confirm the current design records the Play Console IDs, localized price rule, annual renewal, lifetime one-time terms, and legacy Monthly entitlement.
- [ ] Run `flutter test` and `flutter test --dart-define=SYNC_FOCUS_PRO=true`; both must pass.
- [ ] Run `flutter analyze`; it must report no issues.
- [ ] Build a debug APK and launch it on the Android emulator. Verify the paywall presents the two choices and that missing/unconfigured Play products are reported without showing fabricated prices. Live purchase verification waits for Play Console configuration and an eligible Play test account.
