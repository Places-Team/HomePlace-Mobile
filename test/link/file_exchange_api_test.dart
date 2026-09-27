import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/link/exchange_api.dart';
import 'package:homeplace/link/link_client.dart';
import 'package:homeplace/link/models.dart';

void main() {
  test('parses server limits and keeps old servers compatible', () {
    final json = {
      'product': 'HomePlace',
      'server': {'id': 'e54f9bfa-2543-4be2-bc07-c1eb3d0947ee', 'name': 'Test'},
      'protocol': {'min': 1, 'max': 1},
      'serverTime': '2026-09-28T00:00:00.000Z',
      'features': {'pairing': true, 'realtime': false},
    };
    expect(ServerInfo.fromJson(json).maxFileBytes, isNull);
    expect(
      ServerInfo.fromJson({
        ...json,
        'limits': {'maxFileBytes': 10 * 1024 * 1024 * 1024},
      }).maxFileBytes,
      10 * 1024 * 1024 * 1024,
    );
  });

  test(
    'streams a file with the canonical exchange headers and verifies download',
    () async {
      const token = 'abcdefghijklmnopqrstuv';
      final directory = await Directory.systemTemp.createTemp('exchange-test-');
      addTearDown(() => directory.delete(recursive: true));
      final contents = List<int>.generate(256 * 1024, (index) => index % 251);
      final source = File('${directory.path}/source.zip');
      await source.writeAsBytes(contents);
      final destination = File('${directory.path}/download.zip');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final requests = <String>[];
      final headers = <String, String?>{};
      var uploaded = <int>[];
      server.listen((request) async {
        requests.add('${request.method} ${request.uri}');
        if (request.uri.path != '/api/link/info') {
          expect(
            request.headers.value(HttpHeaders.authorizationHeader),
            'Bearer secret',
          );
        }
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path == '/api/link/info') {
          request.response.write(
            jsonEncode({
              'product': 'HomePlace',
              'server': {
                'id': 'e54f9bfa-2543-4be2-bc07-c1eb3d0947ee',
                'name': 'Test',
              },
              'protocol': {'min': 1, 'max': 1},
              'serverTime': '2026-09-28T00:00:00.000Z',
              'features': {'pairing': true, 'realtime': false},
              'limits': {'maxFileBytes': 1024 * 1024},
            }),
          );
        } else if (request.method == 'POST') {
          for (final name in [
            'x-homeplace-size',
            'x-homeplace-filename-base64',
            'x-homeplace-expires',
            'x-homeplace-access',
            'x-homeplace-delete-after-open',
            'x-homeplace-quick',
          ]) {
            headers[name] = request.headers.value(name);
          }
          uploaded = await request.expand((bytes) => bytes).toList();
          request.response.statusCode = HttpStatus.created;
          request.response.write(
            jsonEncode({
              'exchange': {
                ..._fileJson(token, contents.length),
                if (request.headers.value('x-homeplace-quick') == 'true')
                  'shortCode': 'Ab3Xy',
                if (request.headers.value('x-homeplace-quick') == 'true')
                  'access': 'link',
              },
            }),
          );
        } else if (request.uri.path == '/api/exchange') {
          request.response.write(
            jsonEncode({
              'exchanges': [_fileJson(token, contents.length)],
            }),
          );
        } else if (request.uri.path.endsWith('/file')) {
          request.response.headers.contentType = ContentType.binary;
          request.response.contentLength = contents.length;
          request.response.headers.set(
            'x-homeplace-sha256',
            sha256.convert(contents).toString(),
          );
          request.response.add(contents);
        } else {
          request.response.write(
            jsonEncode({'exchange': _fileJson(token, contents.length)}),
          );
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
        serverId: 'e54f9bfa-2543-4be2-bc07-c1eb3d0947ee',
        serverName: 'Test',
      );
      const api = ExchangeApi();
      final created = await api.createFile(
        session,
        source,
        filename: 'archive.zip',
        mimeType: 'application/zip',
        expiresInSeconds: 600,
        access: 'account',
        deleteAfterOpen: true,
      );
      expect(created, isA<LinkSuccess<FileExchange>>());
      expect(uploaded, contents);
      expect(headers, {
        'x-homeplace-size': '${contents.length}',
        'x-homeplace-filename-base64': base64Encode(utf8.encode('archive.zip')),
        'x-homeplace-expires': '600',
        'x-homeplace-access': 'account',
        'x-homeplace-delete-after-open': 'true',
        'x-homeplace-quick': null,
      });
      final quick = await api.createFile(
        session,
        source,
        filename: 'archive.zip',
        mimeType: 'application/zip',
        expiresInSeconds: 3600,
        access: 'account',
        deleteAfterOpen: false,
        quick: true,
      );
      expect((quick as LinkSuccess<FileExchange>).value.shortCode, 'Ab3Xy');
      expect(headers['x-homeplace-quick'], 'true');
      final listed = await api.listFiles(session);
      expect(
        (listed as LinkSuccess<List<FileExchange>>).value.single.filename,
        'archive.zip',
      );
      final inspected = await api.inspectFile(session, token);
      expect(inspected, isA<LinkSuccess<FileExchange>>());
      final downloaded = await api.downloadFile(
        session,
        (inspected as LinkSuccess<FileExchange>).value,
        destination: destination,
      );
      expect(downloaded, isA<LinkSuccess<DownloadedLinkFile>>());
      expect(await destination.readAsBytes(), contents);
      expect(requests, [
        'GET /api/link/info',
        'POST /api/exchange/file',
        'GET /api/link/info',
        'POST /api/exchange/file',
        'GET /api/exchange',
        'GET /api/exchange/$token',
        'GET /api/exchange/$token/file',
      ]);
    },
  );
}

Map<String, Object?> _fileJson(String token, int size) => {
  'token': token,
  'kind': 'file',
  'filename': 'archive.zip',
  'mimeType': 'application/zip',
  'size': size,
  'access': 'account',
  'deleteAfterOpen': true,
  'expiresAt': '2026-09-28T00:00:00.000Z',
};
