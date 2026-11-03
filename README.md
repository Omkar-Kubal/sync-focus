# Sync Focus

Sync Focus is a Flutter focus timer with Android timer notifications, home-screen widgets, Focus Guard, Do Not Disturb automation, task planning, and progress tracking.

## Enable Pro features in a debug build

Use the `SYNC_FOCUS_PRO` Dart define to exercise Pro-only screens and behavior without a Google Play purchase:

```powershell
flutter run --dart-define=SYNC_FOCUS_PRO=true
flutter build apk --debug --dart-define=SYNC_FOCUS_PRO=true
```

The flag defaults to `false` and only grants test access in debug builds. It does not save or change the Play entitlement, and release builds ignore it. The Pro checkout identifies the override as test access. Omit the define to use normal billing behavior.
