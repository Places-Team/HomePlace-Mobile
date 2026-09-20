# Development workflow

Install Flutter, Android Studio with JDK 17 and Android SDK 36, Xcode, and CocoaPods. Run `flutter doctor -v` before platform work.

## Validation

Run from the repository root:

```sh
scripts/check.sh
flutter pub get
flutter gen-l10n
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
flutter build ios --simulator --no-codesign
```

Android is the first validation target. iOS simulator validation follows once the shared slice is stable. Device-only functionality still requires a real-device check before release.

Android updates require an increasing `versionCode` and the same signing key as
the installed package. Bump the build number in `pubspec.yaml` for distributable
test builds and validate upgrades with `adb install -r`; do not mix APKs signed
by different development machines or CI jobs. Release signing material remains
outside the repository.

## Localization and diagnostics

English and Russian strings live in `lib/l10n/app_en.arb` and `lib/l10n/app_ru.arb`. Run `flutter gen-l10n` after changing either file. Primary errors should be actionable and localized; technical, redacted details belong in the troubleshooting view.

## Native work

Keep method channels small and typed at the Dart boundary. Do not move background execution, Keychain, Keystore, notification, QR camera, Share Sheet, file, or clipboard policy into a shared abstraction that hides platform restrictions.

Before committing, inspect staged files for credentials, signing assets, local SDK paths, and generated build output. Preserve unrelated and uncommitted user changes.
