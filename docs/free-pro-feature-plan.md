# Sync Focus: Free and Pro feature plan

Status: recommended product split for the Flutter rebuild. This is a feature plan, not a claim that every Flutter feature is implemented.

Progress implementation note (2026-11-02): the 30/90-day local focus trend and tag breakdown now render from saved session records. Older records without a tag are grouped under Focus. Subscription entitlement gating, custom tag creation, and full searchable session history are still unimplemented.

## Product rule

Free users can complete the full focus loop: plan a task, run a reliable timer, take a break, and see progress. Pro adds stronger distraction control, richer organization and review, extra sounds, and optional cloud backup. Reliability, accessibility, privacy controls, and recovery are never subscription benefits.

## Feature separation

| Area | Free | Pro |
| --- | --- | --- |
| Focus timer | Unlimited sessions; 5–240 minute custom durations, presets, Flow mode, pause/resume/stop, and breaks | Same core timer |
| Session reliability | Foreground timer, notification controls, boot recovery, and home-screen widget on supported Android devices | Same reliability |
| Tasks | Up to **10 active tasks**; dates, notes, completion, and timer links; completed tasks stay visible | Unlimited active tasks |
| Tags | Built-in Focus tag and existing tags remain usable | Create and manage custom tags |
| Ambient audio | Silence, Rain, White Noise; volume control | Coffee Shop, Ocean Waves, Fireplace, Forest, Brown Noise, Library, plus Free sounds |
| Distraction controls | Manual focus mode and optional Do Not Disturb where supported | Focus Guard app blocking, blocked-app list, and related permission setup on Android |
| Progress | Current 7-day chart, daily totals, streak, achievements, and five recent sessions | 30/90-day trends with tag breakdown; full searchable session history remains planned |
| Backup and export | All sessions remain stored locally; data deletion controls must be available to everyone before cloud launch | Cloud backup/restore of **focus sessions** and CSV session export |
| Appearance | Light/dark theme and accessibility settings | AMOLED pure-black theme |

### Boundary details

- The 10-task cap counts active, incomplete tasks across both task entry points. Completing or deleting a task frees a slot. Existing tasks remain readable and editable after Pro expires; only creating another task beyond the Free cap is blocked.
- The timer duration must be consistent between Home and the task editor. The Android Home screen already permits 5–240 minutes without a Pro check, while the task editor locks its 60-minute preset. The Flutter build should make the full range Free in both places.
- Local sessions are never deleted or stopped when a subscription ends. Pro history views, cloud sync, custom-tag creation, and premium sound selection lock at expiry; existing local records and tag labels remain intact.
- Focus Guard requires Android platform code and special permissions even though its UI is Flutter. Do not promise equivalent app blocking on iOS. Show platform availability before purchase.
- The current cloud repository backs up session records. Do not describe it as full task/settings/device sync unless that scope is implemented and tested.
- The old Android app does not expose its promised cloud-deletion action. Add and verify a deletion flow for any cloud data and anonymous account before offering cloud backup in Flutter; never put deletion behind Pro.
- Do not advertise full searchable history in the paywall until its Flutter screen and queries exist. The 30/90-day trend and tag breakdown now have local queries; subscription entitlement gating still needs to be connected before release. The current Android Insights screen already exposes the 7-day chart, streak, badges, and five recent sessions to Free users.
- Replace the vague “All future Pro features” claim with the exact benefits available at purchase time. Show the store-provided localized price, billing period, renewal terms, and restore/manage subscription actions.

## Upgrade moments

1. **Focus Guard:** Let users view a short explanation and supported-platform note. Present Pro before requesting Usage Access and overlay permissions. After purchase, guide through permissions.
2. **Task limit:** At 10 active tasks, explain “Complete a task to make room, or get Pro for unlimited active tasks.” Never interrupt an active timer.
3. **Premium sounds:** Allow a short preview, then show which sound requires Pro. Keep Rain and White Noise selectable.
4. **History and export:** Show the Free weekly chart and recent sessions first. Offer Pro when the user opens older history or requests CSV.
5. **Settings:** Keep a single Pro section with concrete benefits. No paywall on launch or immediately after a focus session.

## Flutter implementation order

1. Define one entitlement and feature-policy layer used by Home, Tasks, Sounds, Insights, Settings, and platform bridges. Implement the 10-active-task rule at the data/use-case boundary, not only in the UI.
2. Port and verify the Free focus loop and Android reliability features first: timer service, notification actions, boot recovery, widget, local tasks, breaks, and weekly progress.
3. Add Pro features behind the same policy: sounds, custom tags, AMOLED, Focus Guard, session cloud backup/restore, and CSV export. Keep purchase state in sync with the store, including expiry and restore.
4. Build full history and 30/90-day insights before adding them to Pro marketing. Define their queries and empty states separately from the existing Free weekly view.
5. Verify purchase, cancellation/expiry, offline recovery, task-cap edge cases, Android special-permission denial, backup/restore, cloud-data deletion, and widget/boot behavior before release. Update paywall, store listing, and privacy copy to match the shipped features.

## Source discrepancies to resolve

- Android `TaskViewModel` allows 10 active Free tasks; `TaskSheet` allows 3. This plan chooses **10** as the single limit.
- Android Home permits up to 4-hour sessions without a paywall; the task editor gates its 60-minute preset. This plan makes duration Free everywhere.
- The existing Pro sheet promises “Expanded insights and history,” but those Pro views are not present in the current Android Insights screen. Treat them as a build requirement before using that claim.
- The prior QA report found subscription-entitlement and cloud-deletion issues. These are release gates for the Flutter Pro experience.
