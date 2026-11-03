# Superseded: Sync Focus Pro Paywall Design

> Superseded on 2026-11-03 by [Sync Focus Yearly and Lifetime Pro Options](2026-11-03-sync-focus-yearly-lifetime-design.md). This document records the original Monthly-only checkout and is historical context; use the newer specification for current plan IDs, pricing, purchase behavior, and paywall requirements.

## Intent

Replace the current short, informational “Explore Pro” sheet with a purchase-ready paywall that follows Sync Spend’s paywall layout. Sync Focus keeps its own circular logo, feature descriptions, and its established monthly Google Play subscription.

## Goals

- Match Sync Spend’s tall rounded sheet, hero treatment, scrollable benefits, fixed checkout footer, close control, and dark/light presentation.
- Show the localized monthly price and subscription terms supplied by Google Play, plus purchase, restore, privacy, and Play payment disclosure controls.
- Complete subscription purchase and restore through Flutter’s `in_app_purchase` plugin, selecting the configured Sync Focus offer.
- Represent loading, unavailable, pending, canceled, failed, restored, and active purchase states in the paywall.
- Keep Sync Focus’s existing Pro benefit copy, branding, and global color scheme. Do not introduce gold accents or beige textures from Sync Spend.

## Constraints and non-goals

- Keep the current product contract: product ID `syncfocus_pro`, base plan ID `01-syncfocus-pro`, monthly renewal, cancelable through Google Play.
- Use Google Play’s localized product price and active purchase query as the entitlement source. Pending or failed purchases do not unlock Pro. An authoritative query with no active subscription clears a cached Pro status; a query error does not.
- Use the current Sync Focus privacy policy URL and link to existing terms where the subscription disclosure needs it.
- Do not change the app ID, add a lifetime product, modify native Kotlin billing, add receipt verification servers, or implement unrelated Pro feature gates in this change.
- The app already depends on `shared_preferences` and `url_launcher`; add `in_app_purchase` and its Android implementation because the Flutter app has no billing bridge and the selected implementation is the Flutter plugin.

## Approaches

1. **Flutter `in_app_purchase` plugin — selected by the user.** Keep the subscription flow and state in Dart, use the Android package to select the configured base-plan offer, and keep the sheet integrated with the existing Flutter settings flow. This fits the Flutter rebuild and matches the approach already used in Sync Spend.
2. **Kotlin BillingClient through a platform channel.** Reuse the existing Kotlin billing manager and its product contract, but add and maintain a Dart/native channel for catalog, purchase, restore, and state updates. This keeps billing native and adds more cross-language plumbing.

## Design decisions

- The paywall opens from existing Pro entry points in Settings.
- Use Sync Spend’s 90%-height rounded sheet, scrollable hero and benefit area, pinned checkout section, and floating close button. The footer presents the monthly plan, localized price, primary subscribe action, restore action, Play billing disclosure, and policy link.
- Resolve the offer using the existing Kotlin behavior: prefer an offer for base plan `01-syncfocus-pro`, falling back to the first Play offer only when no matching base-plan offer is returned. Display the selected offer’s store-provided localized pricing phases and recurring terms.
- When Play confirms an active subscription, show the existing Kotlin success state (“You’re Pro!” / “Start focusing”) instead of offering checkout again.
- Use Sync Focus’s circular logo and current Pro benefits: Focus Guard, custom task tags, longer-range progress, focus sound options, and AMOLED appearance. Use Hugeicons already registered in the app.
- Use Sync Focus’s existing light/dark palette tokens for the hero, benefit icons, plan selection, controls, and checkout footer. Use the app’s blue accent and black/white primary button treatment; do not add paywall-specific colors or copied textures.
- Add a `ProBillingController` and a Google Play billing service under `lib/features/pro/`. The controller listens to purchase updates, loads the product at app startup, reconciles active ownership, persists a local status cache, acknowledges/completes purchases, and exposes actionable status to the paywall.
- Keep this change scoped to the paywall and its purchase state. The existing screens’ separate Pro feature enforcement remains unchanged.

## Acceptance

- The Settings Pro entry point shows the matching paywall in light and dark themes, with scrollable benefits and a fixed checkout footer.
- The Google Play catalog is queried for `syncfocus_pro`; checkout prefers the `01-syncfocus-pro` offer and displays its localized pricing and recurring terms.
- Purchase and restore results update the visible Pro state; pending, errors, unavailable billing, and no active subscription are handled without falsely granting access.
- The current Sync Focus logo, palette, typography, and policy destinations remain consistent with the app.
