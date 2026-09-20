# Flutter migration

The active application is now the Flutter project at the repository root. Android and iOS hosts remain native where required, while UI, state, networking, Link models, and connection logic are shared in Dart.

The previous Kotlin/Compose and Swift/SwiftUI trees are preserved in `legacy/android-native` and `legacy/ios-native`. This keeps all committed and uncommitted work available while parity is verified. They are not built by the active CI workflow.

## Implemented parity

- onboarding and English/Russian localization;
- manual and QR server setup;
- URL and TLS policy;
- Link info parsing and protocol rejection;
- pairing approval, device identity, secure credential storage, and profiles;
- foreground presence, notification events, disconnect, and revoke;
- multiple saved HomePlace profiles with identity-checked switching;
- opt-in Android periodic background notification delivery;
- encrypted notification history and background-run diagnostics;
- unit, controller, widget, and mock-server tests.

## Remaining platform work

- real-device Android end-to-end pairing and notification validation;
- instant Android push or WebSocket transport after the server exposes realtime support;
- real-device iOS pairing and notification validation;
- iOS background behavior within platform limits;
- Share Sheet and Share Extension integration;
- local-network discovery after the server publishes a canonical discovery contract.
