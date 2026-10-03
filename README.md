# HomePlace Mobile

The Flutter application for connecting Android and iOS devices to a self-hosted HomePlace server. The user-facing name on both platforms is **HomePlace**.

## Current milestone

On Android, choosing HomePlace from another app's Share Sheet opens a compact, translucent recipient picker over that app. The saved connection restores without first showing HomePlace's main screen. Sending still requires a recipient and explicit confirmation. Closing the picker returns to the source app. Incoming file acceptance and rejection are available from Android notifications; optional background checks follow Android's scheduling and are not instant delivery.

Transfers include account-only temporary text links through the server's
`/api/exchange` API. They can expire after 10 minutes, one hour, or one day,
optionally disappear after the first open, and be revoked from the phone.
Direct device offers remain separate. This requires the paired device's
`share.relay` permission. File exchange accepts any file type within the
connected server's current `/api/link/info` upload limit, streams the upload
with progress and cancellation,
and defaults to account-only access. Creating an external link requires a
second confirmation. Android can inspect a link from the connected server,
confirm the download, verify its SHA-256 digest, save it to Downloads, and open
the saved file. A one-time download cannot be resumed after interruption.
Upload and download run while the app is open; background exchange is not yet
available. Older servers without a reported limit retain a 500 MiB fallback.
Reverse proxies may impose a lower upload limit.
Quick one-time file links use a five-character code and expire after 10 minutes;
the server makes them public and consumes them when downloading starts. Ordinary
account-only and longer-lived links remain available separately.
Recipients can enter a quick code or `/f` link in the mobile app, or use the
server's `/f` page. The app resolves only same-server codes and requires
explicit confirmation before downloading.

The Media requests tab browses the paired server's Seerr catalog in English or
Russian, filters films, series, and anime, and opens details with season and
quality-profile selection. Creating a request requires an explicit tap and the
device's `media.request` permission. The prior Sonarr/Radarr search and queue
view remains available in a collapsible section. Catalog images are fetched
only from approved paths on the paired server with the device credential;
external image URLs are ignored.

Android 16 support now includes an optional Quick Settings Transfers tile,
system notification-settings access, private notification visibility, and
subtle system haptics in navigation. See [Android platform integration](docs/android-platform.md)
for the implemented One UI/Android behavior and the Android 17 permission gate.

Plans includes an Ideas workspace based on Desktop's quick-capture flow:
notes, categories, editing, duplication, deletion, and explicit handoff to
the server-backed reminder editor. Ideas use the account-scoped
`/api/link/ideas` API when the paired device has `ideas.manage`. Older
pairings keep their secure device-local ideas until access is granted.
The user can then confirm an idempotent import; phone copies remain intact.
Synced ideas show and edit Desktop notes, pinning, completion, and archive. Advanced
controls are unavailable for device-local ideas until account access is granted.
Android launcher shortcuts can open Ideas and Transfers after the normal
connection flow; neither shortcut bypasses confirmation.

The first Flutter application slice is implemented with Android as the primary validation target. It includes:

- English and Russian onboarding;
- domain, local hostname, IPv4, IPv6, and QR address input;
- strict URL normalization and local HTTP warnings;
- `/api/link/info` compatibility and server identity validation;
- explicit self-signed certificate fingerprint confirmation;
- pairing approval and secure device credentials;
- capability negotiation, foreground heartbeat, event acknowledgement, and test notifications;
- multiple saved connection profiles with server identity checks, diagnostics, revoke, and disconnect actions;
- a five-tab pill navigation shell for home, plans, media requests, transfers, and monitoring;
- local plant care on Home and Plans: editable photo cards, flexible 1–90 day watering intervals, due and overdue states, and a one-tap watering action;
- an "All sections" workspace map inspired by the server and desktop information architecture, with live routes for implemented modules and clearly labelled previews for automations and smart-home controls that still require server APIs;
- dedicated mobile views for share-capable devices, encrypted notification history, approved permissions, server identity, account isolation, and connection security;
- Google Calendar agenda and full reminder management: upcoming, overdue and completed sections, create, edit, repeat, complete, restore and confirmed deletion;
- Sonarr/Radarr search and requests, qBittorrent status, Telegram status and a delivery check;
- compact service health and recent-event monitoring;
- explicit Android clipboard relay with foreground reads and confirmation before an incoming value is copied;
- Android Share Sheet support for text, safe web links, and streamed files up to 500 MB, with an explicit recipient and send confirmation;
- private same-account or explicitly enabled household delivery, 30-minute addressed offers, encrypted temporary server storage, Accept/Decline notification actions, transfer progress, cancellation, and SHA-256 verification;
- confirmed Android downloads saved through MediaStore with an immediate system Open action and one-time server acknowledgement;
- a dedicated transfer center for all pending incoming offers, queued outgoing items, retryable failures, and encrypted per-profile history;
- exactly-once Android Share Sheet intake for up to ten items and 500 MB per batch, opening directly on device selection and confirmation;
- a four-view Control area that separates monitored service checks from Docker containers and shows health, host, state, latency, and recent events;
- non-blocking error indicators in the top bar with details available on demand;
- opt-in Android background notification checks through WorkManager, with server identity validation on every run;
- encrypted per-profile notification history and visible background-check diagnostics;
- opt-in background discovery of incoming clipboard, text, link and file offers, with private Android notifications and explicit acceptance;
- confirmed Android files download and save through a headless WorkManager engine without opening the application; failed work remains queued for a safe retry and is acknowledged only after MediaStore succeeds;
- opt-in seamless saving for integrity-checked files sent by another device owned by the same account, including during enabled Android background checks;
- bounded incoming and outgoing queues so concurrent files and links remain independently reviewable.

