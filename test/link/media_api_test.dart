import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/link/link_client.dart';
import 'package:homeplace/link/media_api.dart';

void main() {
  test(
    'poster uses authenticated bounded transport and rejects invalid content',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer secret',
        );
        request.response.headers.contentType = ContentType('image', 'png');
        request.response.add([137, 80, 78, 71]);
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
      const api = MediaApi();
      expect(
        await api.poster(session, 'https://other.example/steal'),
        isA<LinkFailure>(),
      );
      final result = await api.poster(session, '/api/media/tmdb-image?path=x');
      expect(result, isA<LinkSuccess>());
      expect((result as LinkSuccess).value, [137, 80, 78, 71]);
    },
  );
  test(
    'catalog, details and requests use paired server and credential',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final paths = <String>[];
      Map<String, dynamic>? requestBody;
      server.listen((request) async {
        paths.add('${request.method} ${request.uri}');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer secret',
        );
        request.response.headers.contentType = ContentType.json;
        if (request.uri.path == '/api/link/media' && request.method == 'GET') {
          request.response.write(
            jsonEncode({
              'configured': true,
              'page': 1,
              'pages': 1,
              'items': [
                {
                  'id': 42,
                  'kind': 'tv',
                  'title': 'Русское название',
                  'originalTitle': 'Original',
                  'overview': 'Description',
                  'status': 'missing',
                  'poster':
                      '/api/media/tmdb-image?size=w500&path=%2Fposter.jpg',
                },
              ],
            }),
          );
        } else if (request.uri.path == '/api/link/media/tv/42') {
          request.response.write(
            jsonEncode({
              'details': {
                'id': 42,
                'kind': 'tv',
                'title': 'Русское название',
                'overview': 'Description',
                'status': 'missing',
                'seasons': [
                  {'number': 1, 'name': 'One'},
                ],
              },
              'profiles': [
                {'key': 'server-1', 'label': 'HD'},
              ],
            }),
          );
        } else if (request.uri.path == '/api/link/media/requests') {
          requestBody = jsonDecode(
            await utf8.decoder.bind(request).join(),
          ) as Map<String, dynamic>;
          request.response.statusCode = HttpStatus.created;
          request.response.write(jsonEncode({'ok': true}));
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
      const api = MediaApi();
      final catalog = await api.discover(
        session,
        query: 'Ёлка',
        kind: 'tv',
        category: 'all',
        language: 'ru',
        page: 1,
      );
      expect(catalog, isA<LinkSuccess<MediaCatalog>>());
      final title = (catalog as LinkSuccess<MediaCatalog>).value.items.single;
      expect(title.title, 'Русское название');
      expect(title.poster, isNotNull);
      final details = await api.details(session, title, 'ru');
      expect(details, isA<LinkSuccess<MediaDetails>>());
      expect(
        (details as LinkSuccess<MediaDetails>).value.seasons.single.number,
        1,
      );
      final requested = await api.request(
        session,
        title,
        seasons: [1],
        profileKey: 'server-1',
      );
      expect(requested, isA<LinkSuccess<void>>());
      expect(requestBody, {
        'kind': 'tv',
        'mediaId': 42,
        'seasons': [1],
        'profileKey': 'server-1',
      });
      expect(paths[0], contains('q=%D0%81%D0%BB%D0%BA%D0%B0'));
      expect(paths[0], contains('lang=ru'));
      expect(paths[1], contains('/tv/42?lang=ru'));
    },
  );

  test('rejects external and malformed artwork locations', () {
    expect(safeMediaImagePath('https://another.example/poster.jpg'), isNull);
    expect(safeMediaImagePath('//another.example/poster.jpg'), isNull);
    expect(safeMediaImagePath('/api/media/tmdb-image?size=w500'), isNotNull);
    expect(safeMediaImagePath('/api/link/media/requests'), isNull);
  });

  test('distinguishes unconfigured and unavailable catalogs', () {
    final unconfigured = MediaCatalog.fromJson({
      'configured': false,
      'page': 1,
      'pages': 1,
      'items': <Object>[],
    });
    final unavailable = MediaCatalog.fromJson({
      'configured': true,
      'unavailable': true,
      'page': 1,
      'pages': 1,
      'items': <Object>[],
    });
    expect(unconfigured.configured, isFalse);
    expect(unconfigured.unavailable, isFalse);
    expect(unavailable.configured, isTrue);
    expect(unavailable.unavailable, isTrue);
  });
}
