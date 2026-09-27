import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/connection/connection_controller.dart';
import '../../core/storage/connection_profile.dart';
import '../../link/idea_api.dart';
import '../../link/link_client.dart';
import 'idea_store.dart';

final class ServerIdeaStore implements IdeaStore {
  ServerIdeaStore({
    required this.profile,
    required this.sessionProvider,
    required this.localStore,
    IdeaGateway? gateway,
  }) : gateway = gateway ?? const IdeaApi();

  final ConnectionProfile profile;
  final Future<AuthenticatedLinkSession?> Function() sessionProvider;
  final IdeaStore localStore;
  final IdeaGateway gateway;

  IdeaCollection current = const IdeaCollection();
  final Map<String, String> _categoryIds = {};
  int pendingLocalCount = 0;
  bool _needsRefresh = false;

  String get _importKey =>
      'homeplace.ideas.imported.${SecureIdeaStore.keyFor(profile)}';

  Future<AuthenticatedLinkSession> _session() async =>
      await sessionProvider() ??
      (throw StateError('HomePlace is not connected.'));

  T _value<T>(LinkResult<T> result) => switch (result) {
    LinkSuccess<T>(:final value) => value,
    LinkFailure<T>(:final message) => throw StateError(message),
  };

  @override
  Future<IdeaCollection> read() async {
    final session = await _session();
    final categories = <String, String>{};
    final ideas = <HomeIdea>[];
    final seenCursors = <String>{};
    String? cursor;
    do {
      final page = _value(await gateway.page(session, cursor: cursor));
      final rawCategories = page['categories'];
      final rawIdeas = page['ideas'];
      if (rawCategories is! List || rawIdeas is! List) {
        throw const FormatException('Invalid HomePlace ideas response.');
      }
      for (final raw in rawCategories) {
        if (raw is! Map || raw['id'] is! String || raw['name'] is! String) {
          throw const FormatException('Invalid HomePlace idea category.');
        }
        categories[_keyForName(raw['name'] as String)] = raw['id'] as String;
      }
      for (final raw in rawIdeas) {
        if (raw is! Map ||
            raw['id'] is! String ||
            raw['title'] is! String ||
            raw['categoryId'] is! String) {
          throw const FormatException('Invalid HomePlace idea.');
        }
        final createdAt = DateTime.tryParse(raw['createdAt']?.toString() ?? '');
        if (createdAt == null) {
          throw const FormatException('Invalid HomePlace idea date.');
        }
        final category = categories.entries
            .where((entry) => entry.value == raw['categoryId'])
            .map((entry) => entry.key)
            .firstOrNull;
        ideas.add(
          HomeIdea(
            id: raw['id'] as String,
            text: raw['title'] as String,
            category: category ?? 'inbox',
            createdAt: createdAt,
          ),
        );
      }
      cursor = page['nextCursor'] as String?;
      if (cursor != null && !seenCursors.add(cursor)) {
        throw const FormatException('Repeated HomePlace ideas cursor.');
      }
    } while (cursor != null);

    _categoryIds
      ..clear()
      ..addAll(categories);
    final custom = categories.keys
        .where((key) => key.startsWith('custom:'))
        .map((key) => key.substring(7))
        .toList(growable: false);
    current = IdeaCollection(ideas: ideas, customCategories: custom);
    _needsRefresh = false;
    final preferences = await SharedPreferences.getInstance();
    pendingLocalCount = preferences.getBool(_importKey) == true
        ? 0
        : (await localStore.read()).ideas.length;
    return current;
  }

  @override
  Future<void> write(IdeaCollection next) async {
    if (_needsRefresh) {
      throw StateError('Refresh ideas before changing them again.');
    }
    final session = await _session();
    final before = {for (final idea in current.ideas) idea.id: idea};
    final after = {for (final idea in next.ideas) idea.id: idea};
    final categoryKeys = <String>{
      ...next.customCategories.map((name) => 'custom:$name'),
      ...next.ideas.map((idea) => idea.category),
    };
    for (final key in categoryKeys) {
      if (_categoryIds.containsKey(key)) continue;
      _needsRefresh = true;
      final response = _value(
        await gateway.command(session, {
          'action': 'createCategory',
          'name': _nameForKey(key),
        }),
      );
      final category = response['category'];
      if (category is! Map || category['id'] is! String) {
        throw const FormatException('Invalid HomePlace category response.');
      }
      _categoryIds[key] = category['id'] as String;
    }
    for (final idea in next.ideas) {
      final old = before[idea.id];
      if (old == null) {
        _needsRefresh = true;
        _value(
          await gateway.command(session, {
            'action': 'createIdea',
            'title': idea.text,
            'categoryId': _categoryIds[idea.category],
          }),
        );
      } else if (old.text != idea.text || old.category != idea.category) {
        _needsRefresh = true;
        _value(
          await gateway.command(session, {
            'action': 'updateIdea',
            'id': idea.id,
            'title': idea.text,
            'categoryId': _categoryIds[idea.category],
          }),
        );
      }
    }
    for (final idea in current.ideas) {
      if (!after.containsKey(idea.id)) {
        _needsRefresh = true;
        _value(
          await gateway.command(session, {
            'action': 'deleteIdea',
            'id': idea.id,
          }),
        );
      }
    }
    await read();
  }

  Future<void> importLocal() async {
    final local = await localStore.read();
    if (local.ideas.isEmpty && local.customCategories.isEmpty) return;
    final session = await _session();
    final names = <String>{
      ...local.customCategories,
      ...local.ideas.map((idea) => _nameForKey(idea.category)),
    }.toList();
    for (var start = 0; start < names.length; start += 40) {
      _value(
        await gateway.command(session, {
          'action': 'import',
          'categories': names.skip(start).take(40).toList(),
          'ideas': <Object>[],
        }),
      );
    }
    for (var start = 0; start < local.ideas.length; start += 30) {
      _value(
        await gateway.command(session, {
          'action': 'import',
          'categories': <String>[],
          'ideas': local.ideas
              .skip(start)
              .take(30)
              .map(
                (idea) => {
                  'sourceId': _sourceId(idea.id),
                  'title': idea.text,
                  'category': _nameForKey(idea.category),
                  'createdAt': idea.createdAt.toUtc().toIso8601String(),
                },
              )
              .toList(),
        }),
      );
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_importKey, true);
    await read();
  }

  String _sourceId(String localId) {
    final hex = sha256
        .convert(
          utf8.encode('${profile.serverId}:${profile.deviceId}:$localId'),
        )
        .toString();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  static String _keyForName(String name) {
    final clean = name.trim();
    final lower = clean.toLowerCase();
    return builtInIdeaCategories.contains(lower) ? lower : 'custom:$clean';
  }

  static String _nameForKey(String key) =>
      key.startsWith('custom:') ? key.substring(7) : key;
}

final class ProfileIdeaStore implements IdeaStore {
  ProfileIdeaStore({
    required this.local,
    required this.server,
    required this.canUseServer,
  });

  final IdeaStore local;
  final ServerIdeaStore server;
  final bool Function() canUseServer;
  bool serverSynced = false;

  @override
  Future<IdeaCollection> read() async {
    final targetServer = canUseServer();
    final collection = await (targetServer ? server.read() : local.read());
    serverSynced = targetServer;
    return collection;
  }

  @override
  Future<void> write(IdeaCollection collection) =>
      serverSynced ? server.write(collection) : local.write(collection);

  IdeaCollection get current => server.current;
  int get pendingLocalCount => serverSynced ? server.pendingLocalCount : 0;
  Future<void> importLocal() => server.importLocal();
}
