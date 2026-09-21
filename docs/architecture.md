# Architecture

HomePlace Mobile uses one Flutter application for Android and iOS. Shared Dart code owns product UI and Link behavior; Kotlin and Swift own security and system integration that cannot be represented faithfully as shared application logic.

## Layers

1. `lib/main.dart` and `lib/features/` own localized UI, the finite connection state machine, the mobile dashboard state, and the four-tab navigation shell.
2. `lib/link/` owns client-side models, compatibility checks, pairing, heartbeat, authenticated mobile actions, and event transport.
3. `lib/core/network/` owns address normalization and connection security classification.
4. `lib/core/storage/` separates non-secret connection profile metadata from credentials.
5. `android/` and `ios/` expose native identity keys and platform services through narrow Flutter channels and plugins.

The HomePlace server remains canonical for Link schemas and endpoint behavior. Mobile models intentionally validate only the subset required by the supported protocol version.

## Connection state

`welcome → address → validating → preview → pairing → connected`

Network requests have bounded timeouts and explicit error paths. Pairing secrets exist only for the short pairing session. A persisted profile records the server ID, URL, device ID, security state, and optional certificate fingerprint; its credential is stored separately.

On reconnect, the client requests `/api/link/info` before using the saved credential and stops if the server ID differs. Foreground heartbeat delivers allowlisted events and acknowledges their IDs on the next request.

After pairing, `HomeController` reads the authenticated mobile overview and refreshes it every 30 seconds while the application is open. Calendar, reminders, media requests, Telegram, and monitoring reuse server-owned services and models. Reminder history includes upcoming, overdue, and completed items; every mutation remains scoped to the paired user's ID on the server. The app does not keep a competing local source of truth.

On Android, `ACTION_SEND` and `ACTION_SEND_MULTIPLE` intents are reduced to bounded text, HTTP(S) URLs, or private cache files. A batch contains at most ten items and 500 MB total. Shared Dart UI queues every item in the transfer center, filters the server-provided authorized device list by real receiver capability, identifies household targets, and requires an explicit named recipient and confirmation before upload. Successfully sent items leave the queue; a failed item and everything after it remain available for retry. The receiving device accepts or declines each server offer from the transfer center or private notification actions. Files up to 500 MB are streamed in both directions. Android creates the destination temporary file inside the application's canonical cache directory before Flutter downloads into it; exact size and SHA-256 are verified before the Android host copies it to `Downloads/HomePlace`. The event is acknowledged only after that save succeeds. An opt-in foreground-only seamless path can request this acceptance automatically only when the canonical server marks both devices as belonging to the same account.

## Native boundaries

- Android generates a P-256 identity key in Android Keystore. Narrow Kotlin channels perform foreground clipboard access, Share Sheet ingestion, safe URL opening, and confirmed file saving. Opt-in WorkManager jobs periodically validate each server and deliver notification events without processing clipboard, link, or file offers.
- iOS generates a P-256 identity key in Keychain. Notification, a future Share Extension, and permitted background behavior remain iOS-specific. The current iOS build does not advertise sharing capabilities.
- Shared code never claims unrestricted background execution, arbitrary app launching, or remote system control. Android clipboard relay is foreground-only and incoming text requires an explicit copy action. iOS does not advertise clipboard relay.

## Migration policy

The former native applications are preserved under `legacy/`. They are reference implementations, not build targets. Remove a legacy feature only after the Flutter equivalent has been implemented, covered by appropriate tests, and reviewed on its real platform.
