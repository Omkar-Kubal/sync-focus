# Sync Focus Android Firebase Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Android Crashlytics reporting and confirmed Pro purchase revenue events to Firebase project Toki (`toki-0001`).

**Architecture:** Register `com.appylab.syncfocus` as an Android app in the existing Firebase project, generate its own Android config, and use Firebase Core, Crashlytics, and Analytics. Initialize Crashlytics before `runApp`, preserve app startup if Firebase initialization fails, and log Play purchase revenue only for `purchased` updates using the matching Play product metadata.

**Tech Stack:** Flutter/Dart, `firebase_core`, `firebase_crashlytics`, `firebase_analytics`, Firebase CLI, FlutterFire CLI, Google Services Gradle plugin, Firebase Crashlytics Gradle plugin, Google Play Billing.

**Spec:** `docs/superpowers/specs/2026-11-13-sync-focus-firebase-android-design.md`

## Global Constraints

- Configure Android only; do not register or configure the iOS target.
- Use the existing Firebase project `toki-0001` and Android package `com.appylab.syncfocus`.
- Do not change Google Play product IDs, billing flows, entitlement rules, or add a server-side receipt service.
- Do not log restores, pending purchases, cancellations, or failures as revenue.
- Firebase initialization and Analytics failures must not block app startup or purchase completion.
- Do not add or run tests for this task.

## Review Focus

- **Wrong Firebase app or project:** Verify `firebase apps:list --project toki-0001` shows the Android app with package `com.appylab.syncfocus`, and verify generated config references project `toki-0001`.
- **Firebase initialization unavailable:** Inspect startup fallback so the app still reaches `runApp` if Firebase initialization fails.
- **Crash handler coverage:** Inspect that framework, platform-dispatcher, and uncaught zone errors all reach Crashlytics when initialized.
- **Non-revenue purchase states:** Inspect the billing controller so only `purchased` updates call the Analytics revenue logger; restored, pending, canceled, and error updates do not.
- **Invalid price or analytics failure:** Inspect that non-positive values or missing currency are skipped, and Analytics exceptions do not prevent entitlement persistence or purchase acknowledgement.

---

### Task 1: Register Sync Focus and configure the Android Firebase SDK

**Files:**
- Modify: `pubspec.yaml` — add the same Firebase package constraints used by Sync Spend (`firebase_core: ^4.12.1`, `firebase_crashlytics: ^5.2.6`, `firebase_analytics: ^12.4.5`).
- Modify: `android/settings.gradle.kts` — declare Google Services plugin `4.5.0` and Crashlytics plugin `3.0.7` with `apply false`, following Sync Spend.
- Modify: `android/app/build.gradle.kts` — apply both Firebase Gradle plugins.
- Create: `android/app/google-services.json` — generate for the Toki Android app registration.
- Create: `firebase.json` — store FlutterFire Android project/app mapping.
- Create: `lib/firebase_options.dart` — generate Android Firebase options.

**Interfaces:**
- Consumes: Firebase CLI authentication for project `toki-0001`; current Android package ID `com.appylab.syncfocus`.
- Produces: App-specific Firebase configuration whose Android app ID belongs to Toki and whose package name is `com.appylab.syncfocus`.

- [x] Check `firebase apps:list --project toki-0001`; SyncFocus is already registered, and its SDK config identifies `com.appylab.syncfocus`.
- [x] Install FlutterFire CLI 1.5.0.
- [x] Run `flutterfire configure --project toki-0001 --platforms android` after Firebase CLI authentication is available.
- [x] Add the three Firebase dependencies and both Gradle plugins, leaving SDK levels, app ID, signing, and iOS files unchanged.
- [x] Run `flutter pub get`.
- [x] Confirm the generated config contains project `toki-0001` and the `com.appylab.syncfocus` app registration.

### Task 2: Initialize Firebase and route uncaught errors to Crashlytics

**Files:**
- Create: `lib/core/crash/crash_reporter.dart` — initialization, Flutter/platform/zone error hooks, and nonfatal error recording.
- Modify: `lib/main.dart` — initialize Firebase and install handlers before starting the app.

**Interfaces:**
- Consumes: `DefaultFirebaseOptions.currentPlatform` from Task 1.
- Produces: `CrashReporter.runAppGuarded(FutureOr<void> Function() appRunner)`, `CrashReporter.recordError(Object, [StackTrace?, String?])`, and a guarded app bootstrap.

- [x] Implement `CrashReporter.initialize()` using `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` and enable Crashlytics collection.
- [x] Install `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and `runZonedGuarded` handlers modeled on Sync Spend.
- [x] Make Firebase initialization failure fall back to launching the app; leave Crashlytics disabled when Firebase is unavailable.
- [x] Update `main()` to run the existing `MyApp` through the guarded bootstrap without changing app state or billing startup order.

### Task 3: Log confirmed Play purchase revenue

**Files:**
- Create: `lib/core/analytics/app_analytics.dart` — Firebase Analytics purchase event type and `logPurchaseRevenue` helper.
- Modify: `lib/features/pro/pro_billing_controller.dart` — build revenue events from the matching loaded Play product for confirmed purchases.

**Interfaces:**
- Consumes: `ProPurchaseUpdate`, `_options`, and each `ProPurchaseOption.product` (`id`, `title`, `rawPrice`, `currencyCode`); `update.rawPurchase?.purchaseID` when present.
- Produces: `AppAnalyticsPurchaseEvent` with `productId`, `productName`, `value`, `currency`, `quantity`, and optional `transactionId`; `AppAnalytics.logPurchaseRevenue(event)`.

- [x] Implement `AppAnalytics.logPurchaseRevenue` with Firebase Analytics `logPurchase`, including `transactionId` when Google Play provides a purchase ID.
- [x] Skip an event when its price is not positive or its currency code is empty.
- [x] In the controller’s confirmed purchase path, find the matching loaded option and report its `rawPrice`, `currencyCode`, product ID/title, quantity 1, and purchase ID.
- [x] Ensure Analytics errors are caught and reported as nonfatal without interrupting Pro entitlement persistence or Play purchase completion.
- [x] Keep restored, pending, canceled, and error updates out of the revenue logger.

### Task 4: Verify the Android integration

**Files:**
- No additional source files.

**Interfaces:**
- Consumes: Android Firebase configuration and implementation from Tasks 1–3.
- Produces: Evidence that configuration, Dart integration, and Android Gradle wiring are valid.

- [x] Run `flutter analyze` and resolve issues introduced by the integration.
- [x] Run `flutter build apk --debug` and resolve configuration or compile failures.
- [x] Run `firebase apps:list --project toki-0001` and confirm the registered package is `com.appylab.syncfocus`.
- [x] Do not add or run Flutter tests.
