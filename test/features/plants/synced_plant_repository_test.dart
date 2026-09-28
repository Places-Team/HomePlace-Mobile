import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/core/storage/connection_profile.dart';
import 'package:homeplace/core/storage/credential_store.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/features/plants/plant_store.dart';
import 'package:homeplace/features/plants/synced_plant_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class _Credentials implements CredentialStore {
  String value = 'account-a';
  @override
  Future<String?> read(String serverId) async => value;
  @override
  Future<void> write(String serverId, String credential) async =>
      value = credential;
  @override
  Future<void> remove(String serverId) async => value = '';
}

final class _Cache implements PlantSyncCache {
  final states = <String, PlantSyncSnapshot>{};
  bool failWrites = false;
  @override
  Future<PlantSyncSnapshot> read(String scope) async =>
      states[scope] ?? const PlantSyncSnapshot();
  @override
  Future<void> write(String scope, PlantSyncSnapshot snapshot) async {
    if (failWrites) throw StateError('Secure storage unavailable.');
    states[scope] = snapshot;
  }
}

void main() {
  test('imports by consent, retries offline, resolves conflicts and isolates accounts', () async {
    SharedPreferences.setMockInitialValues({});
    const serverId = 'e54f9bfa-2543-4be2-bc07-c1eb3d0947ee';
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final byAccount = <String, Map<String, Map<String, dynamic>>>{};
    var offline = false;
    var commands = 0;
    server.listen((request) async {
      final account =
          request.headers
              .value(HttpHeaders.authorizationHeader)
              ?.replaceFirst('Bearer ', '') ??
          '';
      final records = byAccount.putIfAbsent(account, () => {});
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/api/link/info') {
        request.response.write(
          jsonEncode({
            'product': 'HomePlace',
            'server': {'id': serverId, 'name': 'Test'},
            'protocol': {'min': 1, 'max': 1},
            'serverTime': '2026-09-28T00:00:00.000Z',
            'features': {'pairing': true, 'realtime': false},
          }),
        );
      } else if (offline) {
        request.response.statusCode = HttpStatus.serviceUnavailable;
        request.response.write(jsonEncode({'error': 'offline'}));
      } else if (request.method == 'GET') {
        request.response.write(jsonEncode({'plants': records.values.toList()}));
      } else {
        commands++;
        final body = jsonDecode(
          await utf8.decoder.bind(request).join(),
        ) as Map<String, dynamic>;
        final id = body['clientId'] as String;
        final before = records[id];
        if (body['action'] == 'create') {
          records[id] =
              before ??
              {
                ...body,
                'revision': 1,
                'deletedAt': null,
                'createdAt': DateTime.utc(2026, 9, 28).toIso8601String(),
                'updatedAt': DateTime.utc(2026, 9, 28).toIso8601String(),
              };
          request.response.statusCode = HttpStatus.created;
        } else if (before == null ||
            before['revision'] != body['revision'] ||
            before['deletedAt'] != null) {
          request.response.statusCode = HttpStatus.conflict;
          request.response.write(jsonEncode({'error': 'plant conflict'}));
        } else {
          records[id] = {
            ...before,
            if (body['action'] == 'update') ...body,
            'revision': (before['revision'] as int) + 1,
            if (body['action'] == 'delete')
              'deletedAt': DateTime.utc(2026, 9, 28).toIso8601String(),
          };
        }
        if (request.response.statusCode != HttpStatus.conflict) {
          request.response.write(jsonEncode({'plant': records[id]}));
        }
      }
      await request.response.close();
    });
    const profile = ConnectionProfile(
      serverId: serverId,
      serverName: 'Test',
      preferredUrl: 'http://127.0.0.1',
      deviceId: 'device-1',
      secure: false,
    );
    final local = PlantStore(profile);
    final old = HomePlant(
      id: 'legacy-1',
      name: 'Orchid',
      species: 'Orchid',
      location: 'Window',
      intervalDays: 7,
      lastWateredAt: DateTime.utc(2026, 9, 20),
      createdAt: DateTime.utc(2026, 9, 20),
      photoName: '123.jpg',
    );
    await local.save(old);
    final credentials = _Credentials();
    final cache = _Cache();
    Future<AuthenticatedLinkSession?> session() async =>
        AuthenticatedLinkSession(
          address: ServerAddress(
            uri: Uri.parse('http://127.0.0.1:${server.port}'),
            isLocal: true,
            security: ConnectionSecurity.localHttp,
          ),
          credential: credentials.value,
          serverId: serverId,
          serverName: 'Test',
        );
    SyncedPlantRepository repository() => SyncedPlantRepository(
      profile: profile,
      local: local,
      sessionProvider: session,
      canUseServer: () => true,
      cache: cache,
      credentials: credentials,
    );

    final first = repository();
    await first.load();
    expect(first.localOnlyCount, 1);
    expect(first.plants.single.id, 'legacy-1');
    expect(commands, 0);
    cache.failWrites = true;
    await expectLater(first.importLocal(), throwsStateError);
    expect(first.localOnlyCount, 1);
    expect(first.pendingCount, 0);
    expect(commands, 0);
    cache.failWrites = false;
    await first.importLocal();
    expect(first.localOnlyCount, 0);
    expect((await local.readAll()).single.id, 'legacy-1');
    final synced = first.plants.single;
    expect(synced.id, isNot('legacy-1'));
    expect(synced.photoName, '123.jpg');
    expect(byAccount['account-a']!.length, 1);

    offline = true;
    await first.save(synced.copyWith(name: 'Updated orchid'));
    expect(first.pendingCount, 1);
    expect(first.plants.single.name, 'Updated orchid');
    final restored = repository();
    await restored.load();
    expect(restored.pendingCount, 1);
    expect(restored.plants.single.name, 'Updated orchid');
    offline = false;
    await restored.sync();
    expect(restored.pendingCount, 0);
    expect(byAccount['account-a']![synced.id]!['name'], 'Updated orchid');

    final serverPlant = byAccount['account-a']![synced.id]!;
    serverPlant['name'] = 'Desktop orchid';
    serverPlant['revision'] = (serverPlant['revision'] as int) + 1;
    offline = true;
    await restored.save(restored.plants.single.copyWith(name: 'Phone orchid'));
    offline = false;
    await restored.sync();
    expect(restored.conflicts, contains(synced.id));
    expect(restored.pendingCount, 1);
    await restored.resolveConflict(synced.id, useServer: false);
    expect(restored.pendingCount, 0);
    expect(byAccount['account-a']![synced.id]!['name'], 'Phone orchid');

    serverPlant['name'] = 'Desktop orchid';
    serverPlant['revision'] =
        (byAccount['account-a']![synced.id]!['revision'] as int) + 1;
    byAccount['account-a']![synced.id] = serverPlant;
    offline = true;
    await restored.save(
      restored.plants.single.copyWith(name: 'Another phone edit'),
    );
    offline = false;
    await restored.sync();
    expect(restored.conflicts, contains(synced.id));
    await restored.resolveConflict(synced.id, useServer: true);
    expect(restored.plants.single.name, 'Desktop orchid');
    expect(restored.pendingCount, 0);

    await restored.delete(restored.plants.single);
    expect(restored.plants, isEmpty);
    expect(byAccount['account-a']![synced.id]!['deletedAt'], isNotNull);

    credentials.value = 'account-b';
    await restored.sync();
    expect(restored.syncError, contains('account changed'));
    expect(byAccount['account-b'], isNull);
    final secondAccount = repository();
    await secondAccount.load();
    expect(secondAccount.plants.single.id, 'legacy-1');
    expect(secondAccount.localOnlyCount, 1);
    expect(byAccount['account-b'], isEmpty);
  });
}
