import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../core/network/server_address.dart';
import 'models.dart';

enum LinkFailureKind {
  network,
  tls,
  invalidResponse,
  incompatible,
  authentication,
  serverIdentity,
  cancelled,
}

const maxShareFileBytes = 500 * 1024 * 1024;

sealed class LinkResult<T> {
  const LinkResult();
}

final class LinkSuccess<T> extends LinkResult<T> {
  const LinkSuccess(this.value);
  final T value;
}

final class LinkFailure<T> extends LinkResult<T> {
  const LinkFailure(this.kind, this.message, {this.certificateFingerprint});
  final LinkFailureKind kind;
  final String message;
  final String? certificateFingerprint;
}

final class _ResponseTooLarge implements Exception {
  const _ResponseTooLarge();
}

final class _TransferCancelled implements Exception {
  const _TransferCancelled();
}

final class LinkTransferCancellation {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

final class DownloadedLinkFile {
  const DownloadedLinkFile({required this.file, required this.size});

  final File file;
  final int size;
}

final class DeviceDescription {
  const DeviceDescription({
    required this.name,
    required this.platform,
    required this.platformVersion,
    required this.appVersion,
  });
  final String name;
  final String platform;
  final String platformVersion;
  final String appVersion;

  Map<String, dynamic> toJson() => {
    'name': name,
    'platform': platform,
    'platformVersion': platformVersion,
    'appVersion': appVersion,
  };
}

final class PairingSession {
  const PairingSession({
    required this.id,
    required this.code,
    required this.claimSecret,
    required this.expiresAt,
    required this.pollAfterSeconds,
  });

  factory PairingSession.fromJson(Map<String, dynamic> json) => PairingSession(
    id: json['id'] as String,
    code: json['code'] as String,
    claimSecret: json['claimSecret'] as String,
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    pollAfterSeconds: json['pollAfterSeconds'] as int,
  );

  final String id;
  final String code;
  final String claimSecret;
  final DateTime expiresAt;
  final int pollAfterSeconds;
}

final class PairingClaim {
  const PairingClaim({
    required this.status,
    this.serverId,
    this.deviceId,
    this.credential,
  });
  factory PairingClaim.fromJson(Map<String, dynamic> json) => PairingClaim(
    status: json['status'] as String,
    serverId: json['serverId'] as String?,
    deviceId: json['deviceId'] as String?,
    credential: json['credential'] as String?,
  );
  final String status;
  final String? serverId;
  final String? deviceId;
  final String? credential;
}

final class DeviceEvent {
  const DeviceEvent({
    required this.id,
    required this.type,
    required this.payload,
  });
  factory DeviceEvent.fromJson(Map<String, dynamic> json) => DeviceEvent(
    id: json['id'] as String,
    type: json['type'] as String,
    payload: json['payload'] as Map<String, dynamic>? ?? const {},
  );
  final String id;
  final String type;
  final Map<String, dynamic> payload;
}

final class HeartbeatResponse {
  const HeartbeatResponse({required this.serverId, required this.events});
  factory HeartbeatResponse.fromJson(Map<String, dynamic> json) =>
      HeartbeatResponse(
        serverId: json['serverId'] as String,
        events: (json['events'] as List<dynamic>? ?? const [])
            .map((event) => DeviceEvent.fromJson(event as Map<String, dynamic>))
            .toList(growable: false),
      );
  final String serverId;
  final List<DeviceEvent> events;
}

abstract interface class LinkService {
  Future<LinkResult<ServerInfo>> fetchInfo(ServerAddress address);
  Future<LinkResult<PairingSession>> startPairing(
    ServerAddress address,
    DeviceDescription device,
    String publicKey,
    List<Capability> capabilities,
    List<String> permissions,
  );
  Future<LinkResult<PairingClaim>> claimPairing(
    ServerAddress address,
    PairingSession session,
  );
  Future<LinkResult<HeartbeatResponse>> heartbeat(
    ServerAddress address,
    String credential,
    List<String> acknowledgedEventIds,
  );
  Future<LinkResult<void>> revoke(ServerAddress address, String credential);
}

final class HttpLinkService implements LinkService {
  const HttpLinkService();

