import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/storage/connection_profile.dart';
import 'package:homeplace/features/ideas/idea_controller.dart';
import 'package:homeplace/features/ideas/idea_store.dart';

final class MemoryIdeaStore implements IdeaStore {
  IdeaCollection value = const IdeaCollection();
  bool failWrite = false;

  @override
  Future<IdeaCollection> read() async => value;

  @override
  Future<void> write(IdeaCollection collection) async {
    if (failWrite) throw StateError('Storage unavailable');
    value = collection;
  }
}

void main() {
  test('secure storage key separates server and device profiles', () {
    const first = ConnectionProfile(
      serverId: 'server-1',
      serverName: 'Home',
      preferredUrl: 'https://home.test',
      deviceId: 'device-1',
      secure: true,
    );
    const otherDevice = ConnectionProfile(
      serverId: 'server-1',
      serverName: 'Home',
      preferredUrl: 'https://home.test',
      deviceId: 'device-2',
      secure: true,
    );
    const otherServer = ConnectionProfile(
      serverId: 'server-2',
      serverName: 'Home',
      preferredUrl: 'https://home.test',
      deviceId: 'device-1',
      secure: true,
    );
    expect(
      SecureIdeaStore.keyFor(first),
      isNot(SecureIdeaStore.keyFor(otherDevice)),
    );
    expect(
      SecureIdeaStore.keyFor(first),
      isNot(SecureIdeaStore.keyFor(otherServer)),
    );
    expect(SecureIdeaStore.keyFor(first), isNot(contains('server-1')));
  });

  test('idea records and categories survive serialization', () {
    final collection = IdeaCollection(
      ideas: [
        HomeIdea(
          id: 'one',
          text: 'Water the fern',
          note: 'Kitchen window',
          pinned: true,
          completed: true,
          archived: true,
          category: 'home',
          createdAt: DateTime.utc(2026, 9, 27),
        ),
      ],
      customCategories: const ['Garden'],
    );
    final restored = IdeaCollection.fromJson(collection.toJson());
    expect(restored.ideas.single.text, 'Water the fern');
    expect(restored.ideas.single.note, 'Kitchen window');
    expect(restored.ideas.single.pinned, isTrue);
    expect(restored.ideas.single.completed, isTrue);
    expect(restored.ideas.single.archived, isTrue);
    final older = HomeIdea.fromJson({
      'id': 'older',
      'text': 'Old phone idea',
      'category': 'inbox',
      'createdAt': '2026-09-27T00:00:00Z',
    });
    expect(older?.note, isEmpty);
    expect(older?.pinned, isFalse);
    expect(older?.completed, isFalse);
    expect(older?.archived, isFalse);
    expect(restored.customCategories, ['Garden']);
    expect(IdeaCollection.fromJson({'version': 2}).ideas, isEmpty);
    final damaged = IdeaCollection.fromJson({
      'version': 1,
      'customCategories': ['Garden', 'garden'],
      'ideas': [
        {
          'id': 'one',
          'text': 'Keep this idea',
          'category': 'missing',
          'createdAt': '2026-09-27T00:00:00Z',
        },
        {
          'id': 'one',
          'text': 'Duplicate identifier',
          'category': 'home',
          'createdAt': '2026-09-27T00:00:00Z',
        },
      ],
    });
    expect(damaged.customCategories, ['Garden']);
    expect(damaged.ideas.single.category, 'inbox');
  });

  test('controller creates, edits, duplicates and deletes ideas', () async {
    final store = MemoryIdeaStore();
    final controller = IdeaController(store);
    await controller.load();
    expect(await controller.addCategory('Garden'), isTrue);
    expect(
      await controller.add('  Check the balcony  ', 'custom:Garden'),
      isTrue,
    );
    final original = controller.ideas.single;
    expect(original.text, 'Check the balcony');
    expect(
      await controller.update(original, 'Check the roses', 'home'),
      isTrue,
    );
    expect(await controller.duplicate(controller.ideas.single), isTrue);
    expect(controller.ideas.length, 2);
    expect(controller.ideas.first.id, isNot(original.id));
    expect(await controller.remove(controller.ideas.last), isTrue);
    expect(store.value.ideas.single.text, 'Check the roses');
    controller.dispose();
  });

  test('failed storage write does not show an unsaved idea', () async {
    final store = MemoryIdeaStore()..failWrite = true;
    final controller = IdeaController(store);
    await controller.load();
    expect(await controller.add('Private note', 'inbox'), isFalse);
    expect(controller.ideas, isEmpty);
    expect(controller.error, isNotNull);
    controller.dispose();
  });
}
