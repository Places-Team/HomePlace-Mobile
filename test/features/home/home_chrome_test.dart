import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/features/home/home_chrome.dart';
import 'package:homeplace/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('header keeps one identity and reachable global actions', (
    tester,
  ) async {
    var openedHistory = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: HomeAtlasHeader(
            destinationTitle: 'Plan',
            serverName: 'HomePlace',
            refreshing: false,
            hasError: false,
            onRefresh: () {},
            onError: null,
            onNotifications: () => openedHistory = true,
          ),
        ),
      ),
    );

    expect(find.text('HomePlace'), findsOneWidget);
    expect(find.text('Plan'), findsOneWidget);
    expect(find.byTooltip('Notification history'), findsOneWidget);
    expect(find.byTooltip('Refresh'), findsOneWidget);
    await tester.tap(find.byTooltip('Notification history'));
    expect(openedHistory, isTrue);
  });

  testWidgets('header fits enlarged Russian text', (tester) async {
    tester.view.physicalSize = const Size(390, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.4)),
          child: Scaffold(
            body: HomeAtlasHeader(
              destinationTitle: 'Планы',
              serverName: 'HomePlace',
              refreshing: false,
              hasError: true,
              onRefresh: () {},
              onError: () {},
              onNotifications: () {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
  });
}
