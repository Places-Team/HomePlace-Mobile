import '../features/connection/connection_controller.dart';
import '../features/plants/plant_store.dart';
import 'link_client.dart';

final class RemotePlant {
  const RemotePlant({
    required this.plant,
    required this.revision,
    required this.deleted,
  });

  final HomePlant plant;
  final int revision;
  final bool deleted;

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
    });
    if (plant == null) throw const FormatException('Invalid server plant.');
    return RemotePlant(
      plant: plant,
      revision: value['revision'] as int,
      deleted: value['deletedAt'] != null,
    );
  }

  Map<String, Object?> toJson() => {
    ...plant.toJson(),
    'clientId': plant.id,
    'revision': revision,
    'deletedAt': deleted ? DateTime.now().toUtc().toIso8601String() : null,
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
        if (action != 'delete') ...{
          'name': plant.name,
          'species': plant.species,
          'location': plant.location,
          'notes': plant.notes,
          'intervalDays': plant.intervalDays,
          'lastWateredAt': plant.lastWateredAt.toUtc().toIso8601String(),
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
}
