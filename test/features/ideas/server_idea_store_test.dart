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
  }) async => LinkSuccess({
    'categories': categories,
    'ideas': ideas,
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
          'categoryId': body['categoryId'],
          'createdAt': DateTime.utc(2026, 9, 27).toIso8601String(),
        };
        ideas.add(idea);
        return LinkSuccess({'idea': idea});
      case 'updateIdea':
        final idea = ideas.singleWhere((item) => item['id'] == body['id']);
        idea['title'] = body['title'];
        idea['categoryId'] = body['categoryId'];
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
    await store.write(const IdeaCollection());
    expect(store.current.ideas, isEmpty);
    expect(gateway.commands.last['action'], 'deleteIdea');
  });

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
}
