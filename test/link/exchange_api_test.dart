import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/link/exchange_api.dart';
import 'package:homeplace/link/link_client.dart';

void main() {
  test('creates, lists, and revokes account-only text exchanges', () async {
    const token = 'abcdefghijklmnopqrstuv';
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final requests = <String>[];
    final bodies = <Map<String, dynamic>>[];
    server.listen((request) async {
      requests.add('${request.method} ${request.uri}');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer secret',
      );
      if (request.method == 'POST') {
        bodies.add(
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>,
        );
      }
      request.response.headers.contentType = ContentType.json;
      if (request.method == 'GET') {
        request.response.write(
          jsonEncode({
            'exchanges': [
              {
                'token': token,
                'kind': 'text',
                'access': 'account',
                'expiresAt': '2026-09-28T00:00:00.000Z',
                'deleteAfterOpen': false,
              },
              {'kind': 'file'},
            ],
          }),
        );
      } else if (request.method == 'POST') {
        request.response.write(
          jsonEncode({
            'exchange': {
              'token': token,
              'kind': 'text',
              'access': 'account',
              'expiresAt': '2026-09-28T00:00:00.000Z',
              'deleteAfterOpen': true,
            },
          }),
        );
      } else {
        request.response.write('{"ok":true}');
      }
      await request.response.close();
    });
    final session = AuthenticatedLinkSession(
      address: ServerAddress(
        uri: Uri.parse('http://127.0.0.1:${server.port}'),
        isLocal: true,
        security: ConnectionSecurity.localHttp,
      ),
      credential: 'secret',
      serverId: 'server-1',
      serverName: 'Test',
    );
    const api = ExchangeApi();
    final list = await api.list(session);
    expect((list as LinkSuccess<List<TextExchange>>).value, hasLength(1));
    final created = await api.createText(
      session,
      'Private note',
      expiresInSeconds: 600,
      deleteAfterOpen: true,
    );
    expect(created, isA<LinkSuccess<TextExchange>>());
    expect(bodies.single, {
      'text': 'Private note',
      'expiresInSeconds': 600,
      'access': 'account',
      'deleteAfterOpen': true,
    });
    expect(await api.revoke(session, token), isA<LinkSuccess<void>>());
    expect(requests, [
      'GET /api/exchange',
      'POST /api/exchange',
      'DELETE /api/exchange/$token',
    ]);
  });

  test('rejects oversized UTF-8 text before sending', () async {
    final session = AuthenticatedLinkSession(
      address: ServerAddress(
        uri: Uri.parse('http://127.0.0.1'),
        isLocal: true,
        security: ConnectionSecurity.localHttp,
      ),
      credential: 'secret',
      serverId: 'server-1',
      serverName: 'Test',
    );
    final result = await const ExchangeApi().createText(
      session,
      'ж' * 9000,
      expiresInSeconds: 3600,
      deleteAfterOpen: false,
    );
    expect(result, isA<LinkFailure<TextExchange>>());
  });
}
