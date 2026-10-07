# Home Atlas Foundation Implementation Plan

**Goal:** Ship the Home Atlas visual foundation, compact navigation, Home/Plan hierarchy, and accessible plant-watering interaction as a working Android increment.

**Architecture:** Centralize visual tokens in a Flutter theme module; keep the shell responsible for navigation and shared chrome, while Home, Plan day selection, and plant watering own their local UI state. Existing controllers and server-backed data remain the source of truth. This plan does not change HomePlace Link, device capabilities, or file-transfer persistence.

**Tech Stack:** Flutter, Dart, Material 3, existing `flutter_test` widget tests, Android emulator and Samsung profile-mode validation.

**Specs:** `docs/superpowers/specs/2026-10-07-home-atlas-visual-design.md` and `docs/superpowers/specs/2026-10-07-mobile-navigation-and-transfer-design.md`.

## Global constraints

- Preserve the five bottom destinations and the rightmost All sections button.
- Retain English and Russian localization; no user-facing string is hardcoded outside localization resources.
- Every gesture has a visible tap alternative; reduced-motion mode removes travel animations.
- Watering writes only after a completed gesture or button tap; Undo restores the previous watering time.
- Keep account/profile isolation, existing permissions, and platform-secure credential storage unchanged.
- Keep documentation, comments, and commit messages in English, with no attribution text.
- Validate Android first. Do not claim iOS gesture or background parity without device validation.
- Commit completed, validated increments as `Olmae <sviteyo@gmail.com>`; fetch and integrate remote changes safely before any push.

## Review focus

1. Russian text at 1.4–2.0 scale must not clip the header, pill, day rail, or watering control (Tasks 2, 4, 5, 6).
2. An empty or offline plant list must show a useful state without a false `watered` animation (Tasks 4 and 6).
3. A cancelled or repeated water drag must not write twice; Undo must restore the prior date (Task 6).
4. Returning from notification history or a plant detail must preserve the selected bottom destination and its scroll position (Tasks 2, 3, 6).
5. With reduced motion enabled, actions must remain understandable without travel/ripple animation or haptics (Tasks 2, 5, 6).

## File map

- `lib/core/design/home_atlas_theme.dart`: palette, typography, shape tokens, and `buildHomeAtlasTheme(Brightness)`.
- `assets/fonts/Onest-Variable.ttf`, `assets/fonts/Literata-Variable.ttf`, and their OFL files: bundled, offline Cyrillic-capable typography.
- `lib/features/home/home_chrome.dart`: compact `HomeAtlasHeader` and `HomeAtlasPill` widgets.
- `lib/features/notifications/notification_history_page.dart`: the single notification-history destination, extracted from the current module page.
- `lib/features/home/home_today_page.dart`: focused Home composition using existing overview and plant data.
- `lib/features/home/plan_day_rail.dart`: local seven-day selection and expanded-month control.
- `lib/features/plants/plant_detail_page.dart`: plant detail and the button-equivalent watering action.
- `lib/features/plants/plant_watering_control.dart`: isolated drag/hold gesture and visual feedback; no persistence logic.
- `lib/features/home/home_shell.dart`: integration only; remove chrome and Home composition as they move to focused files.
- Existing English/Russian ARB files and focused tests change with the feature that needs them.

---

### Task 1: Offline typography and theme tokens

**Files:** Create `lib/core/design/home_atlas_theme.dart`, `assets/fonts/Onest-Variable.ttf`, `assets/fonts/Literata-Variable.ttf`, `assets/fonts/OFL-Onest.txt`, `assets/fonts/OFL-Literata.txt`, and `test/core/design/home_atlas_theme_test.dart`; modify `pubspec.yaml` and `lib/main.dart`.

**Interfaces:** Produce `ThemeData buildHomeAtlasTheme(Brightness brightness)`; later tasks consume `Theme.of(context)` and the named `HomeAtlasColors` constants from this module.

- [ ] Write `home_atlas_theme_test.dart`: assert light canvas `0xFFF6F2E8`, dark canvas `0xFF121A17`, light ink `0xFF1D2922`, light primary `0xFF2E6048`, `Onest` body family, `Literata` display family, and distinct light/dark schemes.
- [ ] Run `flutter test test/core/design/home_atlas_theme_test.dart`; expect failure because the module is absent.
- [ ] Bundle the two Google Fonts OFL variable fonts and licenses from `ofl/onest/Onest[wght].ttf` and `ofl/literata/Literata[opsz,wght].ttf`; verify SHA-256 `966c5c29b4755da84b6854d5c21dd4eaa2420225d0e9874de602de176d4a9f31` and `b41138c9373112f32abb589cc22e8674b06ed4048b0c513be922bdd26f274440`. Stop and verify upstream changes if a checksum differs. Register local font assets in `pubspec.yaml`; do not fetch fonts at runtime.
- [ ] Implement `buildHomeAtlasTheme` with the spec's light/dark tokens and shape/typography hierarchy; replace the private `_theme` body in `lib/main.dart` with a call to this function.
- [ ] Run the focused test, `flutter analyze`, and `flutter test test/widget_test.dart`; expect all to pass, then commit `Add Home Atlas theme and typography`.

