# Architecture

HomePlace Mobile uses one Flutter application for Android and iOS. Shared Dart code owns product UI and Link behavior; Kotlin and Swift own security and system integration that cannot be represented faithfully as shared application logic.

## Layers

1. `lib/main.dart` and `lib/features/` own localized UI and the finite connection state machine.
2. `lib/link/` owns client-side models, compatibility checks, pairing, heartbeat, and event transport.
3. `lib/core/network/` owns address normalization and connection security classification.
4. `lib/core/storage/` separates non-secret connection profile metadata from credentials.
5. `android/` and `ios/` expose native identity keys and platform services through narrow Flutter channels and plugins.

The HomePlace server remains canonical for Link schemas and endpoint behavior. Mobile models intentionally validate only the subset required by the supported protocol version.

## Connection state

`welcome → address → validating → preview → pairing → connected`

Network requests have bounded timeouts and explicit error paths. Pairing secrets exist only for the short pairing session. A persisted profile records the server ID, URL, device ID, security state, and optional certificate fingerprint; its credential is stored separately.

On reconnect, the client requests `/api/link/info` before using the saved credential and stops if the server ID differs. Foreground heartbeat delivers allowlisted events and acknowledges their IDs on the next request.

## Native boundaries

- Android generates a P-256 identity key in Android Keystore. Notification, QR camera, and future foreground-service work remain Android-specific.
- iOS generates a P-256 identity key in Keychain. Notification, Share Extension, and permitted background behavior remain iOS-specific.
- Shared code never claims unrestricted background execution, clipboard access, arbitrary app launching, or remote system control.

## Migration policy

The former native applications are preserved under `legacy/`. They are reference implementations, not build targets. Remove a legacy feature only after the Flutter equivalent has been implemented, covered by appropriate tests, and reviewed on its real platform.
