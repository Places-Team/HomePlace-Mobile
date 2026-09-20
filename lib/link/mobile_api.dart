import '../features/connection/connection_controller.dart';
import 'link_client.dart';
import 'mobile_models.dart';

final class MobileApi {
  const MobileApi({HttpLinkService? client})
    : _client = client ?? const HttpLinkService();
  final HttpLinkService _client;

  Future<LinkResult<MobileOverview>> overview(
    AuthenticatedLinkSession session,
  ) async {
    final response = await _client.requestJson(
      session.address,
      'GET',
      '/api/link/mobile/overview',
      credential: session.credential,
      maxResponseBytes: 524288,
    );
    return _decode(
      response,
      MobileOverview.fromJson,
      'HomePlace returned an invalid mobile overview.',
    );
  }

  Future<LinkResult<void>> createReminder(
    AuthenticatedLinkSession session, {
    required String title,
    required DateTime at,
    required String repeat,
  }) => _empty(session, '/api/link/mobile/reminders', {
    'action': 'create',
    'title': title,
    'at': at.toUtc().toIso8601String(),
    'repeat': repeat,
  });

  Future<LinkResult<void>> completeReminder(
    AuthenticatedLinkSession session,
    String id,
  ) => _empty(session, '/api/link/mobile/reminders', {
    'action': 'complete',
    'id': id,
  });

  Future<LinkResult<void>> deleteReminder(
    AuthenticatedLinkSession session,
    String id,
  ) => _empty(session, '/api/link/mobile/reminders', {
    'action': 'delete',
    'id': id,
  });

  Future<LinkResult<List<MobileSearchResult>>> search(
    AuthenticatedLinkSession session,
    String query,
  ) async {
    final response = await _client.requestJson(
      session.address,
      'GET',
      '/api/link/mobile/requests/search?q=${Uri.encodeQueryComponent(query)}',
      credential: session.credential,
      maxResponseBytes: 262144,
    );
    return _decode(
      response,
      (json) => (json['results'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MobileSearchResult.fromJson)
          .toList(growable: false),
      'HomePlace returned invalid search results.',
    );
  }

  Future<LinkResult<void>> addRequest(
    AuthenticatedLinkSession session,
    MobileSearchResult item,
  ) => _empty(session, '/api/link/mobile/requests', {
    'instanceLabel': item.instanceLabel,
    'externalId': item.externalId,
  });

  Future<LinkResult<void>> testTelegram(AuthenticatedLinkSession session) =>
      _empty(session, '/api/link/mobile/telegram', const {});

  Future<LinkResult<int>> relayClipboard(
    AuthenticatedLinkSession session,
    String text,
  ) async {
    final response = await _client.requestJson(
      session.address,
      'POST',
      '/api/link/mobile/clipboard',
      credential: session.credential,
      body: {'text': text},
    );
    return _decode(
      response,
      (json) => (json['recipients'] as num?)?.round() ?? 0,
      'HomePlace returned an invalid clipboard response.',
    );
  }

  Future<LinkResult<void>> _empty(
    AuthenticatedLinkSession session,
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.requestJson(
      session.address,
      'POST',
      path,
      credential: session.credential,
      body: body,
    );
    if (response case LinkFailure<Map<String, dynamic>> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    return const LinkSuccess(null);
  }

  LinkResult<T> _decode<T>(
    LinkResult<Map<String, dynamic>> response,
    T Function(Map<String, dynamic>) parse,
    String invalidMessage,
  ) {
    if (response case LinkFailure<Map<String, dynamic>> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    try {
      return LinkSuccess(
        parse((response as LinkSuccess<Map<String, dynamic>>).value),
      );
    } on Object {
      return LinkFailure(LinkFailureKind.invalidResponse, invalidMessage);
    }
  }
}
