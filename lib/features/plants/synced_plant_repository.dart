import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/storage/connection_profile.dart';
import '../../core/storage/credential_store.dart';
import '../../link/link_client.dart';
import '../../link/models.dart';
import '../../link/plant_api.dart';
import '../connection/connection_controller.dart';
import 'plant_store.dart';

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
        !['create', 'update', 'delete'].contains(value['action'])) {
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

final class PlantSyncSnapshot {
  const PlantSyncSnapshot({
    this.remote = const [],
    this.pending = const [],
    this.migrated = const {},
  });
  final List<RemotePlant> remote;
  final List<PendingPlantChange> pending;
  final Map<String, String> migrated;

  factory PlantSyncSnapshot.fromJson(Object? value) {
    if (value is! Map<String, dynamic> || value['version'] != 1) {
      throw const FormatException('Invalid plant sync state.');
    }
    final remote = value['remote'];
    final pending = value['pending'];
    final migrated = value['migrated'];
    if (remote is! List ||
        remote.length > 500 ||
        pending is! List ||
        pending.length > 500 ||
        migrated is! Map<String, dynamic>) {
      throw const FormatException('Invalid plant sync state.');
    }
    return PlantSyncSnapshot(
      remote: remote.map(RemotePlant.fromJson).toList(growable: false),
      pending: pending.map(PendingPlantChange.fromJson).toList(growable: false),
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
  });

  final ConnectionProfile profile;
  final PlantStore local;
  final Future<AuthenticatedLinkSession?> Function() sessionProvider;
  final bool Function() canUseServer;
  final PlantGateway gateway;
  final PlantSyncCache cache;
  final CredentialStore credentials;

  List<HomePlant> _legacy = const [];
  PlantSyncSnapshot _state = const PlantSyncSnapshot();
  String? _scope;
  Future<void>? _activeSync;
  Future<void>? _activeLoad;
  String? syncError;
  final Set<String> conflicts = {};

  int get pendingCount => _state.pending.length;
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
    if ((info as LinkSuccess<ServerInfo>).value.server.id != session.serverId) {
      syncError = 'This address belongs to a different HomePlace server.';
      return;
    }
    final result = await gateway.list(session);
    if (result case LinkFailure<List<RemotePlant>> failure) {
      syncError = failure.message;
      return;
    }
    final previous = {
      for (final item in _state.remote) item.plant.id: item.plant.photoName,
    };
    await _commit(
      PlantSyncSnapshot(
        remote: (result as LinkSuccess<List<RemotePlant>>).value
            .map((item) {
              final photo = previous[item.plant.id];
              return photo == null
                  ? item
                  : RemotePlant(
                      plant: item.plant.copyWith(photoName: photo),
                      revision: item.revision,
                      deleted: item.deleted,
                    );
            })
            .toList(growable: false),
        pending: _state.pending,
        migrated: _state.migrated,
      ),
    );
    await _flush(session);
  }

  bool _sameFields(HomePlant a, HomePlant b) =>
      a.name == b.name &&
      a.species == b.species &&
      a.location == b.location &&
      a.notes == b.notes &&
      a.intervalDays == b.intervalDays &&
      a.lastWateredAt.isAtSameMomentAs(b.lastWateredAt);

  Future<void> _flush(AuthenticatedLinkSession session) async {
    for (final change in List<PendingPlantChange>.of(_state.pending)) {
      final current = _state.remote
          .where((item) => item.plant.id == change.plant.id)
          .firstOrNull;
      if (change.action == 'delete' && current?.deleted == true ||
          change.action != 'delete' &&
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
        ),
      );
    }
    await _commit(
      PlantSyncSnapshot(
        remote: next,
        pending: [..._state.pending]
          ..removeWhere((item) => item.plant.id == change.plant.id),
        migrated: _state.migrated,
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
    await _commit(
      PlantSyncSnapshot(
        remote: _state.remote,
        pending: [..._state.pending]
          ..removeWhere((item) => item.plant.id == plant.id)
          ..add(change),
        migrated: _state.migrated,
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
      ),
    );
    await sync();
  }

  Future<void> importLocal() async {
    if (!canUseServer() || _scope == null) {
      throw StateError('Connect to HomePlace before importing plants.');
    }
    if (_activeSync != null) await _activeSync;
    if (_state.pending.length + localOnlyCount > 500) {
      throw StateError('Too many plants to import at once.');
    }
    final pending = [..._state.pending];
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
      migrated[plant.id] = id;
    }
    await _commit(
      PlantSyncSnapshot(
        remote: _state.remote,
        pending: pending,
        migrated: migrated,
      ),
    );
    await sync();
  }

  Future<void> resolveConflict(String id, {required bool useServer}) async {
    final pending = [..._state.pending];
    final index = pending.indexWhere((item) => item.plant.id == id);
    if (index < 0) return;
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
