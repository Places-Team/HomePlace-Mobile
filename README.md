# HomePlace Mobile

The Flutter application for connecting Android and iOS devices to a self-hosted HomePlace server. The user-facing name on both platforms is **HomePlace**.

## Current milestone

The first Flutter connection slice is implemented and validated on Android and the iOS Simulator. It includes:

- English and Russian onboarding;
- domain, local hostname, IPv4, IPv6, and QR address input;
- strict URL normalization and local HTTP warnings;
- `/api/link/info` compatibility and server identity validation;
- explicit self-signed certificate fingerprint confirmation;
- pairing approval and secure device credentials;
- capability negotiation, foreground heartbeat, event acknowledgement, and test notifications;
- saved connection profiles, diagnostics, revoke, and disconnect actions.

Presence currently operates while the application is open. Persistent platform background delivery remains a later native-integration milestone.

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

## Project rules

- The HomePlace server repository is canonical for Link protocol and API behavior.
- Public hostnames require HTTPS. HTTP is restricted to loopback and private local-network addresses.
- Invalid TLS certificates are never silently accepted.
- Private keys and tokens remain in platform-secure storage and are never logged.
- Capabilities describe only functionality that is implemented and available on the current device.
- Never commit credentials, signing material, provisioning profiles, or environment-specific configuration.

Read [Architecture](docs/architecture.md), [Security](docs/security.md), [HomePlace Link](docs/homeplace-link.md), and [Development](docs/development.md) before changing connection behavior.
