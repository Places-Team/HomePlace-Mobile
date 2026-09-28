import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/link/exchange_api.dart';
import 'package:homeplace/link/link_client.dart';

void main() {
  test(
    'resolves only a relative token path without sending credentials',
    () async {
      const serverId = 'e54f9bfa-2543-4be2-bc07-c1eb3d0947ee';
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      var actualServerId = serverId;
      var location = '/x/abcdefghijklmnopqrstuv';
      var shortCodeRequests = 0;
      server.listen((request) async {
        if (request.uri.path == '/api/link/info') {
          request.response.headers.contentType = ContentType.json;
          request.response.write(
            jsonEncode({
              'product': 'HomePlace',
              'server': {'id': actualServerId, 'name': 'Test'},
              'protocol': {'min': 1, 'max': 1},
              'serverTime': '2026-09-28T00:00:00.000Z',
              'features': {'pairing': true, 'realtime': false},
            }),
          );
        } else if (request.uri.path == '/f/Ab3Xy') {
          shortCodeRequests++;
          expect(
            request.headers.value(HttpHeaders.authorizationHeader),
            isNull,
          );
          request.response.statusCode = HttpStatus.seeOther;
          request.response.headers.set(HttpHeaders.locationHeader, location);
        } else {
          request.response.statusCode = HttpStatus.notFound;
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
        serverId: serverId,
        serverName: 'Test',
      );
      const api = ExchangeApi();
      final valid = await api.resolveShortCode(session, 'Ab3Xy');
      expect(valid, isA<LinkSuccess<String>>());
      expect((valid as LinkSuccess<String>).value, 'abcdefghijklmnopqrstuv');

      for (final rejected in [
        'https://another.example/x/abcdefghijklmnopqrstuv',
        '//another.example/x/abcdefghijklmnopqrstuv',
        '/x/abcdefghijklmnopqrstuv?next=other',
        '/x/abcdefghijklmnopqrstuv/extra',
      ]) {
        location = rejected;
        expect(
          await api.resolveShortCode(session, 'Ab3Xy'),
          isA<LinkFailure<String>>(),
        );
      }
    actualServerId = 'f15f9bfa-2543-4be2-bc07-c1eb3d0947ee';
      final before = shortCodeRequests;
      final changed = await api.resolveShortCode(session, 'Ab3Xy');
      expect(
        (changed as LinkFailure<String>).kind,
        LinkFailureKind.serverIdentity,
      );
      expect(shortCodeRequests, before);
    },
  );
}
