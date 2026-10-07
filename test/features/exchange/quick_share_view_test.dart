import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/sharing/share_service.dart';
import 'package:homeplace/core/settings/app_preferences.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/features/exchange/quick_share_view.dart';
import 'package:homeplace/features/home/home_shell.dart';
import 'package:homeplace/main.dart';
import 'package:homeplace/l10n/generated/app_localizations.dart';
import 'package:homeplace/link/mobile_models.dart';

void main() {
  testWidgets('external share replaces the full app while restoring', (
    tester,
  ) async {
    final controller = ConnectionController()
      ..quickShareRequested = true
      ..pendingOutgoingShares = const [
        SharedContent(kind: SharedContentKind.text, value: 'Share right now'),
      ];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ConnectionShell(
          controller: controller,
          preferences: AppPreferences(),
        ),
      ),
    );
    expect(find.byType(QuickShareView), findsOneWidget);
    expect(find.text('Share right now'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    controller.dispose();
  });

  testWidgets('external share keeps connected home mounted', (tester) async {
    final controller = ConnectionController()
      ..stage = ConnectionStage.connected
      ..quickShareRequested = true
      ..pendingOutgoingShares = const [
        SharedContent(kind: SharedContentKind.text, value: 'A note'),
      ];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ConnectionShell(
          controller: controller,
          preferences: AppPreferences(),
        ),
      ),
    );
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(QuickShareView), findsOneWidget);
    controller.clearAllOutgoingShares();
    await tester.pump();
    expect(find.byType(HomeShell), findsOneWidget);
    expect(find.byType(QuickShareView), findsNothing);
    controller.dispose();
  });

  testWidgets(
    'shows external content immediately and requires target confirmation',
    (tester) async {
      final controller = ConnectionController()
        ..pendingOutgoingShares = const [
          SharedContent(kind: SharedContentKind.text, value: 'A shared note'),
        ];
      var sends = 0;
      var closes = 0;
      final target = MobileShareTarget(
        id: 'mac-1',
        name: 'Family Mac',
        platform: 'macos',
        supportsText: true,
        supportsUrl: true,
        supportsFile: true,
        online: true,
        ownedByCurrentUser: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: QuickShareView(
            connection: controller,
            targetsLoader: () async => [target],
            sender: (device, content) async {
              sends++;
              return true;
            },
            onClose: () => closes++,
          ),
        ),
      );
      expect(find.text('A shared note'), findsOneWidget);
      expect(find.text('Family Mac'), findsNothing);
      controller.stage = ConnectionStage.connected;
      controller.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('Family Mac'), findsOneWidget);
      await tester.tap(find.text('Family Mac'));
      await tester.pumpAndSettle();
      expect(sends, 0);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.tap(find.text('Send').last);
      await tester.pumpAndSettle();
      expect(sends, 1);
      expect(closes, 1);
      expect(controller.pendingOutgoingShares, isEmpty);
      controller.dispose();
    },
  );
}
