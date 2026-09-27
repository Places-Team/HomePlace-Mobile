import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/core/storage/connection_profile.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/features/ideas/idea_store.dart';
import 'package:homeplace/features/ideas/server_idea_store.dart';
import 'package:homeplace/link/idea_api.dart';
import 'package:homeplace/link/link_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class _LocalStore implements IdeaStore {
  IdeaCollection value = const IdeaCollection();

  @override
  Future<IdeaCollection> read() async => value;

  @override
  Future<void> write(IdeaCollection collection) async {
    value = collection;
  }
}

final class _Gateway implements IdeaGateway {
  final commands = <Map<String, dynamic>>[];
  final ideas = <Map<String, dynamic>>[];
  final categories = <Map<String, dynamic>>[
    {'id': 'inbox-id', 'name': 'Inbox', 'position': 0},
  ];

  @override
  Future<LinkResult<Map<String, dynamic>>> page(
    AuthenticatedLinkSession session, {
    String? cursor,
    bool archived = false,
  }) async => LinkSuccess({
    'categories': categories,
    'ideas': ideas.where((idea) => idea['archived'] == archived).toList(),
    'nextCursor': null,
  });

  @override
  Future<LinkResult<Map<String, dynamic>>> command(
    AuthenticatedLinkSession session,
    Map<String, dynamic> body,
  ) async {
    commands.add(body);
    switch (body['action']) {
      case 'createCategory':
        final category = {
          'id': 'category-${categories.length}',
          'name': body['name'],
          'position': categories.length,
        };
        categories.add(category);
        return LinkSuccess({'category': category});
      case 'createIdea':
        final idea = {
          'id': 'idea-${ideas.length}',
          'title': body['title'],
          'note': body['note'] ?? '',
          'pinned': false,
          'archived': false,
          'completedAt': null,
          'categoryId': body['categoryId'],
          'createdAt': DateTime.utc(2026, 9, 27).toIso8601String(),
        };
        ideas.add(idea);
        return LinkSuccess({'idea': idea});
      case 'updateIdea':
        final idea = ideas.singleWhere((item) => item['id'] == body['id']);
        if (body.containsKey('title')) idea['title'] = body['title'];
        if (body.containsKey('note')) idea['note'] = body['note'];
        if (body.containsKey('categoryId')) {
          idea['categoryId'] = body['categoryId'];
        }
        if (body.containsKey('pinned')) idea['pinned'] = body['pinned'];
        if (body.containsKey('archived')) idea['archived'] = body['archived'];
        if (body.containsKey('completed')) {
          idea['completedAt'] = body['completed'] == true
              ? DateTime.utc(2026, 9, 27).toIso8601String()
              : null;
        }
        return const LinkSuccess({'ok': true});
      case 'deleteIdea':
        ideas.removeWhere((item) => item['id'] == body['id']);
        return const LinkSuccess({'ok': true});
      default:
        return const LinkSuccess({'ok': true});
    }
  }
}

final class _UnavailableGateway implements IdeaGateway {
  @override
  Future<LinkResult<Map<String, dynamic>>> page(
    AuthenticatedLinkSession session, {
    String? cursor,
    bool archived = false,
  }) async =>
      const LinkFailure(LinkFailureKind.invalidResponse, 'Not deployed');

  @override
  Future<LinkResult<Map<String, dynamic>>> command(
    AuthenticatedLinkSession session,
    Map<String, dynamic> body,
  ) async => const LinkFailure(LinkFailureKind.network, 'Unavailable');
}

