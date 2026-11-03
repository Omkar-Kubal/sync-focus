# Sync Focus Pro Paywall Implementation Plan

> **For agentic workers:** Execute this plan task-by-task in the current user-authorized workspace. Keep verification focused on static analysis, Android builds, and emulator review.

**Goal:** Replace Sync Focus’s Explore Pro sheet with a Sync Spend-matched paywall and connect it to the existing monthly Google Play subscription.

**Architecture:** Keep billing state and purchase handling in a focused Dart controller backed by a Google Play service. Pass one app-lifetime controller from the app shell into Settings and render a dedicated scrollable paywall with a pinned checkout footer, using only existing Sync Focus theme tokens.

**Tech Stack:** Flutter, Dart, `in_app_purchase`, `in_app_purchase_android`, `shared_preferences`, `url_launcher`, Android emulator.

**Spec:** `docs/superpowers/specs/2026-11-02-sync-focus-paywall-design.md`

## Global Constraints

- Product ID: `syncfocus_pro`; base plan ID: `01-syncfocus-pro`; subscription is monthly and cancelable through Google Play.
- Use the localized offer phases and recurring terms returned by Google Play.
- Prefer the configured base-plan offer; follow the existing Kotlin fallback to the first returned offer when none match.
- Pending or failed purchases never unlock Pro; an authoritative empty ownership query clears cached entitlement, while a query error does not.
- Do not edit native Kotlin, add server verification, create a lifetime offer, or change existing Pro feature enforcement.
- Preserve Sync Focus’s logo, typography, privacy URL, and current global palette.

## Review Focus

- Matching offer missing or multiple offers returned: select the configured base plan and retain the Kotlin first-offer fallback.
- Trial or intro phases present: show the phase pricing followed by the recurring localized price and interval.
- Play unavailable or catalog query failing: show a clear unavailable state and disable subscribe without blocking restore retry.
- Pending, canceled, and failed transaction updates: never set active entitlement until Play reports a purchased/restored state.
- Subscription expires or ownership query fails: clear cached active access only on an authoritative empty query; retain it during query errors.

---

### Task 1: Add subscription billing state and service

**Files:**
- Create: `lib/features/pro/pro_billing_service.dart` — query the product, resolve a configured subscription offer, launch purchase, query subscription ownership, and complete purchases.
- Create: `lib/features/pro/pro_billing_controller.dart` — app-lifetime observable state, startup reconciliation, purchase stream processing, and local entitlement cache.
- Create: `test/features/pro/pro_billing_controller_test.dart` — pending/purchased/restore entitlement behavior.
- Create: `test/features/pro/pro_billing_service_test.dart` — configured base-plan selection and fallback.
- Modify: `pubspec.yaml` — add `in_app_purchase` and `in_app_purchase_android`.
- Modify: `pubspec.lock` — dependency resolution.

**Interfaces:**
- Produces `ProBillingController extends ChangeNotifier`, with getters `status`, `isPro`, `priceLabel`, `pricingDisclosure`, `message`, `isBusy`; and methods `load()`, `buy()`, `restore()`, and `dispose()`.
- Status states: `loading`, `ready`, `unavailable`, `purchasing`, `restoring`, `pending`, `active`, `error`.
- Service resolves product `syncfocus_pro` and base plan `01-syncfocus-pro`, preferring the matching Android subscription offer and falling back to the first returned offer only when necessary.

- [x] Add the two billing packages at the same compatible version ranges used by Sync Spend (`in_app_purchase: ^3.3.0`, `in_app_purchase_android: ^0.5.2`), then run `flutter pub get`.
- [x] Write controller tests for pending purchase not unlocking Pro, confirmed purchase activating Pro, authoritative empty restore clearing cached Pro, and restore query error retaining cached Pro.
- [x] Run `flutter test test/features/pro/pro_billing_controller_test.dart`; confirmed the expected missing controller implementation failure.
- [x] Write an offer-selection test: choose the `01-syncfocus-pro` candidate among multiple offers and fall back to the first candidate if no base plan matches.
- [x] Run `flutter test test/features/pro/pro_billing_service_test.dart`; confirmed the expected missing offer resolver failure.
- [x] Implement the Google Play service using `InAppPurchase.instance.queryProductDetails`, `GooglePlayProductDetails.productDetails.subscriptionOfferDetails`, `GooglePlayPurchaseParam`, Android `queryPastPurchases`, and `completePurchase`.
- [x] Convert each selected offer’s pricing phases into a display disclosure: introductory/finite phases when present, plus the recurring phase price and readable billing interval.
- [x] Implement `ProBillingController.load()` to subscribe to purchase updates, query Play availability and catalog, and reconcile active subscriptions before publishing ready state.
- [x] Process only `syncfocus_pro` purchased/restored updates as active; keep pending/canceled/error separate, complete pending transactions, and persist active cache in `SharedPreferences`.
- [x] On ownership query success, set active when Play returns an active subscription and clear stale cache when it authoritatively returns none; retain the cache when the query fails.
- [x] Run `flutter test test/features/pro/pro_billing_controller_test.dart test/features/pro/pro_billing_service_test.dart`; all seven billing assertions passed.
- [x] Run `flutter analyze`; initially surfaced missing legacy logo token aliases, fixed by registering the existing source/light logo asset paths; final analysis has no issues.

