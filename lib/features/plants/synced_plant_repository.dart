import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/storage/connection_profile.dart';
import '../../core/storage/credential_store.dart';
import '../../link/link_client.dart';
import '../../link/models.dart';
import '../../link/plant_api.dart';
import '../connection/connection_controller.dart';
import 'plant_store.dart';
import 'plant_photo_cache.dart';
import 'plant_photo_preparer.dart';

final class PendingPlantChange {
  const PendingPlantChange({
    required this.action,
    required this.plant,
    this.revision,
  });
  final String action;
  final HomePlant plant;
  final int? revision;

  factory PendingPlantChange.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        !['create', 'update', 'delete', 'water'].contains(value['action'])) {
      throw const FormatException('Invalid pending plant change.');
    }
    final plant = HomePlant.fromJson(value['plant']);
    if (plant == null ||
        (value['action'] != 'create' &&
            (value['revision'] is! int || (value['revision'] as int) < 1))) {
      throw const FormatException('Invalid pending plant change.');
    }
    return PendingPlantChange(
      action: value['action'] as String,
      plant: plant,
      revision: value['revision'] as int?,
    );
  }

  Map<String, Object?> toJson() => {
    'action': action,
    'plant': plant.toJson(),
    if (revision != null) 'revision': revision,
  };
}

final class PendingPlantPhoto {
  const PendingPlantPhoto({
    required this.clientId,
    required this.sourceName,
    required this.baseVersion,
  });

  final String clientId;
  final String? sourceName;
  final String? baseVersion;

  factory PendingPlantPhoto.fromJson(Object? value) {
    if (value is! Map<String, dynamic> ||
        value['clientId'] is! String ||
        !RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(value['clientId'] as String) ||
        value['sourceName'] != null &&
            (value['sourceName'] is! String ||
                !RegExp(r'^\d+\.(jpg|png|webp|heic|heif)$')
                    .hasMatch(value['sourceName'] as String)) ||
        value['baseVersion'] != null &&
            (value['baseVersion'] is! String ||
                !RegExp(r'^[0-9a-fA-F-]{36}\.(jpg|png|webp)$')
                    .hasMatch(value['baseVersion'] as String))) {
      throw const FormatException('Invalid pending plant photo.');
    }
    return PendingPlantPhoto(
      clientId: value['clientId'] as String,
      sourceName: value['sourceName'] as String?,
      baseVersion: value['baseVersion'] as String?,
    );
  }

  Map<String, Object?> toJson() => {
    'clientId': clientId,
    'sourceName': sourceName,
    'baseVersion': baseVersion,
  };
}

final class PlantSyncSnapshot {
  const PlantSyncSnapshot({
    this.remote = const [],
    this.pending = const [],
    this.migrated = const {},
    this.pendingPhotos = const [],
    this.settings,
  });
  final List<RemotePlant> remote;
  final List<PendingPlantChange> pending;
  final Map<String, String> migrated;
  final List<PendingPlantPhoto> pendingPhotos;
  final PlantNotificationSettings? settings;

  factory PlantSyncSnapshot.fromJson(Object? value) {
    if (value is! Map<String, dynamic> || value['version'] != 1) {
      throw const FormatException('Invalid plant sync state.');
    }
    final remote = value['remote'];
    final pending = value['pending'];
    final migrated = value['migrated'];
    final pendingPhotos = value['pendingPhotos'] ?? const [];
    final settings = value['settings'];
    if (remote is! List ||
        remote.length > 500 ||
        pending is! List ||
        pending.length > 500 ||
        migrated is! Map<String, dynamic> ||
        pendingPhotos is! List ||
        pendingPhotos.length > 500) {
      throw const FormatException('Invalid plant sync state.');
    }
    return PlantSyncSnapshot(
      remote: remote.map(RemotePlant.fromJson).toList(growable: false),
      pending: pending.map(PendingPlantChange.fromJson).toList(growable: false),
      pendingPhotos: pendingPhotos
          .map(PendingPlantPhoto.fromJson)
          .toList(growable: false),
      settings: settings == null
          ? null
          : PlantNotificationSettings.fromJson(settings),
      migrated: migrated.map((key, value) {
        if (value is! String) {
          throw const FormatException('Invalid plant migration map.');
        }
        return MapEntry(key, value);
      }),
    );
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'remote': remote.map((item) => item.toJson()).toList(),
    'pending': pending.map((item) => item.toJson()).toList(),
    'migrated': migrated,
    'pendingPhotos': pendingPhotos.map((item) => item.toJson()).toList(),
    'settings': settings?.toJson(),
  };
}

