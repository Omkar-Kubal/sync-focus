# Sync Focus Yearly and Lifetime Pro Options

## Intent

Offer new buyers Yearly Pro and a one-time Lifetime purchase. Keep the existing monthly plan's entitlement valid for people who already own it.

## Goals

- Replace the Monthly checkout choice with Yearly and Lifetime choices.
- Use localized prices and product details returned by Google Play; do not hardcode regional prices.
- Treat a confirmed purchase of either new option or the existing monthly plan as Pro.
- Keep restore working for existing monthly subscribers and owners of either new option.
- Preserve the existing Sync Focus paywall layout, color scheme, privacy and terms links, and pinned checkout area.

## Non-goals

- Do not remove, rename, or change the price of the existing monthly plan.
- Do not change Pro feature gates or introduce a server-side receipt service.
- Do not create or publish products in Google Play Console from this code change.

## Constraints and product IDs

- Existing subscription product: `syncfocus_pro`; existing monthly base plan: `01-syncfocus-pro`.
- Add the yearly subscription as base plan `02-syncfocus-pro-yearly` under `syncfocus_pro`.
- Add Lifetime as a one-time, non-consumable Google Play product `syncfocus_pro_lifetime`.
- Google Play Console must have the new base plan and one-time product configured before live localized prices and purchases are available.
- Use Google Play's localized prices; do not hardcode an amount, currency, or savings claim. Do not show a price when Play has not returned that product or offer.
- Yearly copy states that the plan auto-renews every year and can be canceled in Google Play. Lifetime copy states that it is a one-time payment and does not renew.
- Existing Monthly subscribers keep Pro access and remain restorable through product ID `syncfocus_pro`; Monthly is not offered to new buyers.

## Approaches

1. **Show Yearly and Lifetime; retain monthly ownership — selected by the user.** Add a yearly base plan to the existing subscription product and a separate one-time product. This presents the requested two choices without invalidating existing monthly subscribers.
2. **Show Monthly, Yearly, and Lifetime.** This preserves the current checkout choice for new buyers, but the user selected a two-choice paywall.
3. **Create a separate yearly subscription product.** This duplicates the subscription product and complicates ownership and subscription transitions without adding a user benefit, so keep yearly on the existing subscription product as another base plan.

## Interaction and billing behavior

- The paywall presents two clearly selectable cards: Yearly and Lifetime. Yearly is selected initially; the Lifetime card explicitly says “one-time purchase.”
- The checkout button and pricing disclosure follow the selected plan. A Play-provided price is shown only when that product or offer is available.
- Yearly price is presented per year with annual renewal terms. Lifetime price is presented as a one-time payment with no renewal.
- A confirmed or restored purchase of the yearly base plan, lifetime product, or existing monthly subscription unlocks Pro. Pending, canceled, and failed purchases do not.
- Restore checks all three product identifiers. An authoritative result with no active purchase clears the cached entitlement; an ownership-query error retains the current behavior and cached entitlement.
- If the yearly offer or lifetime product is not configured or unavailable, the other available choice remains usable and the unavailable choice is clearly disabled.
- Existing active Pro access continues to show a generic Pro access state rather than incorrectly labeling lifetime ownership as a subscription.

## Implementation and verification

- Extend the Pro billing service/controller to load both new purchase choices, start the correct Google Play flow for each, and recognize ownership and purchase updates for the existing monthly ID plus both new choices.
- Update the paywall checkout area to render the two options and selection-specific terms while retaining the existing visual system and pinned footer.
- Add tests for plan selection, localized product availability, yearly and lifetime purchase routing, pending/error handling, lifetime and legacy-monthly restore, and the two-option paywall.
- Verify the Free and Pro-flagged Flutter suites, analyzer, Android debug build, and emulator paywall presentation. Live billing requires the new products to be configured and tested in Google Play.
