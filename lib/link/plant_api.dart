import 'dart:convert';
import 'dart:typed_data';

import '../features/connection/connection_controller.dart';
import '../features/plants/plant_store.dart';
import 'link_client.dart';

final class PlantPhoto {
  const PlantPhoto({
    required this.url,
    required this.version,
    required this.maxBytes,
  });

  final String url;
  final String version;
  final int maxBytes;

  factory PlantPhoto.fromJson(Object? value, String clientId) {
    if (value is! Map<String, dynamic> ||
        value['url'] != '/api/link/plants/$clientId/photo' ||
        value['version'] is! String ||
        !RegExp(r'^[0-9a-fA-F-]{36}\.(jpg|png|webp)$')
            .hasMatch(value['version'] as String) ||
        value['maxBytes'] is! int ||
        (value['maxBytes'] as int) < 1 ||
        (value['maxBytes'] as int) > 12 * 1024 * 1024) {
      throw const FormatException('Invalid private plant photo.');
    }
    return PlantPhoto(
      url: value['url'] as String,
      version: value['version'] as String,
      maxBytes: value['maxBytes'] as int,
    );
  }

  Map<String, Object> toJson() => {
    'url': url,
    'version': version,
    'maxBytes': maxBytes,
  };
}

final class PlantNotificationSettings {
  const PlantNotificationSettings({
    required this.enabled,
    required this.app,
    required this.telegram,
    required this.time,
    required this.timeZone,
    required this.repeatDays,
  });

  final bool enabled;
  final bool app;
  final bool telegram;
  final String time;
  final String timeZone;
  final int repeatDays;

  factory PlantNotificationSettings.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['enabled'] is! bool ||
        value['app'] is! bool ||
        value['telegram'] is! bool ||
        value['time'] is! String ||
        !RegExp(r'^([01]\d|2[0-3]):[0-5]\d$')
            .hasMatch(value['time'] as String) ||
        value['timeZone'] is! String ||
        (value['timeZone'] as String).isEmpty ||
        (value['timeZone'] as String).length > 80 ||
        value['repeatDays'] is! int ||
        (value['repeatDays'] as int) < 0 ||
        (value['repeatDays'] as int) > 30) {
      throw const FormatException('Invalid plant notification settings.');
    }
    return PlantNotificationSettings(
      enabled: value['enabled'] as bool,
      app: value['app'] as bool,
      telegram: value['telegram'] as bool,
      time: value['time'] as String,
      timeZone: value['timeZone'] as String,
      repeatDays: value['repeatDays'] as int,
    );
  }

  PlantNotificationSettings copyWith({
    bool? enabled,
    bool? app,
    bool? telegram,
    String? time,
    String? timeZone,
    int? repeatDays,
  }) => PlantNotificationSettings(
    enabled: enabled ?? this.enabled,
    app: app ?? this.app,
    telegram: telegram ?? this.telegram,
    time: time ?? this.time,
    timeZone: timeZone ?? this.timeZone,
    repeatDays: repeatDays ?? this.repeatDays,
  );

  Map<String, Object> toJson() => {
    'enabled': enabled,
    'app': app,
    'telegram': telegram,
    'time': time,
    'timeZone': timeZone,
    'repeatDays': repeatDays,
  };
}

final class RemotePlant {
  const RemotePlant({
    required this.plant,
    required this.revision,
    required this.deleted,
    this.photo,
  });

  final HomePlant plant;
  final int revision;
  final bool deleted;
  final PlantPhoto? photo;

  factory RemotePlant.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['clientId'] is! String ||
        !RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(value['clientId'] as String) ||
        value['revision'] is! int ||
        (value['revision'] as int) < 1 ||
        value['deletedAt'] != null &&
            DateTime.tryParse(value['deletedAt'].toString()) == null) {
      throw const FormatException('Invalid server plant.');
    }
    final plant = HomePlant.fromJson({
      'id': value['clientId'],
      'name': value['name'],
      'species': value['species'],
      'location': value['location'],
      'notes': value['notes'],
      'intervalDays': value['intervalDays'],
      'lastWateredAt': value['lastWateredAt'],
      'createdAt': value['createdAt'],
      'remindersEnabled': value['remindersEnabled'],
    });
    if (plant == null) throw const FormatException('Invalid server plant.');
    return RemotePlant(
      plant: plant,
      revision: value['revision'] as int,
      deleted: value['deletedAt'] != null,
      photo: value['photo'] == null
          ? null
          : PlantPhoto.fromJson(value['photo'], value['clientId'] as String),
    );
  }

  Map<String, Object?> toJson() => {
    ...plant.toJson(),
    'clientId': plant.id,
    'revision': revision,
    'deletedAt': deleted ? DateTime.now().toUtc().toIso8601String() : null,
    'photo': photo?.toJson(),
  };
}