### Task 2: Compact shared header and single notification route

**Files:** Create `lib/features/home/home_chrome.dart`, `lib/features/notifications/notification_history_page.dart`, and `test/features/home/home_chrome_test.dart`; modify `lib/features/home/home_shell.dart`, `lib/features/home/home_modules.dart`, `test/features/home/home_shell_test.dart`, `lib/l10n/app_en.arb`, and `lib/l10n/app_ru.arb`.

**Interfaces:** `HomeAtlasHeader({required String destinationTitle, required String serverName, required bool refreshing, required bool hasError, required VoidCallback onRefresh, required VoidCallback? onError, required VoidCallback onNotifications})`; `NotificationHistoryPage({required ConnectionController connection})`.

- [ ] Add widget tests asserting one app identity in the header, accessible Bell/Refresh/Error labels at 1.4 text scale, bell navigation to the current profile's history, and no notification-history row in All sections or card in Transfers.
- [ ] Run `flutter test test/features/home/home_chrome_test.dart test/features/home/home_shell_test.dart`; expect the new tests to fail on the current duplicated entry points.
- [ ] Extract the existing `_NotificationsModulePage` behavior into `NotificationHistoryPage`, keep its profile-scoped data and clear action, remove the old directory entry and Transfers card, and wire the new header Bell route from `HomeShell`.
- [ ] Build `HomeAtlasHeader` as one compact row; remove the special Plan logo/title layout and duplicate HomePlace label. Use ARB labels for both languages and run `flutter gen-l10n`.
- [ ] Run both focused test files and `flutter analyze`; expect pass, then commit `Unify mobile header and notification history`.

### Task 3: Retained one-handed navigation

**Files:** Add `HomeAtlasPill` to `lib/features/home/home_chrome.dart`; modify `lib/features/home/home_shell.dart` and `test/features/home/home_shell_test.dart`.

**Interfaces:** `HomeAtlasPill({required int selectedIndex, required int transferCount, required ValueChanged<int> onSelect, required VoidCallback onMore})`; indexes `0..4` remain Home, Plan, Requests, Transfers, Control.

- [ ] Add widget tests: the five destinations and All sections remain visible; tapping a pill item preserves the destination after a detail push/pop; tapping Back from a detail returns to its originating tab; the root `PageView` does not respond to a horizontal drag; 2.0 text scale yields no overflow.
- [ ] Run `flutter test test/features/home/home_shell_test.dart`; expect the new retained-navigation and scaling assertions to fail.
- [ ] Move `_PillNavigation` into `HomeAtlasPill`, retain its badge only for actual pending offers, set the root `PageView` to `NeverScrollableScrollPhysics`, and preserve the existing retained child state and scroll controllers. Move only the active pill region with an interruptible 200–300 ms animation; use immediate state changes under reduced motion.
- [ ] Run the focused test and `flutter analyze`; expect pass, then commit `Refine retained mobile navigation`.

### Task 4: Home as a useful daily page

**Files:** Create `lib/features/home/home_today_page.dart` and `test/features/home/home_today_page_test.dart`; modify `lib/features/home/home_shell.dart`, `lib/features/plants/plants_view.dart`, and both ARB files.

**Interfaces:** `HomeTodayPage({required MobileOverview overview, required HomeController home, required ConnectionController connection, required PlantController? plants, required VoidCallback onOpenPlan})`; reads existing plant dates and overview reminders without duplicating persistence.

- [ ] Add tests for two due plants plus a nearest action above the first scroll, no plants/empty plan, a plant with no photo, a long Russian plant name at 1.4 scale, and navigation from a plant tile to its detail.
- [ ] Run `flutter test test/features/home/home_today_page_test.dart`; expect failure because the page does not exist.
- [ ] Move the current `_OverviewPage` responsibility into `HomeTodayPage`: compact date/title, one asymmetric plant-care feature, at most three due plant tiles, and a short nearest-action row. Use a local illustration/initial fallback, not external image requests; preserve existing permission gates.
- [ ] Update `HomeShell` to host `HomeTodayPage`, generate localizations, and run focused Home and plant view tests plus `flutter analyze`; expect pass, then commit `Focus Home on daily care`.