abstract interface class PlantSyncCache {
  Future<PlantSyncSnapshot> read(String scope);
  Future<void> write(String scope, PlantSyncSnapshot snapshot);
}

final class SecurePlantSyncCache implements PlantSyncCache {
  const SecurePlantSyncCache({this.storage = const FlutterSecureStorage()});
  final FlutterSecureStorage storage;

  String _key(String scope) => 'homeplace.plants.sync.v1.$scope';

  @override
  Future<PlantSyncSnapshot> read(String scope) async {
    final raw = await storage.read(
      key: _key(scope),
      aOptions: const AndroidOptions(),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
    return raw == null
        ? const PlantSyncSnapshot()
        : PlantSyncSnapshot.fromJson(jsonDecode(raw));
  }

  @override
  Future<void> write(String scope, PlantSyncSnapshot snapshot) => storage.write(
    key: _key(scope),
    value: jsonEncode(snapshot.toJson()),
    aOptions: const AndroidOptions(),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
}

final class SyncedPlantRepository {
  SyncedPlantRepository({
    required this.profile,
    required this.local,
    required this.sessionProvider,
    required this.canUseServer,
    this.gateway = const PlantApi(),
    this.cache = const SecurePlantSyncCache(),
    this.credentials = const PlatformCredentialStore(),
    PlantPhotoCache? photoCache,
    PlantPhotoPreparer? photoPreparer,
  }) : photoCache = photoCache ?? PlantPhotoCache(),
       photoPreparer = photoPreparer ?? PlantPhotoPreparer();

  final ConnectionProfile profile;
  final PlantStore local;
  final Future<AuthenticatedLinkSession?> Function() sessionProvider;
  final bool Function() canUseServer;
  final PlantGateway gateway;
  final PlantSyncCache cache;
  final CredentialStore credentials;
  final PlantPhotoCache photoCache;
  final PlantPhotoPreparer photoPreparer;

  List<HomePlant> _legacy = const [];
  PlantSyncSnapshot _state = const PlantSyncSnapshot();
  String? _scope;
  Future<void>? _activeSync;
  Future<void>? _activeLoad;
  String? syncError;
  bool plantPhotosAvailable = false;
  bool plantRemindersAvailable = false;
  int maxPlantPhotoBytes = 12 * 1024 * 1024;
  PlantNotificationSettings? get notificationSettings => _state.settings;
  final Set<String> conflicts = {};

  int get pendingCount => _state.pending.length + _state.pendingPhotos.length;
  int get localOnlyCount =>
      _legacy.where((plant) => !_state.migrated.containsKey(plant.id)).length;
  bool get serverEnabled => canUseServer();
  String _scopeFor(String credential) => sha256
      .convert(
        utf8.encode('${profile.serverId}:${profile.deviceId}:$credential'),
      )
      .toString();
  bool isSharedPlant(HomePlant plant) =>
      _state.remote.any((item) => item.plant.id == plant.id) ||
      _state.pending.any((item) => item.plant.id == plant.id);

  Future<File?> photoFile(HomePlant plant) async {
    final scope = _scope;
    final remote = _state.remote
        .where((item) => item.plant.id == plant.id)
        .firstOrNull;
    final photo = remote?.photo;
    if (scope != null && canUseServer() && photo != null) {
      final cached = await photoCache.read(scope, plant.id, photo.version);
      if (cached != null) return cached;
      try {
        final session = await _verifiedSession();
        if (plantPhotosAvailable) {
          final result = await gateway.downloadPhoto(session, plant.id, photo);
          if (result case LinkSuccess<Uint8List> success) {
            return await photoCache.write(
              scope,
              plant.id,
              photo.version,
              success.value,
            );
          }
        }
      } on Object {
        // Keep local originals available when the server is offline.
      }
    }
    return local.photoFile(plant.photoName);
  }

  List<HomePlant> get plants {
    final visible = <String, HomePlant>{
      for (final plant in _legacy)
        if (!_state.migrated.containsKey(plant.id)) plant.id: plant,
    };
    if (!canUseServer()) return visible.values.toList(growable: false);
    for (final item in _state.remote) {
      if (!item.deleted) visible[item.plant.id] = item.plant;
    }
    for (final change in _state.pending) {
      if (change.action == 'delete') {
        visible.remove(change.plant.id);
      } else {
        visible[change.plant.id] = change.plant;
      }
    }
    return visible.values.toList(growable: false);
  }

  Future<void> load() async {
    if (_activeLoad != null) return _activeLoad;
    final operation = _loadNow();
    _activeLoad = operation;
    try {
      await operation;
    } finally {
      _activeLoad = null;
    }
  }

  Future<void> _loadNow() async {
    _legacy = await local.readAll();
    final credential = await credentials.read(profile.serverId);
    if (credential == null) {
      _scope = null;
      _state = const PlantSyncSnapshot();
      conflicts.clear();
      return;
    }
    final scope = _scopeFor(credential);
    if (_scope != scope) {
      _state = await cache.read(scope);
      _scope = scope;
      conflicts.clear();
    }
    if (canUseServer()) await sync();
  }

  Future<void> _commit(PlantSyncSnapshot next) async {
    final scope = _scope;
    if (scope == null) throw StateError('Plant sync is not initialized.');
    await cache.write(scope, next);
    _state = next;
  }

  Future<void> sync() async {
    if (!canUseServer() || _scope == null) return;
    if (_activeSync != null) return _activeSync;
    final operation = _syncNow();
    _activeSync = operation;
    try {
      await operation;
    } finally {
      _activeSync = null;
    }
  }

  Future<void> _syncNow() async {
    final session = await sessionProvider();
    if (session == null) {
      syncError = 'Connect to HomePlace to sync plants.';
      return;
    }
    if (_scopeFor(session.credential) != _scope) {
      syncError = 'Device account changed. Refresh plants before syncing.';
      return;
    }
    final info = await const HttpLinkService().fetchInfo(session.address);
    if (info case LinkFailure<ServerInfo> failure) {
      syncError = failure.message;
      return;
    }
    final serverInfo = (info as LinkSuccess<ServerInfo>).value;
    if (serverInfo.server.id != session.serverId) {
      syncError = 'This address belongs to a different HomePlace server.';
      return;
    }
    plantPhotosAvailable = serverInfo.features.plantPhotos;
    plantRemindersAvailable = serverInfo.features.plantReminders;
    maxPlantPhotoBytes = serverInfo.maxPlantPhotoBytes ?? 12 * 1024 * 1024;
    final result = await gateway.list(session);
    if (result case LinkFailure<List<RemotePlant>> failure) {
      syncError = failure.message;
      return;
    }
    var settings = _state.settings;
    if (plantRemindersAvailable) {
      final settingsResult = await gateway.getSettings(session);
      if (settingsResult case LinkSuccess<PlantNotificationSettings> success) {
        settings = success.value;
      }
    }
    final previous = {for (final item in _state.remote) item.plant.id: item};
    final fresh = (result as LinkSuccess<List<RemotePlant>>).value;
    for (final old in _state.remote) {
      final current = fresh
          .where((item) => item.plant.id == old.plant.id)
          .firstOrNull;
      if (old.photo != null &&
          (current == null || current.deleted || current.photo == null)) {
        await photoCache.remove(_scope!, old.plant.id);
      }
    }
    await _commit(
      PlantSyncSnapshot(
        remote: fresh
            .map((item) {
              final old = previous[item.plant.id];
              final localPhoto = old?.plant.photoName;
              return localPhoto == null
                  ? item
                  : RemotePlant(
                      plant: item.plant.copyWith(photoName: localPhoto),
                      revision: item.revision,
                      deleted: item.deleted,
                      photo: item.photo,
                    );
            })
            .toList(growable: false),
        pending: _state.pending,
        migrated: _state.migrated,
        pendingPhotos: _state.pendingPhotos,
        settings: settings,
      ),
    );
    await _flush(session);
    if (plantPhotosAvailable) await _flushPhotos(session);
  }

  Future<void> _flushPhotos(AuthenticatedLinkSession session) async {
    for (final change in List<PendingPlantPhoto>.of(_state.pendingPhotos)) {
      if (_state.pending.any((item) => item.plant.id == change.clientId)) {
        continue;
      }
      final current = _state.remote
          .where((item) => item.plant.id == change.clientId)
          .firstOrNull;
      if (current == null || current.deleted) continue;
      if (current.photo?.version != change.baseVersion) {
        conflicts.add(change.clientId);
        syncError = 'A plant photo changed elsewhere. Resolve the conflict.';
        continue;
      }
      Uint8List? bytes;
      LinkResult<RemotePlant> result;
      if (change.sourceName == null) {
        if (current.photo == null) {
          await _completePhoto(change, current, null);
          continue;
        }
        result = await gateway.deletePhoto(
          session,
          change.clientId,
          current.revision,
        );
      } else {
        final file = await local.photoFile(change.sourceName);
        if (file == null) {
          syncError = 'The local plant photo is unavailable or exceeds the server limit.';
          continue;
        }
        PreparedPlantPhoto prepared;
        try {
          prepared = await photoPreparer.prepare(
            file,
            maxBytes: maxPlantPhotoBytes,
          );
        } on Object {
          syncError =
              'The plant photo could not be converted within the server limit.';
          continue;
        }
        final mimeType = prepared.mimeType;
        bytes = prepared.bytes;
        result = await gateway.uploadPhoto(
          session,
          change.clientId,
          current.revision,
          bytes,
          mimeType,
        );
      }
      if (result case LinkFailure<RemotePlant> failure) {
        syncError = failure.message;
        if (failure.message.toLowerCase().contains('conflict')) {
          conflicts.add(change.clientId);
        }
        continue;
      }
      await _completePhoto(
        change,
        (result as LinkSuccess<RemotePlant>).value,
        bytes,
      );
    }
    if (conflicts.isEmpty && pendingCount == 0) syncError = null;
  }

  Future<void> _completePhoto(
    PendingPlantPhoto change,
    RemotePlant response,
    Uint8List? bytes,
  ) async {
    final current = _state.remote
        .where((item) => item.plant.id == change.clientId)
        .firstOrNull;
    final updated = RemotePlant(
      plant: response.plant.copyWith(
        photoName: response.photo == null ? null : current?.plant.photoName,
        clearPhoto: response.photo == null,
      ),
      revision: response.revision,
      deleted: response.deleted,
      photo: response.photo,
    );
    await _commit(
      PlantSyncSnapshot(
        remote: [..._state.remote]
          ..removeWhere((item) => item.plant.id == change.clientId)
          ..add(updated),
        pending: _state.pending,
        migrated: _state.migrated,
        pendingPhotos: [..._state.pendingPhotos]
          ..removeWhere((item) => item.clientId == change.clientId),
        settings: _state.settings,
      ),
    );
    conflicts.remove(change.clientId);
    if (_scope case final scope?) {
      if (response.photo == null) {
        await photoCache.remove(scope, change.clientId);
      } else if (bytes != null) {
        await photoCache.write(
          scope,
          change.clientId,
          response.photo!.version,
          bytes,
        );
      }
    }
  }

  Future<void> updateNotificationSettings(
    PlantNotificationSettings next,
  ) async {
    if (!canUseServer()) {
      throw StateError('Plant synchronization is unavailable.');
    }
    final session = await _verifiedSession();
    if (!plantRemindersAvailable) {
      throw StateError(
        'This HomePlace server does not support plant reminders.',
      );
    }
    final response = await gateway.updateSettings(session, next);
    if (response case LinkFailure<PlantNotificationSettings> failure) {
      throw StateError(failure.message);
    }
    await _commit(
      PlantSyncSnapshot(
        remote: _state.remote,
        pending: _state.pending,
        migrated: _state.migrated,
        pendingPhotos: _state.pendingPhotos,
        settings: (response as LinkSuccess<PlantNotificationSettings>).value,
      ),
    );
  }

  Future<AuthenticatedLinkSession> _verifiedSession() async {
    final session = await sessionProvider();
    if (session == null || _scopeFor(session.credential) != _scope) {
      throw StateError(
        'Device account changed. Refresh plants before syncing.',
      );
    }
    final info = await const HttpLinkService().fetchInfo(session.address);
    if (info case LinkFailure<ServerInfo> failure) {
      throw StateError(failure.message);
    }
    final serverInfo = (info as LinkSuccess<ServerInfo>).value;
    if (serverInfo.server.id != session.serverId) {
      throw StateError('This address belongs to a different HomePlace server.');
    }
    plantPhotosAvailable = serverInfo.features.plantPhotos;
    plantRemindersAvailable = serverInfo.features.plantReminders;
    maxPlantPhotoBytes = serverInfo.maxPlantPhotoBytes ?? 12 * 1024 * 1024;
    return session;
  }

  bool _sameFields(HomePlant a, HomePlant b) =>
      a.name == b.name &&
      a.species == b.species &&
      a.location == b.location &&
      a.notes == b.notes &&
      a.intervalDays == b.intervalDays &&
      a.lastWateredAt.isAtSameMomentAs(b.lastWateredAt) &&
      a.remindersEnabled == b.remindersEnabled;

  Future<void> _flush(AuthenticatedLinkSession session) async {
    for (final change in List<PendingPlantChange>.of(_state.pending)) {
      final current = _state.remote
          .where((item) => item.plant.id == change.plant.id)
          .firstOrNull;
      if (change.action == 'delete' && current?.deleted == true ||
          change.action == 'water' &&
              current != null &&
              current.plant.lastWateredAt.isAtSameMomentAs(
                change.plant.lastWateredAt,
              ) ||
          change.action != 'delete' &&
              change.action != 'water' &&
              current != null &&
              !current.deleted &&
              _sameFields(current.plant, change.plant)) {
        await _complete(change, current);
        continue;
      }
      if (change.action == 'create' && current != null ||
          change.action != 'create' &&
              (current == null ||
                  current.deleted ||
                  current.revision != change.revision)) {
        conflicts.add(change.plant.id);
        syncError = 'A plant was changed elsewhere. Resolve the conflict.';
        continue;
      }
      final response = await gateway.command(
        session,
        change.action,
        change.plant,
        revision: change.revision,
      );
      if (response case LinkFailure<RemotePlant> failure) {
        syncError = failure.message;
        if (failure.kind == LinkFailureKind.invalidResponse &&
            failure.message.toLowerCase().contains('conflict')) {
          conflicts.add(change.plant.id);
        }
        break;
      }
      await _complete(change, (response as LinkSuccess<RemotePlant>).value);
    }
    if (conflicts.isEmpty && _state.pending.isEmpty) syncError = null;
  }

  Future<void> _complete(PendingPlantChange change, RemotePlant? remote) async {
    final next = [..._state.remote]
      ..removeWhere((item) => item.plant.id == change.plant.id);
    if (remote != null) {
      next.add(
        RemotePlant(
          plant: remote.plant.copyWith(photoName: change.plant.photoName),
          revision: remote.revision,
          deleted: remote.deleted,
          photo: remote.photo,
        ),
      );
    }
    await _commit(
      PlantSyncSnapshot(
        remote: next,
        pending: [..._state.pending]
          ..removeWhere((item) => item.plant.id == change.plant.id),
        migrated: _state.migrated,
        pendingPhotos: _state.pendingPhotos,
        settings: _state.settings,
      ),
    );
    conflicts.remove(change.plant.id);
  }

  Future<void> save(HomePlant plant) async {
    if (_scope == null) await load();
    if (!canUseServer() ||
        _scope == null ||
        _legacy.any(
          (item) =>
              item.id == plant.id && !_state.migrated.containsKey(item.id),
        )) {
      await local.save(plant);
      _legacy = await local.readAll();
      return;
    }
    if (_activeSync != null) await _activeSync;
    final existing = _state.remote
        .where((item) => item.plant.id == plant.id)
        .firstOrNull;
    final queued = _state.pending
        .where((item) => item.plant.id == plant.id)
        .firstOrNull;
    final remotePlant = existing == null && queued == null
        ? plant.copyWith(id: _newPlantId())
        : plant;
    final change = PendingPlantChange(
      action: queued?.action == 'create' || existing == null
          ? 'create'
          : 'update',
      plant: remotePlant,
      revision: queued?.revision ?? existing?.revision,
    );
    final oldPhotoName = queued?.plant.photoName ?? existing?.plant.photoName;
    final pendingPhotos = [..._state.pendingPhotos];
    if (remotePlant.photoName != oldPhotoName) {
      pendingPhotos.removeWhere((item) => item.clientId == remotePlant.id);
      pendingPhotos.add(
        PendingPlantPhoto(
          clientId: remotePlant.id,
          sourceName: remotePlant.photoName,
          baseVersion: existing?.photo?.version,
        ),
      );
    }
    await _commit(
      PlantSyncSnapshot(
        remote: _state.remote,
        pending: [..._state.pending]
          ..removeWhere((item) => item.plant.id == plant.id)
          ..add(change),
        migrated: _state.migrated,
        pendingPhotos: pendingPhotos,
        settings: _state.settings,
      ),
    );
    await sync();
  }

  Future<void> water(HomePlant plant, DateTime at) async {
    final watered = plant.copyWith(lastWateredAt: at);
    if (_scope == null) await load();
    if (!canUseServer() ||
        _scope == null ||
        _legacy.any(
          (item) =>
              item.id == plant.id && !_state.migrated.containsKey(item.id),
        )) {
      await local.save(watered);
      _legacy = await local.readAll();
      return;
    }
    if (_activeSync != null) await _activeSync;
    final queued = _state.pending
        .where((item) => item.plant.id == plant.id)
        .firstOrNull;
    final existing = _state.remote
        .where((item) => item.plant.id == plant.id)
        .firstOrNull;
    if (queued?.action == 'delete') {
      throw StateError('This plant is being deleted.');
    }
    await _commit(
      PlantSyncSnapshot(
        remote: _state.remote,
        pending: [..._state.pending]
          ..removeWhere((item) => item.plant.id == plant.id)
          ..add(
            PendingPlantChange(
              action: queued?.action == 'create' || queued?.action == 'update'
                  ? queued!.action
                  : 'water',
              plant: watered,
              revision: queued?.revision ?? existing?.revision,
            ),
          ),
        migrated: _state.migrated,
        pendingPhotos: _state.pendingPhotos,
        settings: _state.settings,
      ),
    );
    await sync();
  }

  Future<void> delete(HomePlant plant) async {
    if (_scope == null) await load();
    if (!canUseServer() ||
        _scope == null ||
        _legacy.any(
          (item) =>
              item.id == plant.id && !_state.migrated.containsKey(item.id),
        )) {
      await local.delete(plant);
      _legacy = await local.readAll();
      return;
    }
    if (_activeSync != null) await _activeSync;
    final queued = _state.pending
        .where((item) => item.plant.id == plant.id)
        .firstOrNull;
    final existing = _state.remote
        .where((item) => item.plant.id == plant.id)
        .firstOrNull;
    final pending = [..._state.pending]
      ..removeWhere((item) => item.plant.id == plant.id);
    final migrated = Map<String, String>.of(_state.migrated);
    if (queued?.action == 'create') {
      migrated.removeWhere((key, value) => value == plant.id);
    } else if (existing != null) {
      pending.add(
        PendingPlantChange(
          action: 'delete',
          plant: plant,
          revision: queued?.revision ?? existing.revision,
        ),
      );
    }
    await _commit(
      PlantSyncSnapshot(
        remote: _state.remote,
        pending: pending,
        migrated: migrated,
        pendingPhotos: [..._state.pendingPhotos]
          ..removeWhere((item) => item.clientId == plant.id),
        settings: _state.settings,
      ),
    );
    await sync();
  }

  Future<void> importLocal({bool uploadPhotos = false}) async {
    if (!canUseServer() || _scope == null) {
      throw StateError('Connect to HomePlace before importing plants.');
    }
    if (_activeSync != null) await _activeSync;
    if (_state.pending.length + localOnlyCount > 500) {
      throw StateError('Too many plants to import at once.');
    }
    final pending = [..._state.pending];
    final pendingPhotos = [..._state.pendingPhotos];
    final migrated = Map<String, String>.of(_state.migrated);
    for (final plant in _legacy) {
      if (migrated.containsKey(plant.id)) continue;
      final id = _newPlantId();
      pending.add(
        PendingPlantChange(
          action: 'create',
          plant: plant.copyWith(id: id),
        ),
      );
      if (uploadPhotos && plant.photoName != null) {
        pendingPhotos.add(
          PendingPlantPhoto(
            clientId: id,
            sourceName: plant.photoName,
            baseVersion: null,
          ),
        );
      }
      migrated[plant.id] = id;
    }
    await _commit(
      PlantSyncSnapshot(
        remote: _state.remote,
        pending: pending,
        migrated: migrated,
        pendingPhotos: pendingPhotos,
        settings: _state.settings,
      ),
    );
    await sync();
  }

  Future<void> resolveConflict(String id, {required bool useServer}) async {
    final pending = [..._state.pending];
    final index = pending.indexWhere((item) => item.plant.id == id);
    if (index < 0) {
      final photos = [..._state.pendingPhotos];
      final photoIndex = photos.indexWhere((item) => item.clientId == id);
      if (photoIndex < 0) return;
      final currentPhoto = _state.remote
          .where((item) => item.plant.id == id)
          .firstOrNull;
      if (useServer || currentPhoto == null || currentPhoto.deleted) {
        photos.removeAt(photoIndex);
      } else {
        final old = photos[photoIndex];
        photos[photoIndex] = PendingPlantPhoto(
          clientId: id,
          sourceName: old.sourceName,
          baseVersion: currentPhoto.photo?.version,
        );
      }
      await _commit(
        PlantSyncSnapshot(
          remote: _state.remote,
          pending: _state.pending,
          migrated: _state.migrated,
          pendingPhotos: photos,
          settings: _state.settings,
        ),
      );
      conflicts.remove(id);
      syncError = null;
      if (!useServer) await sync();
      return;
    }
    final current = _state.remote
        .where((item) => item.plant.id == id)
        .firstOrNull;
    final migrated = Map<String, String>.of(_state.migrated);
    if (useServer || current == null || current.deleted) {
      pending.removeAt(index);
      if (current == null || current.deleted) {
        migrated.removeWhere((key, value) => value == id);
      }
    } else {
      final old = pending[index];
      pending[index] = PendingPlantChange(
        action: old.action == 'create' ? 'update' : old.action,
        plant: old.plant,
        revision: current.revision,
      );
    }
    await _commit(
      PlantSyncSnapshot(
        remote: _state.remote,
        pending: pending,
        migrated: migrated,
        pendingPhotos: useServer
            ? ([..._state.pendingPhotos]
                ..removeWhere((item) => item.clientId == id))
            : _state.pendingPhotos,
        settings: _state.settings,
      ),
    );
    conflicts.remove(id);
    syncError = null;
    if (!useServer) await sync();
  }
}

String _newPlantId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}