abstract interface class PlantGateway {
  Future<LinkResult<List<RemotePlant>>> list(AuthenticatedLinkSession session);
  Future<LinkResult<RemotePlant>> command(
    AuthenticatedLinkSession session,
    String action,
    HomePlant plant, {
    int? revision,
  });
  Future<LinkResult<PlantNotificationSettings>> getSettings(
    AuthenticatedLinkSession session,
  );
  Future<LinkResult<PlantNotificationSettings>> updateSettings(
    AuthenticatedLinkSession session,
    PlantNotificationSettings settings,
  );
  Future<LinkResult<Uint8List>> downloadPhoto(
    AuthenticatedLinkSession session,
    String clientId,
    PlantPhoto photo,
  );
  Future<LinkResult<RemotePlant>> uploadPhoto(
    AuthenticatedLinkSession session,
    String clientId,
    int revision,
    Uint8List bytes,
    String mimeType,
  );
  Future<LinkResult<RemotePlant>> deletePhoto(
    AuthenticatedLinkSession session,
    String clientId,
    int revision,
  );
}

final class PlantApi implements PlantGateway {
  const PlantApi({this.client = const HttpLinkService()});
  final HttpLinkService client;

  @override
  Future<LinkResult<List<RemotePlant>>> list(
    AuthenticatedLinkSession session,
  ) async {
    final response = await client.requestJson(
      session.address,
      'GET',
      '/api/link/plants',
      credential: session.credential,
      maxResponseBytes: 512 * 1024,
    );
    if (response case LinkFailure<Map<String, dynamic>> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    try {
      final rows =
          (response as LinkSuccess<Map<String, dynamic>>).value['plants'];
      if (rows is! List || rows.length > 500) {
        throw const FormatException('Invalid plant snapshot.');
      }
      return LinkSuccess(
        rows.map(RemotePlant.fromJson).toList(growable: false),
      );
    } on FormatException {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'HomePlace returned invalid plant data.',
      );
    }
  }

  @override
  Future<LinkResult<RemotePlant>> command(
    AuthenticatedLinkSession session,
    String action,
    HomePlant plant, {
    int? revision,
  }) async {
    final response = await client.requestJson(
      session.address,
      'POST',
      '/api/link/plants',
      credential: session.credential,
      body: {
        'action': action,
        'clientId': plant.id,
        ...?revision == null ? null : {'revision': revision},
        if (action == 'water')
          'lastWateredAt': plant.lastWateredAt.toUtc().toIso8601String(),
        if (action == 'create' || action == 'update') ...{
          'name': plant.name,
          'species': plant.species,
          'location': plant.location,
          'notes': plant.notes,
          'intervalDays': plant.intervalDays,
          'lastWateredAt': plant.lastWateredAt.toUtc().toIso8601String(),
          'remindersEnabled': plant.remindersEnabled,
        },
      },
    );
    if (response case LinkFailure<Map<String, dynamic>> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    try {
      return LinkSuccess(
        RemotePlant.fromJson(
          (response as LinkSuccess<Map<String, dynamic>>).value['plant'],
        ),
      );
    } on FormatException {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'HomePlace returned an invalid plant change.',
      );
    }
  }

  @override
  Future<LinkResult<PlantNotificationSettings>> getSettings(
    AuthenticatedLinkSession session,
  ) async {
    final response = await client.requestJson(
      session.address,
      'GET',
      '/api/link/plants/settings',
      credential: session.credential,
    );
    return _settingsResult(response);
  }

  @override
  Future<LinkResult<PlantNotificationSettings>> updateSettings(
    AuthenticatedLinkSession session,
    PlantNotificationSettings settings,
  ) async {
    final response = await client.requestJson(
      session.address,
      'PATCH',
      '/api/link/plants/settings',
      credential: session.credential,
      body: settings.toJson(),
    );
    return _settingsResult(response);
  }

