import 'dart:convert';

import '../features/connection/connection_controller.dart';
import 'link_client.dart';

final class TextExchange {
  const TextExchange({
    required this.token,
    required this.access,
    required this.expiresAt,
    required this.deleteAfterOpen,
  });

  final String token;
  final String access;
  final DateTime expiresAt;
  final bool deleteAfterOpen;

  static TextExchange fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['kind'] != 'text' ||
        value['token'] is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{22}$').hasMatch(value['token'] as String) ||
        value['access'] != 'account' && value['access'] != 'link' ||
        value['deleteAfterOpen'] is! bool) {
      throw const FormatException('Invalid text exchange.');
    }
    final expiresAt = DateTime.tryParse(value['expiresAt']?.toString() ?? '');
    if (expiresAt == null) {
      throw const FormatException('Invalid exchange expiry.');
    }
    return TextExchange(
      token: value['token'] as String,
      access: value['access'] as String,
      expiresAt: expiresAt,
      deleteAfterOpen: value['deleteAfterOpen'] as bool,
    );
  }
}

abstract interface class ExchangeGateway {
  Future<LinkResult<List<TextExchange>>> list(AuthenticatedLinkSession session);
  Future<LinkResult<TextExchange>> createText(
    AuthenticatedLinkSession session,
    String text, {
    required int expiresInSeconds,
    required bool deleteAfterOpen,
  });
  Future<LinkResult<void>> revoke(
    AuthenticatedLinkSession session,
    String token,
  );
}

final class ExchangeApi implements ExchangeGateway {
  const ExchangeApi({HttpLinkService? client})
    : _client = client ?? const HttpLinkService();

  final HttpLinkService _client;

  @override
  Future<LinkResult<List<TextExchange>>> list(
    AuthenticatedLinkSession session,
  ) async {
    final response = await _client.requestJson(
      session.address,
      'GET',
      '/api/exchange',
      credential: session.credential,
      maxResponseBytes: 131072,
    );
    if (response case LinkFailure<Map<String, dynamic>> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    try {
      final rows =
          (response as LinkSuccess<Map<String, dynamic>>).value['exchanges'];
      if (rows is! List || rows.length > 100) {
        throw const FormatException('Invalid exchange list.');
      }
      return LinkSuccess([
        for (final row in rows)
          if (row is Map<String, dynamic> && row['kind'] == 'text')
            TextExchange.fromJson(row),
      ]);
    } on FormatException {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'HomePlace returned an invalid exchange list.',
      );
    }
  }

  @override
  Future<LinkResult<TextExchange>> createText(
    AuthenticatedLinkSession session,
    String text, {
    required int expiresInSeconds,
    required bool deleteAfterOpen,
  }) async {
    if (text.trim().isEmpty ||
        utf8.encode(text).length > 16384 ||
        !const [600, 3600, 86400].contains(expiresInSeconds)) {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'Text or expiry is invalid.',
      );
    }
    final response = await _client.requestJson(
      session.address,
      'POST',
      '/api/exchange',
      credential: session.credential,
      body: {
        'text': text,
        'expiresInSeconds': expiresInSeconds,
        'access': 'account',
        'deleteAfterOpen': deleteAfterOpen,
      },
    );
    if (response case LinkFailure<Map<String, dynamic>> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    try {
      final exchange = TextExchange.fromJson(
        (response as LinkSuccess<Map<String, dynamic>>).value['exchange'],
      );
      if (exchange.access != 'account') {
        throw const FormatException('Unexpected exchange access.');
      }
      return LinkSuccess(exchange);
    } on FormatException {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'HomePlace returned an invalid exchange.',
      );
    }
  }

  @override
  Future<LinkResult<void>> revoke(
    AuthenticatedLinkSession session,
    String token,
  ) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{22}$').hasMatch(token)) {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'Invalid exchange token.',
      );
    }
    final response = await _client.requestJson(
      session.address,
      'DELETE',
      '/api/exchange/$token',
      credential: session.credential,
    );
    if (response case LinkFailure<Map<String, dynamic>> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    return const LinkSuccess(null);
  }
}
