# Sync Focus Android Firebase Integration

## Intent

Add Android crash reporting and Pro purchase revenue analytics to Sync Focus using the existing Firebase project **Toki** (`toki-0001`), following the integration already used by Sync Spend.

## Goals

- Register `com.appylab.syncfocus` as a separate Android app in Toki and generate app-specific Firebase configuration.
- Initialize Firebase at startup and report uncaught Flutter, platform, and asynchronous errors to Crashlytics.
- Log Google Play purchase revenue to Firebase Analytics for confirmed new Yearly and Lifetime purchases, using the product’s numeric price, currency, ID, and transaction ID when available.
- Keep Firebase initialization and analytics failures from blocking app startup or purchase completion.

## Non-goals and constraints

- Configure Android only. Do not register or configure the iOS target.
- Do not change Google Play product IDs, billing flows, entitlement rules, or add a server-side receipt service.
- Do not log restores, pending purchases, cancellations, or failures as revenue.
- Firebase project access is expected through the user’s authenticated Firebase CLI session. The Firebase app ID and generated config must come from Toki; Sync Spend’s `google-services.json` cannot be reused because it contains different Android package registrations.
- No custom route screen tracker is included. Sync Focus currently uses one app route with modal sheets; this work adds Firebase’s standard app analytics and purchase revenue events.

## Approaches

1. **Mirror Sync Spend’s Firebase SDK setup in Toki — selected by the user.** Add Firebase Core, Crashlytics, and Analytics; configure the Android Gradle plugins and app-specific Firebase options; capture global errors; and log confirmed Pro purchase revenue. This matches the requested reference project and current Android billing flow.
2. **Add Crashlytics only.** This would report crashes but leave revenue tracking out of the Firebase project, so it does not meet the request.
3. **Adopt a separate purchase analytics service.** This adds another provider and billing integration without benefit over the Firebase Analytics pattern already present in Sync Spend.

## Implementation and verification

- Add compatible Flutter Firebase dependencies and the Google Services / Crashlytics Gradle plugins used by Sync Spend.
- Use FlutterFire configuration for project `toki-0001` and package `com.appylab.syncfocus`, producing `android/app/google-services.json`, `firebase.json`, and Android options in `lib/firebase_options.dart`.
- Add a CrashReporter bootstrap matching Sync Spend’s global Flutter, platform, and zone error capture.
- Add an Analytics purchase event helper and call it only for a confirmed purchase update, using Google Play product metadata; do not log restored ownership as a new sale.
- After CLI sign-in and configuration, verify that the registered Android app belongs to Toki, then run Dart analysis and an Android debug build. No tests are added or run as part of this change.
