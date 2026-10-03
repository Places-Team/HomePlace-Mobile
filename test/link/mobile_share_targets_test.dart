import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/link/link_client.dart';
import 'package:homeplace/link/mobile_api.dart';
import 'package:homeplace/link/mobile_models.dart';

void main() {
  test('loads approved share devices without the full home overview', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      expect(request.uri.path, '/api/link/mobile/share');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer paired-credential',
      );
      request.response.headers.contentType = ContentType.json;
      request.response.write('''{"targets":[{
        "id":"mac-1","name":"Family Mac","platform":"macos",
        "supportsText":true,"supportsUrl":true,"supportsFile":true,
        "online":true,"ownedByCurrentUser":true
      }]}''');
      await request.response.close();
    });
    final session = AuthenticatedLinkSession(
      address: ServerAddress(
        uri: Uri.parse('http://127.0.0.1:${server.port}'),
        isLocal: true,
        security: ConnectionSecurity.localHttp,
      ),
      credential: 'paired-credential',
      serverId: 'server-1',
      serverName: 'HomePlace',
    );
    final response = await const MobileApi().shareTargets(session);
    expect(response, isA<LinkSuccess<List<MobileShareTarget>>>());
    expect(
      (response as LinkSuccess<List<MobileShareTarget>>).value.single.name,
      'Family Mac',
    );
  });
}
