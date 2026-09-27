import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/features/exchange/text_exchange_card.dart';
import 'package:homeplace/link/exchange_api.dart';
import 'package:homeplace/link/link_client.dart';
import 'package:homeplace/l10n/generated/app_localizations.dart';

final class _Gateway implements ExchangeGateway {
  final exchanges = <TextExchange>[];
  String? createdText;
  int? lifetime;
  bool? oneTime;

  @override
  Future<LinkResult<List<TextExchange>>> list(
    AuthenticatedLinkSession session,
  ) async => LinkSuccess(List.of(exchanges));

  @override
  Future<LinkResult<TextExchange>> createText(
    AuthenticatedLinkSession session,
    String text, {
    required int expiresInSeconds,
    required bool deleteAfterOpen,
  }) async {
    createdText = text;
    lifetime = expiresInSeconds;
    oneTime = deleteAfterOpen;
    final exchange = TextExchange(
      token: 'abcdefghijklmnopqrstuv',
      access: 'account',
      expiresAt: DateTime.utc(2026, 9, 28),
      deleteAfterOpen: deleteAfterOpen,
    );
    exchanges.add(exchange);
    return LinkSuccess(exchange);
  }

  @override
  Future<LinkResult<void>> revoke(
    AuthenticatedLinkSession session,
    String token,
  ) async {
    exchanges.removeWhere((entry) => entry.token == token);
    return const LinkSuccess(null);
  }
}

void main() {
  testWidgets('creates and revokes a private text link with confirmation', (
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
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: TextExchangeCard(
              sessionProvider: () async => session,
              available: true,
              clipboardRelayEnabled: true,
              gateway: gateway,
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Open temporary links'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Only your HomePlace account can open this link. Anyone with the link and access to your account may read it.',
      ),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('exchange-text')),
      'Watering schedule',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('Create private link'));
    await tester.tap(find.text('Create private link'));
    await tester.pumpAndSettle();
    expect(gateway.createdText, 'Watering schedule');
    expect(gateway.lifetime, 3600);
    expect(gateway.oneTime, false);
    expect(find.text('Private text link'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Copy link'));
    await tester.tap(find.byTooltip('Copy link'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Automatic clipboard sharing is on. Copying this link may send it to your approved devices.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Revoke link'));
    await tester.tap(find.byTooltip('Revoke link'));
    await tester.pumpAndSettle();
    expect(gateway.exchanges, hasLength(1));
    await tester.tap(find.text('Revoke link').last);
    await tester.pumpAndSettle();
    expect(gateway.exchanges, isEmpty);
  });
}
