import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/link/link_client.dart';
import 'package:homeplace/link/plant_api.dart';

void main() {
  test('settings and watering use authenticated account endpoints', () async {
    final requests = <String>[];
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      requests.add('${request.method} ${request.uri.path}');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer secret',
      );
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path.endsWith('/settings')) {
        if (request.method == 'PATCH') {
          final body = jsonDecode(await utf8.decoder.bind(request).join());
          expect(body['telegram'], true);
        }
        request.response.write(
          jsonEncode({
            'settings': {
              'enabled': true,
              'app': true,
              'telegram': true,
              'time': '09:00',
              'timeZone': 'Europe/Moscow',
              'repeatDays': 3,
            },
          }),
        );
      } else {
        final body = jsonDecode(await utf8.decoder.bind(request).join());
        expect(body['action'], 'water');
        expect(body['revision'], 4);
        expect(body['lastWateredAt'], isNotNull);
        request.response.write(jsonEncode({'plant': _plant(revision: 5)}));
      }
      await request.response.close();
    });
    final session = _session(server.port);
    const api = PlantApi();
    expect(
      (await api.getSettings(
        session,
      ) as LinkSuccess<PlantNotificationSettings>).value.repeatDays,
      3,
    );
    final settings = PlantNotificationSettings(
      enabled: true,
      app: true,
      telegram: true,
      time: '09:00',
      timeZone: 'Europe/Moscow',
      repeatDays: 3,
    );
    expect(
      await api.updateSettings(session, settings),
      isA<LinkSuccess<PlantNotificationSettings>>(),
    );
    final plant = RemotePlant.fromJson(_plant(revision: 4)).plant;
    expect(
      await api.command(session, 'water', plant, revision: 4),
      isA<LinkSuccess<RemotePlant>>(),
    );
    expect(requests, [
      'GET /api/link/plants/settings',
      'PATCH /api/link/plants/settings',
      'POST /api/link/plants',
    ]);
  });

  test(
    'private photo download and revision-checked upload stay on paired host',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final bytes = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);
      server.listen((request) async {
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer secret',
        );
        expect(
          request.uri.path,
          '/api/link/plants/e54f9bfa-2543-4be2-bc07-c1eb3d0947ee/photo',
        );
        if (request.method == 'GET') {
          request.response.headers.contentType = ContentType('image', 'jpeg');
          request.response.add(bytes);
        } else {
          expect(request.headers.value(HttpHeaders.ifMatchHeader), '4');
          expect(request.headers.contentType!.mimeType, 'image/jpeg');
          expect(
            await request.fold<int>(0, (count, chunk) => count + chunk.length),
            bytes.length,
          );
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({'plant': _plant(revision: 5)}));
        }
        await request.response.close();
      });
      final session = _session(server.port);
      const api = PlantApi();
      const id = 'e54f9bfa-2543-4be2-bc07-c1eb3d0947ee';
      final photo = PlantPhoto.fromJson({
        'url': '/api/link/plants/$id/photo',
        'version': '01234567-89ab-4cde-8f12-0123456789ab.jpg',
        'maxBytes': 12582912,
      }, id);
      final downloaded = await api.downloadPhoto(session, id, photo);
      expect((downloaded as LinkSuccess<Uint8List>).value, bytes);
      expect(
        await api.uploadPhoto(session, id, 4, bytes, 'image/jpeg'),
        isA<LinkSuccess<RemotePlant>>(),
      );
    },
  );
}

AuthenticatedLinkSession _session(int port) => AuthenticatedLinkSession(
  address: ServerAddress(
    uri: Uri.parse('http://127.0.0.1:$port'),
    isLocal: true,
    security: ConnectionSecurity.localHttp,
  ),
  credential: 'secret',
  serverId: 'e54f9bfa-2543-4be2-bc07-c1eb3d0947ee',
  serverName: 'Test',
);

Map<String, Object?> _plant({required int revision}) => {
  'clientId': 'e54f9bfa-2543-4be2-bc07-c1eb3d0947ee',
  'name': 'Fern',
  'species': '',
  'location': '',
  'notes': '',
  'intervalDays': 7,
  'lastWateredAt': '2026-10-01T00:00:00Z',
  'createdAt': '2026-10-01T00:00:00Z',
  'revision': revision,
  'deletedAt': null,
  'remindersEnabled': true,
  'photo': null,
};
