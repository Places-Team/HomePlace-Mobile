# HomePlace Mobile

Native Android and iOS applications for connecting a phone or tablet to a
self-hosted HomePlace server.

The user-facing application name on both platforms is **HomePlace**. The two
applications keep their interfaces and operating-system integrations native,
while sharing the HomePlace Link terminology, fixtures, and security rules.

## Status

The repository foundation and the first Android connection slice are under
development. The Android app currently supports onboarding, manual server
address entry, address validation, and `/api/link/info` compatibility checks.
Pairing depends on the HomePlace server implementing the Link API described in
its canonical roadmap.

## Repository layout

- `android/` — Kotlin, Jetpack Compose, Material 3, Coroutines, Flow, Room, and
  OkHttp application.
- `ios/` — Swift and SwiftUI application.
- `docs/` — architecture, security, protocol dependency, and development notes.
- `scripts/` — local validation helpers used by contributors and CI.

## Android development

Requirements:

- Android Studio with JDK 17
- Android SDK 35

Open `android/` in Android Studio, let Gradle sync, and run the `app`
configuration. From a terminal with a configured JDK and Android SDK:

```sh
cd android
./gradlew test lint assembleDebug
```

## iOS development

Requirements:

- Xcode 26 or newer
- iOS 17 SDK or newer

Open `ios/HomePlace.xcodeproj`, select the HomePlace scheme, and run it on a
simulator or a development device. Command-line validation:

```sh
xcodebuild -project ios/HomePlace.xcodeproj \
  -scheme HomePlace \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO build
```

## Project rules

- Protocol and API definitions remain canonical in the HomePlace server
  repository. Mobile code pins and validates a supported protocol range.
- Secrets belong in Android Keystore or iOS Keychain and must never be logged.
- Capabilities describe only functionality the current device and OS can
  actually provide.
- Public hostnames require HTTPS. Plain HTTP is limited to loopback and local
  network addresses and is always presented as insecure.
- Do not commit credentials, signing material, provisioning profiles, or
  environment-specific configuration.

See [Architecture](docs/architecture.md), [Security](docs/security.md), and
[HomePlace Link dependency](docs/homeplace-link.md) before adding a connection
or device capability.
