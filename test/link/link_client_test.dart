import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/link/link_client.dart';

void main() {
  test('validates Link info against a mock HomePlace server', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/api/link/info');
      request.response.headers.contentType = ContentType.json;
      request.response.write('''
        {
          "product": "HomePlace",
          "server": {
            "id": "9d55059f-5a47-4f23-a778-5714c6744907",
            "name": "Mock Home"
          },
          "protocol": {"min": 1, "max": 1},
          "serverTime": "2026-09-13T12:00:00Z",
          "features": {"pairing": true, "realtime": true}
        }
      ''');
      await request.response.close();
    });
    final normalized = ServerAddressNormalizer.normalize(
      'http://127.0.0.1:${server.port}',
    ) as ValidAddress;

    final result = await const HttpLinkService().fetchInfo(normalized.address);

    expect(result, isA<LinkSuccess>());
    expect((result as LinkSuccess).value.server.name, 'Mock Home');
  });

  test('rejects an oversized server response', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      request.response.write('x' * 65537);
      await request.response.close();
    });
    final normalized = ServerAddressNormalizer.normalize(
      'http://127.0.0.1:${server.port}',
    ) as ValidAddress;

    final result = await const HttpLinkService().fetchInfo(normalized.address);

    expect(result, isA<LinkFailure>());
    expect((result as LinkFailure).kind, LinkFailureKind.invalidResponse);
  });
}
