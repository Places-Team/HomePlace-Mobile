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

final class _SyncedIdeaController extends IdeaController {
  _SyncedIdeaController(super.store);

  @override
  bool get serverSynced => true;
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
        'Only on this phone. This device has not been granted access to account ideas.',
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
    expect(find.text('Pin idea'), findsNothing);
    await tester.tap(find.text('Make reminder'));
    await tester.pumpAndSettle();
    expect(reminderDraft, 'Water the fern');
    expect(tester.takeException(), isNull);
    controller.dispose();
  });

  testWidgets('shows and edits details shared with Desktop', (tester) async {
    tester.view.physicalSize = const Size(390, 840);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = _MemoryStore()
      ..value = IdeaCollection(
        ideas: [
          HomeIdea(
            id: 'shared-idea',
            text: 'Weekend plan',
            note: 'Take the train',
            pinned: true,
            completed: true,
            category: 'inbox',
            createdAt: DateTime.utc(2026, 9, 27),
          ),
        ],
      );
    final controller = _SyncedIdeaController(store);
    await controller.load();
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
              onMakeReminder: (_) {},
            ),
          ),
        ),
      ),
    );
    final card = find.byKey(const ValueKey('idea-shared-idea'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('Take the train'), findsWidgets);
    await tester.tap(find.text('Unpin idea'));
    await tester.pumpAndSettle();
    expect(controller.ideas.single.pinned, isFalse);

    await tester.tap(card);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reopen idea'));
    await tester.pumpAndSettle();
    expect(controller.ideas.single.completed, isFalse);

    await tester.tap(card);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit idea'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (widget) =>
            widget is TextField && widget.decoration?.labelText == 'Details',
      ),
      'Walk instead',
    );
    await tester.ensureVisible(find.text('Save changes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(controller.ideas.single.note, 'Walk instead');
    await tester.tap(card);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive idea'));
    await tester.pumpAndSettle();
    expect(controller.ideas.single.archived, isTrue);
    expect(card, findsNothing);

    await tester.tap(find.text('Archive').first);
    await tester.pumpAndSettle();
    expect(card, findsOneWidget);
    await tester.tap(card);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore idea'));
    await tester.pumpAndSettle();
    expect(controller.ideas.single.archived, isFalse);
    await tester.tap(find.text('Current'));
    await tester.pumpAndSettle();
    expect(card, findsOneWidget);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}
