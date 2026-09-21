import 'dart:io';

import '../features/connection/connection_controller.dart';
import '../core/sharing/share_service.dart';
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

  Future<LinkResult<void>> updateReminder(
    AuthenticatedLinkSession session,
    MobileReminder reminder, {
    required String title,
    required DateTime at,
    required String repeat,
  }) => _empty(session, '/api/link/mobile/reminders', {
    'action': 'update',
    'id': reminder.id,
    'title': title,
    'at': at.toUtc().toIso8601String(),
    'repeat': repeat,
  });

  Future<LinkResult<void>> reopenReminder(
    AuthenticatedLinkSession session,
    String id,
  ) => _empty(session, '/api/link/mobile/reminders', {
    'action': 'reopen',
    'id': id,
  });

  Future<LinkResult<void>> deleteCompletedReminders(
    AuthenticatedLinkSession session,
  ) => _empty(session, '/api/link/mobile/reminders', {
    'action': 'deleteCompleted',
  });

  Future<LinkResult<void>> deleteReminder(
    AuthenticatedLinkSession session,
    String id,
  ) => _empty(session, '/api/link/mobile/reminders', {
    'action': 'delete',
    'id': id,
  });

  Future<LinkResult<List<MobileCalendarEvent>>> calendar(
    AuthenticatedLinkSession session,
    DateTime from,
    DateTime to,
  ) async {
    final query = Uri(
      path: '/api/link/calendar',
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );
    final response = await _client.requestJson(
      session.address,
      'GET',
      query.toString(),
      credential: session.credential,
      maxResponseBytes: 524288,
    );
    return _decode(
      response,
      (json) => (json['events'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MobileCalendarEvent.fromJson)
          .toList(growable: false),
      'HomePlace returned invalid calendar events.',
    );
  }

  Future<LinkResult<void>> saveCalendarEvent(
    AuthenticatedLinkSession session, {
    MobileCalendarEvent? existing,
    required String summary,
    required DateTime start,
    required DateTime end,
    required bool allDay,
    String? location,
  }) => _empty(session, '/api/link/calendar', {
    'action': existing == null ? 'create' : 'update',
    if (existing != null) 'id': existing.id,
    'summary': summary,
    'start': allDay ? _dateOnly(start) : start.toUtc().toIso8601String(),
    'end': allDay ? _dateOnly(end) : end.toUtc().toIso8601String(),
    'allDay': allDay,
    if (location?.trim().isNotEmpty == true) 'location': location!.trim(),
  });

  Future<LinkResult<void>> deleteCalendarEvent(
    AuthenticatedLinkSession session,
    String id,
  ) => _empty(session, '/api/link/calendar', {'action': 'delete', 'id': id});

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

  Future<LinkResult<void>> relayShare(
    AuthenticatedLinkSession session,
    MobileShareTarget target,
    SharedContent content, {
    void Function(int transferred, int total)? onProgress,
    LinkTransferCancellation? cancellation,
  }) {
    if (content.kind == SharedContentKind.file) {
      return _client.uploadFile(
        session.address,
        '/api/link/mobile/share/file',
        session.credential,
        File(content.path!),
        targetDeviceId: target.id,
        filename: content.filename!,
        mimeType: content.mimeType ?? 'application/octet-stream',
        onProgress: onProgress,
        cancellation: cancellation,
      );
    }
    return _empty(session, '/api/link/mobile/share', {
      'targetDeviceId': target.id,
      'type': content.kind.name,
      'value': content.value,
    });
  }

  Future<LinkResult<DownloadedLinkFile>> downloadSharedFile(
    AuthenticatedLinkSession session,
    String transferId, {
    required int expectedSize,
    required String expectedSha256,
    void Function(int transferred, int total)? onProgress,
    LinkTransferCancellation? cancellation,
  }) => _client.downloadFileToTemporary(
    session.address,
    '/api/link/mobile/share/file/${Uri.encodeComponent(transferId)}',
    session.credential,
    expectedSize: expectedSize,
    expectedSha256: expectedSha256,
    onProgress: onProgress,
    cancellation: cancellation,
  );

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

String _dateOnly(DateTime value) =>
    '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
