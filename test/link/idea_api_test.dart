import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/link/idea_api.dart';
import 'package:homeplace/link/link_client.dart';

void main() {
  test('ideas requests use the authenticated Link route and cursor', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final requests = <String>[];
    server.listen((request) async {
      requests.add('${request.method} ${request.uri}');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer test-token',
      );
      if (request.method == 'POST') {
        expect(jsonDecode(await utf8.decoder.bind(request).join()), {
          'action': 'createIdea',
          'title': 'Water fern',
        });
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'categories': <Object>[],
          'ideas': <Object>[],
          'nextCursor': null,
        }),
      );
      await request.response.close();
    });
    final session = AuthenticatedLinkSession(
      address: ServerAddress(
        uri: Uri.parse('http://127.0.0.1:${server.port}'),
        isLocal: true,
        security: ConnectionSecurity.localHttp,
      ),
      credential: 'test-token',
      serverId: 'server-1',
      serverName: 'Home',
    );
    const api = IdeaApi();
    expect(await api.page(session, cursor: 'next-1'), isA<LinkSuccess>());
    expect(await api.page(session, archived: true), isA<LinkSuccess>());
    expect(
      await api.command(session, {
        'action': 'createIdea',
        'title': 'Water fern',
      }),
      isA<LinkSuccess>(),
    );
    expect(requests, [
      'GET /api/link/ideas?cursor=next-1',
      'GET /api/link/ideas?archived=1',
      'POST /api/link/ideas',
    ]);
  });
}