  LinkResult<PlantNotificationSettings> _settingsResult(
    LinkResult<Map<String, dynamic>> response,
  ) {
    if (response case LinkFailure<Map<String, dynamic>> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    try {
      return LinkSuccess(
        PlantNotificationSettings.fromJson(
          (response as LinkSuccess<Map<String, dynamic>>).value['settings'],
        ),
      );
    } on FormatException {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'HomePlace returned invalid plant notification settings.',
      );
    }
  }

  @override
  Future<LinkResult<Uint8List>> downloadPhoto(
    AuthenticatedLinkSession session,
    String clientId,
    PlantPhoto photo,
  ) async {
    if (photo.url != _photoPath(clientId)) {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'Invalid private plant photo URL.',
      );
    }
    final response = await client.requestBinary(
      session.address,
      'GET',
      photo.url,
      credential: session.credential,
      maxResponseBytes: photo.maxBytes,
    );
    if (response case LinkFailure<LinkBinaryResponse> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    final value = (response as LinkSuccess<LinkBinaryResponse>).value;
    if (!_validImage(value.bytes, value.mimeType)) {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'HomePlace returned an invalid plant image.',
      );
    }
    return LinkSuccess(value.bytes);
  }

  @override
  Future<LinkResult<RemotePlant>> uploadPhoto(
    AuthenticatedLinkSession session,
    String clientId,
    int revision,
    Uint8List bytes,
    String mimeType,
  ) async {
    if (revision < 1 ||
        !_validImage(bytes, mimeType) ||
        bytes.length > 12 * 1024 * 1024) {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'Invalid plant photo upload.',
      );
    }
    final response = await client.requestBinary(
      session.address,
      'POST',
      _photoPath(clientId),
      credential: session.credential,
      body: bytes,
      contentType: mimeType,
      ifMatch: revision,
      maxResponseBytes: 65536,
    );
    return _photoChangeResult(response);
  }

  @override
  Future<LinkResult<RemotePlant>> deletePhoto(
    AuthenticatedLinkSession session,
    String clientId,
    int revision,
  ) async {
    if (revision < 1) {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'Invalid plant revision.',
      );
    }
    final response = await client.requestBinary(
      session.address,
      'DELETE',
      _photoPath(clientId),
      credential: session.credential,
      ifMatch: revision,
      maxResponseBytes: 65536,
    );
    return _photoChangeResult(response);
  }

  LinkResult<RemotePlant> _photoChangeResult(
    LinkResult<LinkBinaryResponse> response,
  ) {
    if (response case LinkFailure<LinkBinaryResponse> failure) {
      return LinkFailure(failure.kind, failure.message);
    }
    try {
      final value = (response as LinkSuccess<LinkBinaryResponse>).value;
      if (value.mimeType != 'application/json') throw const FormatException();
      final decoded = jsonDecode(utf8.decode(value.bytes));
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      return LinkSuccess(RemotePlant.fromJson(decoded['plant']));
    } on Object {
      return const LinkFailure(
        LinkFailureKind.invalidResponse,
        'HomePlace returned an invalid plant photo change.',
      );
    }
  }
}

String _photoPath(String clientId) => '/api/link/plants/$clientId/photo';

bool _validImage(Uint8List bytes, String? mimeType) {
  if (bytes.length < 4) return false;
  return switch (mimeType) {
    'image/jpeg' =>
      bytes[0] == 0xff &&
          bytes[1] == 0xd8 &&
          bytes[bytes.length - 2] == 0xff &&
          bytes.last == 0xd9,
    'image/png' =>
      bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4e &&
          bytes[3] == 0x47 &&
          bytes[4] == 0x0d &&
          bytes[5] == 0x0a &&
          bytes[6] == 0x1a &&
          bytes[7] == 0x0a,
    'image/webp' =>
      bytes.length >= 12 &&
          ascii.decode(bytes.sublist(0, 4), allowInvalid: true) == 'RIFF' &&
          ascii.decode(bytes.sublist(8, 12), allowInvalid: true) == 'WEBP',
    _ => false,
  };
}