### Task 2: Build the matching paywall UI

**Files:**
- Create: `lib/features/pro/pro_paywall_sheet.dart` — 90%-height sheet, hero, benefit list, fixed checkout/footer, close control, active state.
- Modify: `lib/theme/app_colors.dart` — keep the shared palette as the source for all paywall colors; do not add Pro-specific colors.
- Create: `test/features/pro/pro_paywall_sheet_test.dart` — checkout-state and scroll/footer semantics.

**Interfaces:**
- Consumes `ProBillingController` from Task 1.
- Produces `ProPaywallSheet({required ProBillingController billing})`.
- Uses existing `AppLogo`, Hugeicons through `AppIcon`, `AppTypography`, and `context.palette`; no new UI dependency.

- [x] Write a paywall widget test with a fake `ProBillingController` in the ready state; assert Sync Focus branding, the monthly checkout action, restore action, and pinned footer are present.
- [x] Run `flutter test test/features/pro/pro_paywall_sheet_test.dart`; confirmed the expected missing paywall implementation failure.
- [x] Remove the copied Sync Spend texture assets and their `pubspec.yaml` entries after the user clarified the paywall must use Sync Focus colors.
- [x] Use the existing blue, black, white, and brightness-aware surface tokens from `AppColorPalette` throughout the paywall; remove the Pro-only gold and beige palette entries.
- [x] Implement a rounded top sheet at height factor `0.9`, scrollable hero and five benefit rows, floating close button, and a checkout footer pinned beneath the scroll area.
- [x] Retain Sync Focus’s circular logo, current benefit titles/copy, Hugeicons and Google Sans Flex styles.
- [x] Implement the monthly plan card, localized phase/recurrence disclosure, subscribe action, restore action, Google Play payment disclosure, Privacy Policy and Terms links.
- [x] Render loading, unavailable, pending, error, active (“You’re Pro!” / “Start focusing”), and free checkout states from `ProBillingController`.
- [x] Run `flutter test test/features/pro/pro_paywall_sheet_test.dart`; after fixing the narrow footer text wrap, the test passed.
- [x] Run `flutter analyze`; no issues found.

### Task 3: Wire paywall and controller into the app

**Files:**
- Modify: `lib/main.dart` — create, load, pass, and dispose one `ProBillingController` for the app lifetime.
- Modify: `lib/features/focus/focus_home_screen.dart` — receive the controller and pass it into Settings.
- Modify: `lib/features/settings/settings_sheet.dart` — replace `_ProDetailsSheet` with `ProPaywallSheet` and link existing Pro entry points to billing state.

**Interfaces:**
- `MyApp` owns one controller; `FocusHomeShell` and `SettingsSheet` receive that same instance.
- Existing Pro entry points continue to open the purchase sheet. Closing an active success state returns to the app.

- [x] Create and load `ProBillingController` in `MyApp.initState`, then dispose it in `MyApp.dispose`.
- [x] Pass the shared controller through `FocusHomeShell` to `SettingsSheet`.
- [x] Replace the current informational `_ProDetailsSheet` builder with `ProPaywallSheet(billing: ...)` and remove the obsolete private Pro-only widgets.
- [x] Run `flutter analyze`; no issues found.

### Task 4: Build, install, and inspect on the Android emulator

**Files:**
- No source changes unless inspection finds a visual or build defect.

- [x] Run `flutter build apk --debug`; the Sync Focus debug APK built successfully.
- [x] Install and launch the app on the running Android emulator; open Settings → Explore Pro.
- [x] Inspect the dark paywall layout, scroll behavior, pinned footer, product-unavailable state, and navigation back to Settings.
- [x] Inspect the light and dark paywall surfaces, blue accents, logo, and text contrast on the emulator.
- [x] Check Play product availability; this sideloaded emulator cannot retrieve the product catalog, so the unavailable price and disabled purchase state are displayed. Live purchase and restore still need validation through a Play-enabled install with the product available.