void main() {
  const profile = ConnectionProfile(
    serverId: 'server-1',
    serverName: 'Home',
    preferredUrl: 'https://home.example',
    deviceId: 'phone-1',
    secure: true,
  );

  AuthenticatedLinkSession session() => AuthenticatedLinkSession(
    address: ServerAddress(
      uri: Uri.parse('https://home.example'),
      isLocal: false,
      security: ConnectionSecurity.trustedHttps,
    ),
    credential: 'test-only',
    serverId: profile.serverId,
    serverName: profile.serverName,
  );

  test('creates, updates and removes ideas through account API', () async {
    SharedPreferences.setMockInitialValues({});
    final gateway = _Gateway();
    final store = ServerIdeaStore(
      profile: profile,
      sessionProvider: () async => session(),
      localStore: _LocalStore(),
      gateway: gateway,
    );
    expect((await store.read()).ideas, isEmpty);
    await store.write(
      IdeaCollection(
        ideas: [
          HomeIdea(
            id: 'local-draft',
            text: 'Water roses',
            category: 'home',
            createdAt: DateTime.utc(2026, 9, 27),
          ),
        ],
      ),
    );
    expect(store.current.ideas.single.id, 'idea-0');
    expect(gateway.commands.map((item) => item['action']), [
      'createCategory',
      'createIdea',
    ]);
    final idea = store.current.ideas.single;
    await store.write(
      IdeaCollection(ideas: [idea.copyWith(text: 'Water fern')]),
    );
    expect(store.current.ideas.single.text, 'Water fern');
    expect(gateway.commands.last, {
      'action': 'updateIdea',
      'id': 'idea-0',
      'title': 'Water fern',
    });
    await store.write(const IdeaCollection());
    expect(store.current.ideas, isEmpty);
    expect(gateway.commands.last['action'], 'deleteIdea');
  });

  test(
    'preserves desktop idea details and sends only changed fields',
    () async {
      SharedPreferences.setMockInitialValues({});
      final gateway = _Gateway();
      gateway.ideas.add({
        'id': 'desktop-idea',
        'title': 'Plan weekend',
        'note': 'Take the train',
        'pinned': true,
        'archived': false,
        'completedAt': DateTime.utc(2026, 9, 26).toIso8601String(),
        'categoryId': 'inbox-id',
        'createdAt': DateTime.utc(2026, 9, 25).toIso8601String(),
      });
      final store = ServerIdeaStore(
        profile: profile,
        sessionProvider: () async => session(),
        localStore: _LocalStore(),
        gateway: gateway,
      );
      final idea = (await store.read()).ideas.single;
      expect(idea.note, 'Take the train');
      expect(idea.pinned, isTrue);
      expect(idea.completed, isTrue);

      await store.write(
        IdeaCollection(
          ideas: [
            idea.copyWith(
              note: 'Walk instead',
              pinned: false,
              completed: false,
            ),
          ],
        ),
      );
      expect(gateway.commands.last, {
        'action': 'updateIdea',
        'id': 'desktop-idea',
        'note': 'Walk instead',
        'pinned': false,
        'completed': false,
      });
      expect(store.current.ideas.single.note, 'Walk instead');

      await store.write(
        IdeaCollection(
          ideas: [store.current.ideas.single.copyWith(archived: true)],
        ),
      );
      expect(gateway.commands.last, {
        'action': 'updateIdea',
        'id': 'desktop-idea',
        'archived': true,
      });
      expect(store.current.ideas.single.archived, isTrue);
    },
  );

  test(
    'local import uses stable UUID source ids and never deletes phone copy',
    () async {
      SharedPreferences.setMockInitialValues({});
      final local = _LocalStore()
        ..value = IdeaCollection(
          ideas: [
            HomeIdea(
              id: 'old-phone-id',
              text: 'Replace filter',
              category: 'inbox',
              createdAt: DateTime.utc(2026, 9, 20),
            ),
          ],
        );
      final gateway = _Gateway();
      final store = ServerIdeaStore(
        profile: profile,
        sessionProvider: () async => session(),
        localStore: local,
        gateway: gateway,
      );
      await store.read();
      expect(store.pendingLocalCount, 1);
      await store.importLocal();
      final imported = gateway.commands.last['ideas'] as List<dynamic>;
      expect(imported.single['sourceId'], matches(RegExp(r'^[a-f0-9-]{36}$')));
      expect(local.value.ideas.single.text, 'Replace filter');
      expect(store.pendingLocalCount, 0);
    },
  );

  test('a failed server read never labels local ideas as synced', () async {
    SharedPreferences.setMockInitialValues({});
    final local = _LocalStore();
    final store = ProfileIdeaStore(
      local: local,
      server: ServerIdeaStore(
        profile: profile,
        sessionProvider: () async => session(),
        localStore: local,
        gateway: _UnavailableGateway(),
      ),
      canUseServer: () => true,
    );
    await expectLater(store.read(), throwsStateError);
    expect(store.serverSynced, isFalse);
  });

  test(
    'granting ideas access reveals import without changing local copy',
    () async {
      SharedPreferences.setMockInitialValues({});
      final local = _LocalStore()
        ..value = IdeaCollection(
          ideas: [
            HomeIdea(
              id: 'phone-only',
              text: 'Plant shelf',
              category: 'inbox',
              createdAt: DateTime.utc(2026, 9, 27),
            ),
          ],
        );
      var allowed = false;
      final store = ProfileIdeaStore(
        local: local,
        server: ServerIdeaStore(
          profile: profile,
          sessionProvider: () async => session(),
          localStore: local,
          gateway: _Gateway(),
        ),
        canUseServer: () => allowed,
      );
      expect((await store.read()).ideas.single.text, 'Plant shelf');
      expect(store.serverSynced, isFalse);
      allowed = true;
      expect((await store.read()).ideas, isEmpty);
      expect(store.serverSynced, isTrue);
      expect(store.pendingLocalCount, 1);
      expect(local.value.ideas.single.text, 'Plant shelf');
    },
  );
}
