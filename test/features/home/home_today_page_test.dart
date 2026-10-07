import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/storage/connection_profile.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/features/home/home_controller.dart';
import 'package:homeplace/features/home/home_today_page.dart';
import 'package:homeplace/features/plants/plant_controller.dart';
import 'package:homeplace/features/plants/plant_store.dart';
import 'package:homeplace/l10n/generated/app_localizations.dart';
import 'package:homeplace/link/mobile_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('due plants lead home and the nearest action remains visible', (
    tester,
  ) async {
    final now = DateTime.now();
    final plants = await _plantController([
      _plant('fern', 'Fern', now.subtract(const Duration(days: 9))),
      _plant('violet', 'Violet', now.subtract(const Duration(days: 8))),
    ]);
    final connection = ConnectionController();
    final home = HomeController(sessionProvider: () async => null);
    await _pump(
      tester,
      plants: plants,
      connection: connection,
      home: home,
      overview: _overview(reminderTitle: 'Clean kitchen'),
    );

    expect(find.text('2 need water'), findsOneWidget);
    expect(find.text('Fern'), findsOneWidget);
    expect(find.text('Violet'), findsOneWidget);
    expect(find.text('Clean kitchen'), findsOneWidget);
    expect(tester.takeException(), isNull);
    connection.dispose();
    home.dispose();
    plants.dispose();
  });

  testWidgets('without due plants care becomes compact and has no due shelf', (
    tester,
  ) async {
    final plants = await _plantController([
      _plant('fern', 'Fern', DateTime.now()),
    ]);
    final connection = ConnectionController();
    final home = HomeController(sessionProvider: () async => null);
    await _pump(
      tester,
      plants: plants,
      connection: connection,
      home: home,
      overview: _overview(reminderTitle: 'Clean kitchen'),
    );

    expect(find.text('Next watering'), findsOneWidget);
    expect(find.text('Needs watering'), findsNothing);
    expect(find.text('Clean kitchen'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Next up')).dy,
      lessThan(tester.getTopLeft(find.text('Next watering')).dy),
    );
    expect(tester.takeException(), isNull);
    connection.dispose();
    home.dispose();
    plants.dispose();
  });

  testWidgets('empty care offers setup without a false watering state', (
    tester,
  ) async {
    final plants = await _plantController(const []);
    final connection = ConnectionController();
    final home = HomeController(sessionProvider: () async => null);
    await _pump(
      tester,
      plants: plants,
      connection: connection,
      home: home,
      overview: _overview(),
    );

    expect(find.text('Add plant'), findsOneWidget);
    expect(find.textContaining('need water'), findsNothing);
    expect(tester.takeException(), isNull);
    connection.dispose();
    home.dispose();
    plants.dispose();
  });

  testWidgets('today all-day event remains the next household action', (
    tester,
  ) async {
    final plants = await _plantController(const []);
    final connection = ConnectionController();
    final home = HomeController(sessionProvider: () async => null);
    await _pump(
      tester,
      plants: plants,
      connection: connection,
      home: home,
      overview: _overview(allDayTitle: 'Family visit'),
    );

    expect(find.text('Family visit'), findsOneWidget);
    connection.dispose();
    home.dispose();
    plants.dispose();
  });

  testWidgets('long Russian plant name fits and opens its plant page', (
    tester,
  ) async {
    const plantName = 'Очень длинное название домашнего цветка у окна';
    final plants = await _plantController([
      _plant(
        'long',
        plantName,
        DateTime.now().subtract(const Duration(days: 10)),
      ),
    ]);
    final connection = ConnectionController();
    final home = HomeController(sessionProvider: () async => null);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pump(
      tester,
      plants: plants,
      connection: connection,
      home: home,
      overview: _overview(),
      locale: const Locale('ru'),
      textScaler: const TextScaler.linear(1.4),
    );

    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text(plantName).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(plantName).first);
    await tester.pumpAndSettle();
    expect(find.text('Полито сейчас'), findsOneWidget);
    expect(tester.takeException(), isNull);
    connection.dispose();
    home.dispose();
    plants.dispose();
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required PlantController plants,
  required ConnectionController connection,
  required HomeController home,
  required MobileOverview overview,
  Locale locale = const Locale('en'),
  TextScaler textScaler = const TextScaler.linear(1),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: HomeTodayPage(
            overview: overview,
            home: home,
            connection: connection,
            plants: plants,
            onOpenPlan: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

MobileOverview _overview({String? reminderTitle, String? allDayTitle}) =>
    MobileOverview.fromJson({
      'serverTime': DateTime.now().toUtc().toIso8601String(),
      'permissions': ['dashboard.read'],
      'reminders': [
        if (reminderTitle != null)
          {
            'id': 'next',
            'title': reminderTitle,
            'at': DateTime.now()
                .add(const Duration(hours: 2))
                .toIso8601String(),
            'done': false,
          },
      ],
      'calendar': {
        'connected': allDayTitle != null,
        'events': [
          if (allDayTitle != null)
            {
              'id': 'today',
              'summary': allDayTitle,
              'start': DateUtils.dateOnly(DateTime.now()).toIso8601String(),
              'end': DateUtils.dateOnly(DateTime.now())
                  .add(const Duration(days: 1))
                  .toIso8601String(),
              'allDay': true,
            },
        ],
      },
    });

Future<PlantController> _plantController(List<HomePlant> entries) async {
  SharedPreferences.setMockInitialValues({});
  const profile = ConnectionProfile(
    serverId: 'home-today-test',
    serverName: 'Test Home',
    preferredUrl: 'https://home.example.test',
    deviceId: 'test-phone',
    secure: true,
  );
  final store = PlantStore(profile);
  for (final plant in entries) {
    await store.save(plant);
  }
  final controller = PlantController(store);
  await controller.load();
  return controller;
}

HomePlant _plant(String id, String name, DateTime wateredAt) => HomePlant(
  id: id,
  name: name,
  species: '',
  location: '',
  intervalDays: 7,
  lastWateredAt: wateredAt,
  createdAt: wateredAt,
);
