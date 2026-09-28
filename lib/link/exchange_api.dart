import 'dart:convert';
import 'dart:io';

import '../features/connection/connection_controller.dart';
import 'link_client.dart';
import 'models.dart';

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

final class FileExchange {
  const FileExchange({
    required this.token,
    this.shortCode,
    required this.filename,
    required this.mimeType,
    required this.size,
    required this.access,
    required this.expiresAt,
    required this.deleteAfterOpen,
  });

  final String token;
  final String? shortCode;
  final String filename;
  final String mimeType;
  final int size;
  final String access;
  final DateTime expiresAt;
  final bool deleteAfterOpen;

  static FileExchange fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['kind'] != 'file' ||
        value['token'] is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{22}$').hasMatch(value['token'] as String) ||
        (value['shortCode'] != null &&
            (value['shortCode'] is! String ||
                !RegExp(r'^[1-9A-HJ-NP-Za-km-z]{5}$')
                    .hasMatch(value['shortCode'] as String))) ||
        value['filename'] is! String ||
        (value['filename'] as String).trim().isEmpty ||
        value['mimeType'] is! String ||
        value['size'] is! int ||
        (value['size'] as int) < 1 ||
        (value['size'] as int) > maxExchangeFileBytes ||
        value['access'] != 'account' && value['access'] != 'link' ||
        value['deleteAfterOpen'] is! bool) {
      throw const FormatException('Invalid file exchange.');
    }
    final expiresAt = DateTime.tryParse(value['expiresAt']?.toString() ?? '');
    if (expiresAt == null) {
      throw const FormatException('Invalid file exchange expiry.');
    }
    return FileExchange(
      token: value['token'] as String,
      shortCode: value['shortCode'] as String?,
      filename: value['filename'] as String,
      mimeType: value['mimeType'] as String,
      size: value['size'] as int,
      access: value['access'] as String,
      expiresAt: expiresAt,
      deleteAfterOpen: value['deleteAfterOpen'] as bool,
    );
  }
}

abstract interface class FileExchangeGateway {
  Future<LinkResult<int>> fileLimit(AuthenticatedLinkSession session);
  Future<LinkResult<String>> resolveShortCode(
    AuthenticatedLinkSession session,
    String code,
  );
  Future<LinkResult<FileExchange>> inspectFile(
    AuthenticatedLinkSession session,
    String token,
  );
  Future<LinkResult<DownloadedLinkFile>> downloadFile(
    AuthenticatedLinkSession session,
    FileExchange exchange, {
    required File destination,
    void Function(int transferred, int total)? onProgress,
    LinkTransferCancellation? cancellation,
  });
  Future<LinkResult<List<FileExchange>>> listFiles(
    AuthenticatedLinkSession session,
  );
  Future<LinkResult<FileExchange>> createFile(
    AuthenticatedLinkSession session,
    File file, {
    required String filename,
    required String mimeType,
    required int expiresInSeconds,
    required String access,
    required bool deleteAfterOpen,
    bool quick = false,
    void Function(int transferred, int total)? onProgress,
    LinkTransferCancellation? cancellation,
  });
  Future<LinkResult<void>> revoke(
    AuthenticatedLinkSession session,
    String token,
  );
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

final class ExchangeApi implements ExchangeGateway, FileExchangeGateway {
  const ExchangeApi({HttpLinkService? client})
    : _client = client ?? const HttpLinkService();

  final HttpLinkService _client;

  @override
  Future<LinkResult<String>> resolveShortCode(
    AuthenticatedLinkSession session,
    String code,
  ) async {
    final info = await _client.fetchInfo(session.address);
    if (info case LinkFailure<ServerInfo> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    if ((info as LinkSuccess<ServerInfo>).value.server.id != session.serverId) {
      return const LinkFailure(
        LinkFailureKind.serverIdentity,
        'This address now belongs to a different HomePlace server.',
      );
    }
    return _client.resolveFileCode(session.address, code);
  }

  @override
  Future<LinkResult<int>> fileLimit(AuthenticatedLinkSession session) async {
    final result = await _client.fetchInfo(session.address);
    if (result case LinkFailure<ServerInfo> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    final info = (result as LinkSuccess<ServerInfo>).value;
    if (info.server.id != session.serverId) {
      return const LinkFailure(
        LinkFailureKind.serverIdentity,
        'This address now belongs to a different HomePlace server.',
      );
    }
    return LinkSuccess(info.maxFileBytes ?? maxShareFileBytes);
  }

  @override
  Future<LinkResult<FileExchange>> inspectFile(
    AuthenticatedLinkSession session,
    String token,
  ) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{22}$').hasMatch(token)) {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'Invalid file link.',
      );
    }
    final response = await _client.requestJson(
      session.address,
      'GET',
      '/api/exchange/$token',
      credential: session.credential,
    );
    if (response case LinkFailure<Map<String, dynamic>> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    try {
      final value =
          (response as LinkSuccess<Map<String, dynamic>>).value['exchange'];
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Invalid file link.');
      }
      return LinkSuccess(FileExchange.fromJson({...value, 'token': token}));
    } on FormatException {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'HomePlace returned invalid file link metadata.',
      );
    }
  }

  @override
  Future<LinkResult<DownloadedLinkFile>> downloadFile(
    AuthenticatedLinkSession session,
    FileExchange exchange, {
    required File destination,
    void Function(int transferred, int total)? onProgress,
    LinkTransferCancellation? cancellation,
  }) => _client.downloadExchangeFile(
    session.address,
    session.credential,
    exchange.token,
    destination: destination,
    expectedSize: exchange.size,
    onProgress: onProgress,
    cancellation: cancellation,
  );

  @override
  Future<LinkResult<List<FileExchange>>> listFiles(
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
          if (row is Map<String, dynamic> && row['kind'] == 'file')
            FileExchange.fromJson(row),
      ]);
    } on FormatException {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'HomePlace returned an invalid file exchange list.',
      );
    }
  }

  @override
  Future<LinkResult<FileExchange>> createFile(
    AuthenticatedLinkSession session,
    File file, {
    required String filename,
    required String mimeType,
    required int expiresInSeconds,
    required String access,
    required bool deleteAfterOpen,
    bool quick = false,
    void Function(int transferred, int total)? onProgress,
    LinkTransferCancellation? cancellation,
  }) async {
    final limit = await fileLimit(session);
    if (limit case LinkFailure<int> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    final response = await _client.uploadExchangeFile(
      session.address,
      session.credential,
      file,
      filename: filename,
      mimeType: mimeType,
      expiresInSeconds: expiresInSeconds,
      access: access,
      deleteAfterOpen: deleteAfterOpen,
      quick: quick,
      maxBytes: (limit as LinkSuccess<int>).value,
      onProgress: onProgress,
      cancellation: cancellation,
    );
    if (response case LinkFailure<Map<String, dynamic>> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    try {
      final exchange = FileExchange.fromJson(
        (response as LinkSuccess<Map<String, dynamic>>).value['exchange'],
      );
      if (exchange.access != (quick ? 'link' : access) ||
          (quick && exchange.shortCode == null)) {
        throw const FormatException('Unexpected exchange access.');
      }
      return LinkSuccess(exchange);
    } on FormatException {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'HomePlace returned an invalid file exchange.',
      );
    }
  }

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