  Future<LinkResult<void>> uploadFile(
    ServerAddress address,
    String path,
    String credential,
    File file, {
    required String targetDeviceId,
    required String filename,
    required String mimeType,
    void Function(int transferred, int total)? onProgress,
    LinkTransferCancellation? cancellation,
  }) async {
    final client = _clientFor(address);
    try {
      final length = await file.length();
      if (length < 1 || length > maxShareFileBytes) {
        return const LinkFailure(
          LinkFailureKind.invalidResponse,
          'Files must be 500 MB or smaller.',
        );
      }
      final request = await client
          .openUrl('POST', address.uri.resolve(path))
          .timeout(const Duration(seconds: 10));
      request.followRedirects = false;
      request.contentLength = length;
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $credential',
      );
      request.headers.set('x-homeplace-target', targetDeviceId);
      request.headers.set(
        'x-homeplace-filename',
        Uri.encodeComponent(filename),
      );
      request.headers.set(
        'x-homeplace-filename-base64',
        base64Encode(utf8.encode(filename)),
      );
      request.headers.contentType = ContentType.parse(mimeType);
      var transferred = 0;
      await request.addStream(
        file.openRead().map((chunk) {
          if (cancellation?.isCancelled == true) {
            throw const _TransferCancelled();
          }
          transferred += chunk.length;
          onProgress?.call(transferred, length);
          return chunk;
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      final body = await _readBody(response, 65536);
      if (response.statusCode == HttpStatus.unauthorized) {
        return const LinkFailure(
          LinkFailureKind.authentication,
          'This device credential is no longer accepted.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return LinkFailure(
          LinkFailureKind.invalidResponse,
          _serverError(body) ?? 'HomePlace rejected the file.',
        );
      }
      return const LinkSuccess(null);
    } on _TransferCancelled {
      return const LinkFailure(
        LinkFailureKind.cancelled,
        'The file transfer was cancelled.',
      );
    } on HandshakeException {
      return const LinkFailure(LinkFailureKind.tls, 'TLS validation failed.');
    } on Object {
      return const LinkFailure(
        LinkFailureKind.network,
        'The file could not be sent.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<LinkResult<DownloadedLinkFile>> downloadFileToTemporary(
    ServerAddress address,
    String path,
    String credential, {
    required int expectedSize,
    required String expectedSha256,
    void Function(int transferred, int total)? onProgress,
    LinkTransferCancellation? cancellation,
  }) async {
    if (expectedSize < 1 ||
        expectedSize > maxShareFileBytes ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(expectedSha256)) {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'The shared file offer is invalid.',
      );
    }
    final client = _clientFor(address);
    File? temporary;
    try {
      final request = await client
          .getUrl(address.uri.resolve(path))
          .timeout(const Duration(seconds: 10));
      request.followRedirects = false;
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $credential',
      );
      final response = await request.close().timeout(
        const Duration(seconds: 30),
      );
      if (response.statusCode == HttpStatus.unauthorized) {
        await response.drain<void>();
        return const LinkFailure(
          LinkFailureKind.authentication,
          'This device credential is no longer accepted.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<void>();
        return const LinkFailure(
          LinkFailureKind.invalidResponse,
          'The shared file is unavailable or expired.',
        );
      }
      final announced = response.contentLength;
      final announcedDigest = response.headers.value('x-homeplace-sha256');
      if ((announced >= 0 && announced != expectedSize) ||
          (announcedDigest != null &&
              announcedDigest.toLowerCase() != expectedSha256.toLowerCase())) {
        await response.drain<void>();
        return const LinkFailure(
          LinkFailureKind.invalidResponse,
          'The shared file metadata does not match the offer.',
        );
      }

      final directory = await Directory.systemTemp.createTemp(
        'homeplace-received-',
      );
      temporary = File('${directory.path}/transfer.bin');
      final output = temporary.openWrite();
      var transferred = 0;
      try {
        await for (final chunk in response.timeout(
          const Duration(seconds: 30),
        )) {
          if (cancellation?.isCancelled == true) {
            throw const _TransferCancelled();
          }
          transferred += chunk.length;
          if (transferred > expectedSize || transferred > maxShareFileBytes) {
            throw const _ResponseTooLarge();
          }
          output.add(chunk);
          onProgress?.call(transferred, expectedSize);
        }
        await output.flush();
      } finally {
        await output.close();
      }
      if (transferred != expectedSize) {
        return const LinkFailure(
          LinkFailureKind.invalidResponse,
          'The shared file size does not match the offer.',
        );
      }
      final actualDigest = await sha256.bind(temporary.openRead()).single;
      if (actualDigest.toString().toLowerCase() !=
          expectedSha256.toLowerCase()) {
        return const LinkFailure(
          LinkFailureKind.invalidResponse,
          'Shared file integrity check failed.',
        );
      }
      final completed = temporary;
      temporary = null;
      return LinkSuccess(
        DownloadedLinkFile(file: completed, size: transferred),
      );
    } on _TransferCancelled {
      return const LinkFailure(
        LinkFailureKind.cancelled,
        'The file transfer was cancelled.',
      );
    } on _ResponseTooLarge {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'The shared file is larger than the approved offer.',
      );
    } on HandshakeException {
      return const LinkFailure(LinkFailureKind.tls, 'TLS validation failed.');
    } on TimeoutException {
      return const LinkFailure(
        LinkFailureKind.network,
        'The shared file transfer timed out.',
      );
    } on Object {
      return const LinkFailure(
        LinkFailureKind.network,
        'The shared file could not be downloaded.',
      );
    } finally {
      if (temporary != null) {
        try {
          await temporary.parent.delete(recursive: true);
        } on Object {
          // A failed transfer must not replace its useful network error.
        }
      }
      client.close(force: true);
    }
  }

  HttpClient _clientFor(ServerAddress address) {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    client.badCertificateCallback = (certificate, host, port) {
      final fingerprint = _fingerprint(certificate.der);
      return address.security == ConnectionSecurity.confirmedCertificate &&
          _constantTimeEquals(
            fingerprint,
            address.certificateFingerprint ?? '',
          );
    };
    return client;
  }

  @override
  Future<LinkResult<ServerInfo>> fetchInfo(ServerAddress address) async {
    final response = await requestJson(address, 'GET', '/api/link/info');
    if (response is LinkFailure<Map<String, dynamic>>) {
      return _copyFailure(response);
    }
    try {
      final info = ServerInfo.fromJson(
        (response as LinkSuccess<Map<String, dynamic>>).value,
      );
      if (!info.supportsClient) {
        return const LinkFailure(
          LinkFailureKind.incompatible,
          'This HomePlace server does not support Link protocol 1.',
        );
      }
      return LinkSuccess(info);
    } on Object {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'The server returned invalid HomePlace Link information.',
      );
    }
  }

  @override
  Future<LinkResult<PairingSession>> startPairing(
    ServerAddress address,
    DeviceDescription device,
    String publicKey,
    List<Capability> capabilities,
    List<String> permissions,
  ) async {
    final response = await requestJson(
      address,
      'POST',
      '/api/link/pair',
      body: {
        'protocol': supportedLinkProtocol,
        'device': device.toJson(),
        'publicKey': publicKey,
        'capabilities': capabilities
            .map((capability) => capability.toJson())
            .toList(),
        'permissions': permissions,
      },
    );
    if (response is LinkFailure<Map<String, dynamic>>) {
      return _copyFailure(response);
    }
    try {
      final body = (response as LinkSuccess<Map<String, dynamic>>).value;
      return LinkSuccess(
        PairingSession.fromJson(body['pairing'] as Map<String, dynamic>),
      );
    } on Object {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'HomePlace returned an invalid pairing response.',
      );
    }
  }

