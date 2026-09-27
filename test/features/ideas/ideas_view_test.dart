import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/features/ideas/idea_controller.dart';
import 'package:homeplace/features/ideas/idea_store.dart';
import 'package:homeplace/features/ideas/ideas_view.dart';
import 'package:homeplace/l10n/generated/app_localizations.dart';

final class _MemoryStore implements IdeaStore {
  IdeaCollection value = const IdeaCollection();

  @override
  Future<IdeaCollection> read() async => value;

  @override
  Future<void> write(IdeaCollection collection) async {
    value = collection;
  }
}

void main() {
  testWidgets('captures a private idea and hands it to reminder editor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 840);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = IdeaController(_MemoryStore());
    await controller.load();
    String? reminderDraft;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: IdeasWorkspace(
              controller: controller,
              canMakeReminder: true,
              clipboardRelayEnabled: false,
              onMakeReminder: (text) => reminderDraft = text,
            ),
          ),
        ),
      ),
    );
    expect(
      find.text(
        'Private to this phone and connection. Ideas do not sync with Desktop yet.',
      ),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('idea-draft')),
      'Water the fern',
    );
    await tester.ensureVisible(find.text('Save idea'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save idea'));
    await tester.pumpAndSettle();
    expect(controller.ideas, hasLength(1));
    expect(find.text('Water the fern'), findsOneWidget);
    final ideaCard = find.byKey(ValueKey('idea-${controller.ideas.single.id}'));
    await tester.ensureVisible(ideaCard);
    await tester.pumpAndSettle();
    await tester.tap(ideaCard);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Make reminder'));
    await tester.pumpAndSettle();
    expect(reminderDraft, 'Water the fern');
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}
