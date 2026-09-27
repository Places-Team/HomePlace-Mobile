import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/storage/connection_profile.dart';
import 'package:homeplace/features/plants/plant_controller.dart';
import 'package:homeplace/features/plants/plant_store.dart';
import 'package:homeplace/features/plants/plants_view.dart';
import 'package:homeplace/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('adds a plant and records watering from its card', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    const profile = ConnectionProfile(
      serverId: 'garden-server',
      serverName: 'Garden Home',
      preferredUrl: 'https://garden.example.test',
      deviceId: 'garden-phone',
      secure: true,
    );
    final controller = PlantController(PlantStore(profile));
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PlantsPage(controller: controller),
      ),
    );

    await tester.tap(find.text('Add plant').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Name'), 'Fern');
    tester.testTextInput.hide();
    await tester.scrollUntilVisible(
      find.text('Save plant'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Save plant'));
    await tester.pumpAndSettle();
    expect(controller.plants.single.name, 'Fern');
    expect(controller.plants.single.intervalDays, 7);

    await tester.tap(find.text('Fern').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Watered now'));
    await tester.pumpAndSettle();
    expect(controller.plants.single.daysUntilWatering(DateTime.now()), 7);
    controller.dispose();
  });
}