Saved connections reopen automatically. If a server is temporarily unavailable, HomePlace keeps the saved profile and offers a retry without asking for the address again. Plant cards can sync through `/api/link/plants` when the paired device has `plants.manage`. Existing local cards remain on the device until the user explicitly imports them; original records and photos are preserved. New shared cards, edits, watering and deletion use revision-aware sync with a durable offline queue and conflict controls. Photos remain local. Watering dates appear in Home and Plans; scheduled system watering alerts are not implemented yet.

Foreground presence and clipboard relay operate while the application is open. Android can periodically check for notifications and incoming share offers in the background, but Android controls the timing and may defer the 15-minute schedule or an immediate queued task. Private notifications provide Accept and Decline actions; accepting a file queues a headless verified download and MediaStore save without opening the Flutter interface. The optional seamless mode applies only to files from another device with the same server-verified account; when background checks are enabled, those files can also be saved by the worker. Household files, links, text, and clipboard always require a specific action. Android does not permit ordinary applications to read the system clipboard while they are in the background. The Android activity requests the highest refresh mode available at the current resolution, while the operating system retains final control under adaptive refresh and power-saving policies. Instant server push, realtime presence, and an iOS Share Extension remain later native-integration milestones. iOS does not advertise clipboard or sharing capabilities in this milestone.

Plant synchronization now supports private photos, opt-in import of existing
photos, separate watering actions, and configurable HomePlace/Telegram reminder
delivery. See [plant synchronization](docs/plant-sync.md) for privacy and
conflict behavior.

## Repository layout

- `lib/` — shared Flutter UI, state, networking, Link models, and application logic.
- `android/` — Android host and Android Keystore integration.
- `ios/` — iOS host and Keychain integration.
- `test/` — unit, state, widget, and mock-server integration tests.
- `docs/` — architecture, security, Link dependency, migration, and development notes.
- `legacy/` — preserved native implementations used to verify migration parity.
- `scripts/` — repository validation helpers.

## Requirements

- Flutter 3.47.4 or a compatible stable release;
- Android Studio, JDK 17, Android SDK 36 for compilation, and Android SDK 35 as the target;
- Xcode 26 or newer and CocoaPods for iOS development.

## Build and test

```sh
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --no-codesign
```

The Android test package is written to `build/app/outputs/flutter-apk/app-debug.apk`.
Install subsequent local builds with `adb install -r` and keep using the same
development machine or signing key. Android intentionally rejects an update
signed by a different key; switching from a CI/debug signer to a release signer
requires one uninstall. Never commit the signing key to this repository.

## Project rules

- The HomePlace server repository is canonical for Link protocol and API behavior.
- Public hostnames require HTTPS. HTTP is restricted to loopback and private local-network addresses.
- Invalid TLS certificates are never silently accepted.
- Private keys and tokens remain in platform-secure storage and are never logged.
- Capabilities describe only functionality that is implemented and available on the current device.
- Never commit credentials, signing material, provisioning profiles, or environment-specific configuration.

Read [Architecture](docs/architecture.md), [Mobile experience map](docs/mobile-experience-map.md), [Security](docs/security.md), [HomePlace Link](docs/homeplace-link.md), and [Development](docs/development.md) before changing connection behavior.
