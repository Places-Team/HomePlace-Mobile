import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/features/home/home_controller.dart';
import 'package:homeplace/features/home/home_shell.dart';
import 'package:homeplace/l10n/generated/app_localizations.dart';
import 'package:homeplace/link/mobile_models.dart';

void main() {
  testWidgets('dashboard tabs fit a compact Android viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final connection = ConnectionController();
    final home = HomeController(sessionProvider: () async => null)
      ..loading = false
      ..overview = _overview();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HomeShell(connection: connection, homeController: home),
      ),
    );
    expect(find.text('Everything in its place'), findsOneWidget);
    for (final label in ['Plan', 'Requests', 'Monitor', 'Home']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    connection.dispose();
    home.dispose();
  });
}

MobileOverview _overview() => MobileOverview.fromJson({
  'serverTime': '2026-09-20T10:00:00Z',
  'permissions': [
    'dashboard.read',
    'reminder.manage',
    'media.request',
    'telegram.send',
  ],
  'reminders': [
    {
      'id': 'r1',
      'title': 'Water plants',
      'at': '2026-09-20T18:00:00Z',
      'repeat': 'weekly',
    },
  ],
  'calendar': {'connected': true, 'email': 'home@example.test', 'events': []},
  'requests': {
    'instances': [
      {
        'label': 'Movies',
        'kind': 'radarr',
        'queueCount': 0,
        'warnings': 0,
        'queue': [],
        'upcoming': [],
      },
    ],
    'qbittorrent': {
      'downloadSpeed': 0,
      'uploadSpeed': 0,
      'active': 0,
      'total': 0,
    },
  },
  'telegram': {'connected': true, 'enabled': true, 'source': 'ui'},
  'monitoring': {
    'total': 1,
    'online': 1,
    'offline': 0,
    'unknown': 0,
    'services': [
      {
        'id': 'service-1',
        'title': 'HomePlace',
        'status': 'online',
        'latencyMs': 12,
        'checkedAt': '2026-09-20T10:00:00Z',
      },
    ],
    'recent': [],
  },
});
