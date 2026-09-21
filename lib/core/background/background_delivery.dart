import 'dart:io';
import 'dart:ui';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../link/link_client.dart';
import '../../link/models.dart';
import '../network/server_address.dart';
import '../notifications/notification_service.dart';
import '../settings/app_preferences.dart';
import '../storage/connection_profile.dart';
import '../storage/credential_store.dart';
import '../storage/notification_history_store.dart';

const backgroundHeartbeatTask = 'homeplace.backgroundHeartbeat';
const _backgroundHeartbeatUniqueName = 'homeplace-periodic-heartbeat';
const _backgroundHeartbeatNowUniqueName = 'homeplace-heartbeat-now';

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

abstract interface class BackgroundOfferNoticeStore {
  Future<List<String>> read(String serverId);
  Future<void> write(String serverId, List<String> eventIds);
}

final class SharedPreferencesOfferNoticeStore
    implements BackgroundOfferNoticeStore {
  static const _prefix = 'homeplace.backgroundOfferNotices.';

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
      await preferences.setStringList(key, eventIds.take(100).toList());
    }
  }
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
    this.offerNoticeStore = const _DefaultOfferNoticeStore(),
    this.includeIncomingOffers = false,
    this.useRussianLabels = false,
  });

  final ProfileStore profileStore;
  final CredentialStore credentialStore;
  final LinkService linkService;
  final NotificationService? notificationService;
  final BackgroundAcknowledgementStore acknowledgementStore;
  final NotificationHistoryStore notificationHistoryStore;
  final BackgroundOfferNoticeStore offerNoticeStore;
  final bool includeIncomingOffers;
  final bool useRussianLabels;

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
    final previouslyNotifiedOffers = includeIncomingOffers
        ? (await offerNoticeStore.read(profile.serverId)).toSet()
        : const <String>{};
    final currentOfferIds = <String>[];
    for (final event in result.value.events) {
      if (includeIncomingOffers) {
        final offerDescription = _incomingOfferDescription(event);
        if (offerDescription != null) {
          currentOfferIds.add(event.id);
          if (!previouslyNotifiedOffers.contains(event.id)) {
            await notifications.showIncomingOffer(
              event.id,
              profile.serverId,
              useRussianLabels ? 'Новое в HomePlace' : 'New in HomePlace',
              offerDescription,
              useRussianLabels ? 'Принять' : 'Accept',
              useRussianLabels ? 'Отклонить' : 'Decline',
            );
          }
          continue;
        }
      }
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
    if (includeIncomingOffers) {
      await offerNoticeStore.write(profile.serverId, currentOfferIds);
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

  String? _incomingOfferDescription(DeviceEvent event) {
    if (event.type == 'clipboard.offer') {
      final text = event.payload['text'];
      final source = event.payload['sourceName'];
      if (text is! String ||
          text.isEmpty ||
          text.length > 8000 ||
          source is! String ||
          source.trim().isEmpty) {
        return null;
      }
      return useRussianLabels
          ? 'Буфер обмена от $source ждёт подтверждения'
          : 'Clipboard from $source is waiting for approval';
    }
    if (event.type != 'share.offer') return null;
    final type = event.payload['type'];
    final source = event.payload['sourceName'];
    if (source is! String || source.trim().isEmpty) return null;
    if (type == 'text' || type == 'url') {
      final value = event.payload['value'];
      if (value is! String ||
          value.isEmpty ||
          value.length > (type == 'url' ? 4096 : 8000)) {
        return null;
      }
      if (type == 'url') {
        final uri = Uri.tryParse(value);
        if (uri == null ||
            !{'http', 'https'}.contains(uri.scheme) ||
            uri.userInfo.isNotEmpty) {
          return null;
        }
      }
    } else if (type == 'file') {
      final transferId = event.payload['transferId'];
      final filename = event.payload['filename'];
      final size = event.payload['size'];
      final digest = event.payload['sha256'];
      if (transferId is! String ||
          filename is! String ||
          size is! int ||
          size < 1 ||
          size > maxShareFileBytes ||
          digest is! String ||
          !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(digest)) {
        return null;
      }
    } else {
      return null;
    }
    final label = switch (type) {
      'url' => useRussianLabels ? 'Ссылка' : 'Link',
      'file' => useRussianLabels ? 'Файл' : 'File',
      _ => useRussianLabels ? 'Текст' : 'Text',
    };
    return useRussianLabels
        ? '$label от $source ждёт подтверждения'
        : '$label from $source is waiting for approval';
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

  Future<void> refreshNow() async {
    if (!Platform.isAndroid) return;
    await Workmanager().registerOneOffTask(
      _backgroundHeartbeatNowUniqueName,
      backgroundHeartbeatTask,
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingWorkPolicy.replace,
    );
  }
}

@pragma('vm:entry-point')
void backgroundCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != backgroundHeartbeatTask) return true;
    DartPluginRegistrant.ensureInitialized();
    try {
      final preferences = await SharedPreferences.getInstance();
      final includeIncomingOffers =
          preferences.getBool(AppPreferences.backgroundIncomingOffersKey) ??
          false;
      final useRussianLabels =
          preferences.getString('app.language') == 'russian';
      final successfulProfiles = await BackgroundHeartbeatRunner(
        includeIncomingOffers: includeIncomingOffers,
        useRussianLabels: useRussianLabels,
      ).run();
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

final class _DefaultOfferNoticeStore implements BackgroundOfferNoticeStore {
  const _DefaultOfferNoticeStore();

  BackgroundOfferNoticeStore get _delegate =>
      SharedPreferencesOfferNoticeStore();

  @override
  Future<List<String>> read(String serverId) => _delegate.read(serverId);

  @override
  Future<void> write(String serverId, List<String> eventIds) =>
      _delegate.write(serverId, eventIds);
}
