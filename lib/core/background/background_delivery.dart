import 'dart:io';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../link/link_client.dart';
import '../../link/models.dart';
import '../network/server_address.dart';
import '../notifications/notification_service.dart';
import '../storage/connection_profile.dart';
import '../storage/credential_store.dart';
import '../storage/notification_history_store.dart';

const backgroundHeartbeatTask = 'homeplace.backgroundHeartbeat';
const _backgroundHeartbeatUniqueName = 'homeplace-periodic-heartbeat';

final class BackgroundDeliveryStatus {
  const BackgroundDeliveryStatus({
    required this.lastRunAt,
    required this.successfulProfiles,
  });

  final DateTime lastRunAt;
  final int successfulProfiles;
}

final class BackgroundDeliveryStatusStore {
  const BackgroundDeliveryStatusStore();

  static const _lastRunKey = 'homeplace.background.lastRun';
  static const _successfulProfilesKey = 'homeplace.background.successful';

  Future<BackgroundDeliveryStatus?> read() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_lastRunKey);
    final lastRun = raw == null ? null : DateTime.tryParse(raw);
    if (lastRun == null) return null;
    return BackgroundDeliveryStatus(
      lastRunAt: lastRun,
      successfulProfiles: preferences.getInt(_successfulProfilesKey) ?? -1,
    );
  }

  Future<void> write(int successfulProfiles) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _lastRunKey,
      DateTime.now().toUtc().toIso8601String(),
    );
    await preferences.setInt(_successfulProfilesKey, successfulProfiles);
  }
}

abstract interface class BackgroundAcknowledgementStore {
  Future<List<String>> read(String serverId);
  Future<void> write(String serverId, List<String> eventIds);
}

final class SharedPreferencesAcknowledgementStore
    implements BackgroundAcknowledgementStore {
  static const _prefix = 'homeplace.backgroundAcknowledgements.';

  @override
  Future<List<String>> read(String serverId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList('$_prefix$serverId') ?? const [];
  }

  @override
  Future<void> write(String serverId, List<String> eventIds) async {
    final preferences = await SharedPreferences.getInstance();
    final key = '$_prefix$serverId';
    if (eventIds.isEmpty) {
      await preferences.remove(key);
    } else {
      await preferences.setStringList(key, eventIds);
    }
  }
}

final class BackgroundHeartbeatRunner {
  const BackgroundHeartbeatRunner({
    this.profileStore = const _DefaultProfileStore(),
    this.credentialStore = const PlatformCredentialStore(),
    this.linkService = const HttpLinkService(),
    this.notificationService,
    this.acknowledgementStore = const _DefaultAcknowledgementStore(),
    this.notificationHistoryStore = const PlatformNotificationHistoryStore(),
  });

  final ProfileStore profileStore;
  final CredentialStore credentialStore;
  final LinkService linkService;
  final NotificationService? notificationService;
  final BackgroundAcknowledgementStore acknowledgementStore;
  final NotificationHistoryStore notificationHistoryStore;

  Future<int> run() async {
    final notifications = notificationService ?? LocalNotificationService();
    await notifications.initialize();
    if (!await notifications.isAvailable()) return 0;

    var successfulProfiles = 0;
    for (final profile in await profileStore.readAll()) {
      if (await _pollProfile(profile, notifications)) successfulProfiles++;
    }
    return successfulProfiles;
  }

  Future<bool> _pollProfile(
    ConnectionProfile profile,
    NotificationService notifications,
  ) async {
    final normalized = ServerAddressNormalizer.normalize(profile.preferredUrl);
    if (normalized is! ValidAddress) return false;
    var address = normalized.address;
    if (profile.certificateFingerprint case final fingerprint?) {
      address = address.trustFingerprint(fingerprint);
    }

    final info = await linkService.fetchInfo(address);
    if (info is! LinkSuccess<ServerInfo> ||
        verifyServerIdentity(profile.serverId, info.value)
            is IdentityMismatch) {
      return false;
    }
    final credential = await credentialStore.read(profile.serverId);
    if (credential == null) return false;

    final pendingAcknowledgements = await acknowledgementStore.read(
      profile.serverId,
    );
    final result = await linkService.heartbeat(
      address,
      credential,
      pendingAcknowledgements,
    );
    if (result is! LinkSuccess<HeartbeatResponse> ||
        result.value.serverId != profile.serverId) {
      return false;
    }
    if (pendingAcknowledgements.isNotEmpty) {
      await acknowledgementStore.write(profile.serverId, const []);
    }

    final delivered = <String>[];
    for (final event in result.value.events) {
      if (event.type != 'notification.deliver') continue;
      final title = event.payload['title'];
      final body = event.payload['body'];
      if (title is! String ||
          body is! String ||
          title.isEmpty ||
          title.length > 120 ||
          body.isEmpty ||
          body.length > 2000) {
        continue;
      }
      await notifications.show(event.id, title, body);
      try {
        await appendNotificationHistory(
          notificationHistoryStore,
          notificationHistoryScope(profile.serverId, credential),
          NotificationHistoryItem(
            id: event.id,
            title: title,
            body: body,
            receivedAt: DateTime.now(),
          ),
        );
      } on Object {
        // Notification delivery must not depend on optional local history.
      }
      delivered.add(event.id);
    }
    if (delivered.isEmpty) return true;

    final acknowledgement = await linkService.heartbeat(
      address,
      credential,
      delivered,
    );
    if (acknowledgement is! LinkSuccess<HeartbeatResponse> ||
        acknowledgement.value.serverId != profile.serverId) {
      await acknowledgementStore.write(profile.serverId, delivered);
    }
    return true;
  }
}

final class AndroidBackgroundDeliveryScheduler {
  const AndroidBackgroundDeliveryScheduler();

  Future<void> initialize() async {
    if (!Platform.isAndroid) return;
    await Workmanager().initialize(backgroundCallbackDispatcher);
  }

  Future<void> setEnabled(bool enabled) async {
    if (!Platform.isAndroid) return;
    if (!enabled) {
      await Workmanager().cancelByUniqueName(_backgroundHeartbeatUniqueName);
      return;
    }
    await Workmanager().registerPeriodicTask(
      _backgroundHeartbeatUniqueName,
      backgroundHeartbeatTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }
}

@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != backgroundHeartbeatTask) return true;
    DartPluginRegistrant.ensureInitialized();
    try {
      final successfulProfiles = await const BackgroundHeartbeatRunner().run();
      await const BackgroundDeliveryStatusStore().write(successfulProfiles);
      return true;
    } on Object {
      await const BackgroundDeliveryStatusStore().write(-1);
      return false;
    }
  });
}

final class _DefaultProfileStore implements ProfileStore {
  const _DefaultProfileStore();

  ProfileStore get _delegate => SharedPreferencesProfileStore();

  @override
  Future<List<ConnectionProfile>> readAll() => _delegate.readAll();

  @override
  Future<void> remove(String serverId) => _delegate.remove(serverId);

  @override
  Future<void> save(ConnectionProfile profile) => _delegate.save(profile);
}

final class _DefaultAcknowledgementStore
    implements BackgroundAcknowledgementStore {
  const _DefaultAcknowledgementStore();

  BackgroundAcknowledgementStore get _delegate =>
      SharedPreferencesAcknowledgementStore();

  @override
  Future<List<String>> read(String serverId) => _delegate.read(serverId);

  @override
  Future<void> write(String serverId, List<String> eventIds) =>
      _delegate.write(serverId, eventIds);
}