  @override
  Future<LinkResult<PairingClaim>> claimPairing(
    ServerAddress address,
    PairingSession session,
  ) async {
    final response = await requestJson(
      address,
      'POST',
      '/api/link/pairing/${Uri.encodeComponent(session.id)}/claim',
      body: {'claimSecret': session.claimSecret},
    );
    if (response is LinkFailure<Map<String, dynamic>>) {
      return _copyFailure(response);
    }
    try {
      final body = (response as LinkSuccess<Map<String, dynamic>>).value;
      return LinkSuccess(
        PairingClaim.fromJson(body['pairing'] as Map<String, dynamic>),
      );
    } on Object {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'HomePlace returned an invalid pairing response.',
      );
    }
  }

  @override
  Future<LinkResult<HeartbeatResponse>> heartbeat(
    ServerAddress address,
    String credential,
    List<String> acknowledgedEventIds,
  ) async {
    final response = await requestJson(
      address,
      'POST',
      '/api/link/heartbeat',
      credential: credential,
      body: {
        'protocol': supportedLinkProtocol,
        'acknowledgedEventIds': acknowledgedEventIds,
      },
    );
    if (response is LinkFailure<Map<String, dynamic>>) {
      return _copyFailure(response);
    }
    try {
      return LinkSuccess(
        HeartbeatResponse.fromJson(
          (response as LinkSuccess<Map<String, dynamic>>).value,
        ),
      );
    } on Object {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'HomePlace returned an invalid heartbeat.',
      );
    }
  }

  @override
  Future<LinkResult<void>> revoke(
    ServerAddress address,
    String credential,
  ) async {
    final response = await requestJson(
      address,
      'DELETE',
      '/api/link/device',
      credential: credential,
    );
    if (response is LinkFailure<Map<String, dynamic>>) {
      return _copyFailure(response);
    }
    return const LinkSuccess(null);
  }

  Future<LinkResult<Map<String, dynamic>>> requestJson(
    ServerAddress address,
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? credential,
    int maxResponseBytes = 65536,
  }) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    String? rejectedFingerprint;
    client.badCertificateCallback = (certificate, host, port) {
      final fingerprint = _fingerprint(certificate.der);
      rejectedFingerprint = fingerprint;
      return address.security == ConnectionSecurity.confirmedCertificate &&
          _constantTimeEquals(
            fingerprint,
            address.certificateFingerprint ?? '',
          );
    };
    try {
      final request = await client
          .openUrl(method, address.uri.resolve(path))
          .timeout(const Duration(seconds: 10));
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      if (credential != null) {
        request.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer $credential',
        );
      }
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(jsonEncode(body));
      }
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      if (response.isRedirect) {
        return const LinkFailure(
          LinkFailureKind.invalidResponse,
          'HomePlace redirected the connection unexpectedly.',
        );
      }
      final text = await _readBody(
        response,
        maxResponseBytes,
      ).timeout(const Duration(seconds: 12));
      if (response.statusCode == HttpStatus.unauthorized) {
        return const LinkFailure(
          LinkFailureKind.authentication,
          'This device credential is no longer accepted.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String? serverMessage;
        try {
          final decoded = jsonDecode(text);
          if (decoded is Map<String, dynamic> && decoded['error'] is String) {
            serverMessage = decoded['error'] as String;
          }
        } on Object {
          // The HTTP status remains useful when an upstream returned HTML.
        }
        return LinkFailure(
          LinkFailureKind.invalidResponse,
          serverMessage?.trim().isNotEmpty == true
              ? serverMessage!
              : 'HomePlace returned HTTP ${response.statusCode}.',
        );
      }
      if (text.isEmpty) return const LinkSuccess({});
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Expected a JSON object');
      }
      return LinkSuccess(decoded);
    } on _ResponseTooLarge {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'HomePlace returned a response that is too large.',
      );
    } on HandshakeException {
      return LinkFailure(
        LinkFailureKind.tls,
        'The server certificate could not be verified.',
        certificateFingerprint: rejectedFingerprint,
      );
    } on TimeoutException {
      return const LinkFailure(
        LinkFailureKind.network,
        'HomePlace did not respond in time.',
      );
    } on SocketException {
      return const LinkFailure(
        LinkFailureKind.network,
        'HomePlace could not be reached. Check the address and network.',
      );
    } on FormatException {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'HomePlace returned invalid JSON.',
      );
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _readBody(HttpClientResponse response, int maxBytes) async {
    final responseBytes = BytesBuilder(copy: false);
    await for (final chunk in response) {
      if (responseBytes.length + chunk.length > maxBytes) {
        throw const _ResponseTooLarge();
      }
      responseBytes.add(chunk);
    }
    return utf8.decode(responseBytes.takeBytes());
  }

  LinkFailure<T> _copyFailure<T>(LinkFailure<Object?> failure) => LinkFailure(
    failure.kind,
    failure.message,
    certificateFingerprint: failure.certificateFingerprint,
  );

  static String _fingerprint(List<int> der) => sha256
      .convert(der)
      .bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join(':');

  static bool _constantTimeEquals(String left, String right) {
    if (left.length != right.length || left.isEmpty) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index += 1) {
      difference |= left.codeUnitAt(index) ^ right.codeUnitAt(index);
    }
    return difference == 0;
  }
}

String? _serverError(String text) {
  try {
    final decoded = jsonDecode(text);
    return decoded is Map<String, dynamic> ? decoded['error'] as String? : null;
  } on Object {
    return null;
  }
}
