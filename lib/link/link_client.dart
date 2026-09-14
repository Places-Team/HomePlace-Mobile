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
}

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

  @override
  Future<LinkResult<ServerInfo>> fetchInfo(ServerAddress address) async {
    final response = await _request(address, 'GET', '/api/link/info');
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
  ) async {
    final response = await _request(
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
    final response = await _request(
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
    final response = await _request(
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
    final response = await _request(
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

  Future<LinkResult<Map<String, dynamic>>> _request(
    ServerAddress address,
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? credential,
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
      final text = await _readBody(response)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode == HttpStatus.unauthorized) {
        return const LinkFailure(
          LinkFailureKind.authentication,
          'This device credential is no longer accepted.',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return LinkFailure(
          LinkFailureKind.invalidResponse,
          'HomePlace returned HTTP ${response.statusCode}.',
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

  Future<String> _readBody(HttpClientResponse response) async {
    final responseBytes = BytesBuilder(copy: false);
    await for (final chunk in response) {
      if (responseBytes.length + chunk.length > 65536) {
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
