# HomePlace Mobile

The Flutter application for connecting Android and iOS devices to a self-hosted HomePlace server. The user-facing name on both platforms is **HomePlace**.

## Current milestone

The first Flutter application slice is implemented with Android as the primary validation target. It includes:

- English and Russian onboarding;
- domain, local hostname, IPv4, IPv6, and QR address input;
- strict URL normalization and local HTTP warnings;
- `/api/link/info` compatibility and server identity validation;
- explicit self-signed certificate fingerprint confirmation;
- pairing approval and secure device credentials;
- capability negotiation, foreground heartbeat, event acknowledgement, and test notifications;
- multiple saved connection profiles with server identity checks, diagnostics, revoke, and disconnect actions;
- a four-tab pill navigation shell for home, plans, media requests, and monitoring;
- Google Calendar agenda and full reminder management: upcoming, overdue and completed sections, create, edit, repeat, complete, restore and confirmed deletion;
- Sonarr/Radarr search and requests, qBittorrent status, Telegram status and a delivery check;
- compact service health and recent-event monitoring;
- explicit Android clipboard relay with foreground reads and confirmation before an incoming value is copied;
- Android Share Sheet support for text, safe web links, and streamed files up to 500 MB, with an explicit recipient and send confirmation;
- private same-account or explicitly enabled household delivery, five-minute offers, encrypted temporary server storage, Accept/Decline notification actions, transfer progress, cancellation, and SHA-256 verification;
- a dedicated transfer center for all pending incoming offers, queued outgoing items, retryable failures, and encrypted per-profile history;
- Android multi-file Share Sheet intake for up to ten items and 500 MB per batch, followed by one explicit device selection and confirmation;
- opt-in Android background notification checks through WorkManager, with server identity validation on every run;
- encrypted per-profile notification history and visible background-check diagnostics;
- opt-in background discovery of incoming clipboard, text, link and file offers, with private Android notifications and foreground confirmation;
- opt-in seamless saving for integrity-checked files sent by another device owned by the same account while the app is open;
- bounded incoming and outgoing queues so concurrent files and links remain independently reviewable.

Foreground presence and clipboard relay operate while the application is open. Android can periodically check for notifications and incoming share offers in the background, but Android controls the timing and may defer the 15-minute schedule. Private notifications provide Accept and Decline actions; accepting a file brings HomePlace forward to complete its verified download and system save. The optional seamless mode applies only to files from another device with the same server-verified account and only while HomePlace is open. Household files, links, text, and clipboard always require a specific action. Android does not permit ordinary applications to read the system clipboard while they are in the background. Instant server push, realtime presence, and an iOS Share Extension remain later native-integration milestones. iOS does not advertise clipboard or sharing capabilities in this milestone.

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

Read [Architecture](docs/architecture.md), [Security](docs/security.md), [HomePlace Link](docs/homeplace-link.md), and [Development](docs/development.md) before changing connection behavior.
