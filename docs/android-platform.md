# Android platform integration

The Android application targets API 36 (Android 16). System integrations are
implemented in Kotlin when Flutter cannot provide the same platform behavior.
They do not add HomePlace Link capabilities or bypass account permissions.

| Integration | Current behavior | User control |
| --- | --- | --- |
| One UI / Android Quick Settings | An optional Transfers tile opens the existing transfer screen after the normal connection restoration. | Add it from in-app settings on Android 13+, or manually in the Quick Settings editor on older devices. Sending still requires recipient selection and confirmation. |
| Notifications | Incoming offers have Accept and Decline actions; received notification contents use private lock-screen visibility. | Android notification settings are reachable from in-app settings. Background delivery and offers remain opt-in. |
| Display and touch | Android can select the highest supported refresh mode at the current resolution; primary navigation gives a small system haptic selection cue. | Device display and haptic settings still govern actual behavior. |
| Photos and icons | Plant photos use the platform-backed image picker. The launcher has adaptive and monochrome icon resources for themed icons. | No broad media-library permission is requested. |
| Android 16 | The app targets API 36 and uses system-managed edge-to-edge layout and back behavior through Flutter. | The phone app requests portrait orientation so it does not rotate with the device; Android may override this in large-screen windowing modes. |

The tile is only a navigation affordance. It never shows private transfer data
on the lock screen, starts a transfer, or accepts an incoming offer. The tile
request is initiated only by a user tap in settings, and its result is reported
without assuming One UI accepted it.

## Android 17 upgrade gate

Do not raise `targetSdk` to 37 until the Android 17 local-network protection
flow is implemented and tested. Apps targeting API 37 need the
`ACCESS_LOCAL_NETWORK` runtime permission for direct LAN access. HomePlace
needs to explain that permission before requesting it for local hostname/IP
setup and discovery, while public HTTPS domains must continue to work without
it. Denial must produce an actionable local-network error, not an endless
connection spinner. Re-test QR setup, reconnect, background delivery, and
self-signed certificate confirmation on API 37. Review Android 17 certificate
transparency defaults against the existing explicit certificate policy.

Android 16 progress-centric notifications are reserved for a transfer pipeline
that can report real byte progress. A timer or an indeterminate placeholder
must not be presented as download progress.

Platform references: [Android 16 features](https://developer.android.com/about/versions/16/features),
[Android 16 behavior changes](https://developer.android.com/about/versions/16/behavior-changes-16),
and [Android 17 behavior changes](https://developer.android.com/about/versions/17/behavior-changes-17).