### Task 5: Seven-day Plan rail and compact agenda

**Files:** Create `lib/features/home/plan_day_rail.dart` and `test/features/home/plan_day_rail_test.dart`; modify `lib/features/home/home_shell.dart` and both ARB files.

**Interfaces:** `PlanDayRail({required DateTime selectedDate, required ValueChanged<DateTime> onDateSelected, required ValueChanged<int> onWeekShift, required bool expanded, required ValueChanged<bool> onExpandedChanged})`; keep `_MonthCalendar` as the expanded-month content.

- [ ] Add widget tests: today selects the correct seven-day week, a week swipe moves seven days without switching the bottom tab, tapping a day changes the agenda, Expand reveals the month, Collapse restores the day rail, and English/Russian at 1.4 scale has no overflow.
- [ ] Run `flutter test test/features/home/plan_day_rail_test.dart test/features/home/home_shell_test.dart`; expect the new rail assertions to fail.
- [ ] Implement `PlanDayRail` and update `_PlanPage` so the selected-day agenda appears immediately below it; show the existing `_MonthCalendar` only when expanded. Preserve calendar permission checks and the current month-loading API; do not create events locally.
- [ ] Generate localizations; run focused tests and `flutter analyze`; expect pass, then commit `Make Plan day-first`.

### Task 6: Accessible plant watering with a tactile gesture

**Files:** Create `lib/features/plants/plant_detail_page.dart`, `lib/features/plants/plant_watering_control.dart`, and `test/features/plants/plant_watering_control_test.dart`; modify `lib/features/plants/plants_view.dart`, `lib/features/plants/plant_controller.dart`, `test/features/plants/plants_view_test.dart`, and both ARB files.

**Interfaces:** `PlantWateringControl({required Future<void> Function() onWater, required bool busy, required bool reduceMotion})`; `PlantDetailPage({required PlantController controller, required HomePlant plant})`. Add `bool get hasPendingSync` to `PlantController` using its repository's pending count.

- [ ] Add tests that a cancelled drag makes zero `onWater` calls, a release in the target makes exactly one, repeated release while busy makes no second call, the visible `Watered today` button performs the same action, and reduced motion shows state without travel.
- [ ] Run `flutter test test/features/plants/plant_watering_control_test.dart`; expect failure because the widgets are absent.
- [ ] Implement the drag/hold target within the lower thumb zone; commit a write only on release inside the target. Keep a visible button, 44-point targets, semantic descriptions, and a short feedback ripple/leaf lift only after `controller.water` succeeds. If `hasPendingSync`, label the result as saved locally and waiting to sync; failures show inline error.
- [ ] Add detail-page tests that successful watering recalculates the next date, Undo within at least five seconds calls `water` with the previous timestamp, cancelled drag changes no plant, the existing Edit action remains available, and Back returns to the original tab. Replace `_showPlant` sheet with the detail route and generate localizations.
- [ ] Run both plant test files, `test/features/home/home_shell_test.dart`, and `flutter analyze`; expect pass, then commit `Add tactile plant watering`.

### Task 7: Android acceptance and documentation

**Files:** Modify `docs/mobile-experience-map.md` and `docs/architecture.md` only if the implemented navigation or plant flow differs from their current descriptions; add screenshots under a non-secret test-artifact directory outside Git.

**Interfaces:** No new runtime interface. This task closes the increment only after the first six tasks pass.

- [ ] Run `flutter gen-l10n`, `flutter analyze`, and `flutter test`; record pass/fail and fix regressions before proceeding.
- [ ] Build the Android debug APK with `ANDROID_USER_HOME=/Users/olmaemac/.android` so its update signing identity remains stable; install without clearing user data on the emulator first.
- [ ] In Flutter profile mode, compare tab-change and watering frame timings on the emulator and available Samsung. Exercise Home, Plan, plant drag/button/Undo, notification Bell, Back, English/Russian, dark/light, 1.4–2.0 text scale, and reduced motion. A test not completed on a real device must be reported as unverified, not passed.
- [ ] Update only documentation made stale by this increment; run `git diff --check`; commit `Document Home Atlas foundation validation` only if files changed.
- [ ] Before any push, fetch the configured remote, inspect divergence, integrate without overwriting unrelated changes, then push completed validated commits. Record tested commit hash and known limitations.

## Separate follow-up plans

This increment does not implement the companion spec's Transfers/Exchange links restructure or receipt/background-download recovery. Plan those as separate, independently testable increments after the Home Atlas foundation is reviewed; preserve the existing transfer flow until its replacement is validated.
