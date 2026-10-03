import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/features/media/media_catalog_view.dart';
import 'package:homeplace/link/link_client.dart';
import 'package:homeplace/link/media_api.dart';
import 'package:homeplace/l10n/generated/app_localizations.dart';

final class _Gateway implements MediaGateway {
  @override
  Future<LinkResult<Uint8List>> poster(
    AuthenticatedLinkSession session,
    String path,
  ) async => const LinkFailure(
    LinkFailureKind.invalidResponse,
    'No poster in fixture.',
  );
  String? query;
  String? category;
  String? language;
  String? profileKey;
  List<int>? seasons;
  int requests = 0;

  @override
  Future<LinkResult<MediaCatalog>> discover(
    AuthenticatedLinkSession session, {
    required String query,
    required String kind,
    required String category,
    required String language,
    required int page,
  }) async {
    this.query = query;
    this.category = category;
    this.language = language;
    return MediaCatalog.fromJson({
      'configured': true,
      'page': 1,
      'pages': 1,
      'items': [
        {
          'id': 42,
          'kind': 'tv',
          'title': 'Тестовый сериал',
          'originalTitle': 'Test series',
          'overview': 'A test story.',
          'status': 'missing',
        },
      ],
    }).letSuccess();
  }

  @override
  Future<LinkResult<MediaDetails>> details(
    AuthenticatedLinkSession session,
    MediaTitle title,
    String language,
  ) async => LinkSuccess(
    MediaDetails.fromJson({
      'details': {
        'id': title.id,
        'kind': title.kind,
        'title': title.title,
        'overview': title.overview,
        'status': title.status,
        'seasons': [
          {'number': 1, 'name': 'One'},
          {'number': 2, 'name': 'Two'},
        ],
      },
      'profiles': [
        {'key': 'quality-1', 'label': 'HD'},
      ],
    }),
  );

  @override
  Future<LinkResult<void>> request(
    AuthenticatedLinkSession session,
    MediaTitle title, {
    List<int>? seasons,
    String? profileKey,
  }) async {
    requests++;
    this.seasons = seasons;
    this.profileKey = profileKey;
    return const LinkSuccess(null);
  }
}

extension on MediaCatalog {
  LinkSuccess<MediaCatalog> letSuccess() => LinkSuccess(this);
}

void main() {
  testWidgets('searches localized catalog and confirms selected season', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final gateway = _Gateway();
    final session = AuthenticatedLinkSession(
      address: ServerAddress(
        uri: Uri.parse('https://home.example.test'),
        isLocal: false,
        security: ConnectionSecurity.trustedHttps,
      ),
      credential: 'secret',
      serverId: 'server-1',
      serverName: 'Test',
    );
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: MediaCatalogView(
              sessionProvider: () async => session,
              available: true,
              gateway: gateway,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(gateway.language, 'ru');
    await tester.enterText(
      find.byKey(const ValueKey('media-catalog-search')),
      'Сериал',
    );
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(gateway.query, 'Сериал');
    await tester.tap(find.text('Аниме'));
    await tester.pumpAndSettle();
    expect(gateway.category, 'anime');
    await tester.tap(find.text('Тестовый сериал'));
    await tester.pumpAndSettle();
    expect(gateway.requests, 0);
    await tester.tap(find.text('По умолчанию на сервере'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('HD').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('1 · One'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Заказать'));
    await tester.pumpAndSettle();
    expect(gateway.requests, 1);
    expect(gateway.seasons, [1]);
    expect(gateway.profileKey, 'quality-1');
    expect(tester.takeException(), isNull);
  });
}
