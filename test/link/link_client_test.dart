import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/core/sharing/share_service.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/link/link_client.dart';
import 'package:homeplace/link/mobile_api.dart';
import 'package:homeplace/link/mobile_models.dart';

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

  test('loads the authenticated mobile dashboard from a mock server', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      expect(request.uri.path, '/api/link/mobile/overview');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer test-credential',
      );
      request.response.headers.contentType = ContentType.json;
      request.response.write('''
        {
          "serverTime":"2026-09-20T10:00:00Z",
          "permissions":["dashboard.read"],
          "reminders":[],
          "calendar":{"connected":false,"email":null,"events":[]},
          "requests":{"instances":[],"qbittorrent":null},
          "telegram":{"connected":false,"enabled":false,"source":"none"},
          "monitoring":{"total":1,"online":1,"offline":0,"unknown":0,"services":[],"recent":[]}
        }
      ''');
      await request.response.close();
    });
    final normalized = ServerAddressNormalizer.normalize(
      'http://127.0.0.1:${server.port}',
    ) as ValidAddress;
    final session = AuthenticatedLinkSession(
      address: normalized.address,
      credential: 'test-credential',
      serverId: '9d55059f-5a47-4f23-a778-5714c6744907',
      serverName: 'Mock Home',
    );

    final result = await const MobileApi().overview(session);

    expect(result, isA<LinkSuccess>());
    expect((result as LinkSuccess).value.monitoring.online, 1);
  });

  test('loads a bounded calendar range from the Link calendar API', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    server.listen((request) async {
      expect(request.uri.path, '/api/link/calendar');
      expect(request.uri.queryParameters.keys, containsAll(['from', 'to']));
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer test-credential',
      );
      request.response.headers.contentType = ContentType.json;
      request.response.write('''
        {"status":"connected","events":[{
          "id":"event_1","summary":"Family dinner",
          "start":"2026-09-21T16:00:00.000Z",
          "end":"2026-09-21T18:00:00.000Z",
          "allDay":false,"location":"Home"
        }]}
      ''');
      await request.response.close();
    });
    final normalized = ServerAddressNormalizer.normalize(
      'http://127.0.0.1:${server.port}',
    ) as ValidAddress;
    final session = AuthenticatedLinkSession(
      address: normalized.address,
      credential: 'test-credential',
      serverId: '9d55059f-5a47-4f23-a778-5714c6744907',
      serverName: 'Mock Home',
    );

    final result = await const MobileApi().calendar(
      session,
      DateTime.utc(2026, 9, 1),
      DateTime.utc(2026, 10, 1),
    );

    expect(result, isA<LinkSuccess>());
    expect((result as LinkSuccess).value.single.summary, 'Family dinner');
  });

  test('uploads and downloads a shared file through the Link API', () async {
    final expected = Uint8List(6 * 1024 * 1024 + 17);
    for (var index = 0; index < expected.length; index++) {
      expected[index] = index % 251;
    }
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    final temp = await Directory.systemTemp.createTemp('homeplace-file-test-');
    addTearDown(() => temp.delete(recursive: true));
    final file = File('${temp.path}/family note.txt');
    await file.writeAsBytes(expected);
    var uploadVerified = false;
    server.listen((request) async {
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer test-credential',
      );
      if (request.uri.path == '/api/link/mobile/share/file') {
        expect(request.method, 'POST');
        expect(request.headers.value('x-homeplace-target'), 'target-1');
        expect(
          request.headers.value('x-homeplace-filename-base64'),
          '0YHQtdC80YzRjy50eHQ=',
        );
        expect(
          await request.fold<List<int>>([], (all, part) => all..addAll(part)),
          expected,
        );
        uploadVerified = true;
        request.response.statusCode = HttpStatus.created;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"ok":true}');
      } else if (request.uri.path == '/api/link/mobile/share/file/transfer-1') {
        expect(request.method, 'GET');
        request.response.statusCode = HttpStatus.ok;
        request.response.headers.contentType = ContentType.binary;
        request.response.headers.set(
          'x-homeplace-sha256',
          sha256.convert(expected).toString(),
        );
        request.response.add(expected);
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });
    final normalized = ServerAddressNormalizer.normalize(
      'http://127.0.0.1:${server.port}',
    ) as ValidAddress;
    final session = AuthenticatedLinkSession(
      address: normalized.address,
      credential: 'test-credential',
      serverId: '9d55059f-5a47-4f23-a778-5714c6744907',
      serverName: 'Mock Home',
    );
    const target = MobileShareTarget(
      id: 'target-1',
      name: 'Family tablet',
      platform: 'android',
      supportsText: true,
      supportsUrl: true,
      supportsFile: true,
      online: true,
      ownedByCurrentUser: true,
    );

    final sent = await const MobileApi().relayShare(
      session,
      target,
      SharedContent(
        kind: SharedContentKind.file,
        path: file.path,
        filename: 'семья.txt',
        mimeType: 'text/plain',
        size: expected.length,
      ),
    );
    final received = await const MobileApi().downloadSharedFile(
      session,
      'transfer-1',
      expectedSize: expected.length,
      expectedSha256: sha256.convert(expected).toString(),
    );

    expect(sent, isA<LinkSuccess<void>>());
    expect(uploadVerified, isTrue);
    expect(received, isA<LinkSuccess<DownloadedLinkFile>>());
    final downloaded = (received as LinkSuccess<DownloadedLinkFile>).value;
    expect(await downloaded.file.readAsBytes(), expected);
    await downloaded.file.parent.delete(recursive: true);
  });
}
