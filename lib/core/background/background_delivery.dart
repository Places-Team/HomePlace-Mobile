import 'dart:io';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../../link/link_client.dart';
import '../../link/models.dart';
import 'background_tasks.dart';
import '../network/server_address.dart';
import '../notifications/notification_service.dart';
import '../settings/app_preferences.dart';
import '../storage/connection_profile.dart';
import '../storage/credential_store.dart';
import '../storage/notification_history_store.dart';

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

abstract interface class BackgroundFileStore {
  Future<String> createTemporaryFilePath();
  Future<String> saveFilePath(String path, String filename, String mimeType);
}

abstract interface class BackgroundFileTransferClient {
  Future<LinkResult<DownloadedLinkFile>> download(
    ServerAddress address,
    String credential,
    BackgroundFileOffer offer,
    String destinationPath,
  );
}

final class PlatformBackgroundFileStore implements BackgroundFileStore {
  const PlatformBackgroundFileStore();

  static const _channel = MethodChannel(
    'com.homeplace.mobile/background_files',
  );

  @override
  Future<String> createTemporaryFilePath() async {
    final path = await _channel.invokeMethod<String>('createTemporaryFile');
    if (path == null || path.isEmpty) {
      throw PlatformException(code: 'temporary_file_unavailable');
    }
    return path;
  }

  @override
  Future<String> saveFilePath(
    String path,
    String filename,
    String mimeType,
  ) async {
    final location = await _channel.invokeMethod<String>('saveFilePath', {
      'path': path,
      'filename': filename,
      'mimeType': mimeType,
    });
    if (location == null || location.isEmpty) {
      throw PlatformException(code: 'save_failed');
    }
    return location;
  }
}

final class HttpBackgroundFileTransferClient
    implements BackgroundFileTransferClient {
  const HttpBackgroundFileTransferClient();

  @override
  Future<LinkResult<DownloadedLinkFile>> download(
    ServerAddress address,
    String credential,
    BackgroundFileOffer offer,
    String destinationPath,
  ) => const HttpLinkService().downloadFileToTemporary(
    address,
    '/api/link/mobile/share/file/${Uri.encodeComponent(offer.transferId)}',
    credential,
    destination: File(destinationPath),
    expectedSize: offer.size,
    expectedSha256: offer.sha256,
  );
}

final class BackgroundFileOffer {
  const BackgroundFileOffer({
    required this.transferId,
    required this.filename,
    required this.mimeType,
    required this.size,
    required this.sha256,
  });

  final String transferId;
  final String filename;
  final String mimeType;
  final int size;
  final String sha256;
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
    this.fileStore = const PlatformBackgroundFileStore(),
    this.fileTransferClient = const HttpBackgroundFileTransferClient(),
    this.includeIncomingOffers = false,
    this.seamlessOwnAccountTransfers = false,
    this.useRussianLabels = false,
  });

  final ProfileStore profileStore;
  final CredentialStore credentialStore;
  final LinkService linkService;
  final NotificationService? notificationService;
  final BackgroundAcknowledgementStore acknowledgementStore;
  final NotificationHistoryStore notificationHistoryStore;
  final BackgroundOfferNoticeStore offerNoticeStore;
  final BackgroundFileStore fileStore;
  final BackgroundFileTransferClient fileTransferClient;
  final bool includeIncomingOffers;
  final bool seamlessOwnAccountTransfers;
  final bool useRussianLabels;

  Future<int> run() async {
    final notifications = notificationService ?? LocalNotificationService();
    await notifications.initialize();
    if (!await notifications.isAvailable()) return 0;

    final actions = includeIncomingOffers
        ? await notifications.takeIncomingActions()
        : const <IncomingNotificationAction>[];
    final profiles = await profileStore.readAll();
    var successfulProfiles = 0;
    for (final profile in profiles) {
      final profileActions = actions
          .where((action) => action.serverId == profile.serverId)
          .toList(growable: false);
      if (await _pollProfile(profile, notifications, profileActions)) {
        successfulProfiles++;
      }
    }
    final knownServers = profiles.map((profile) => profile.serverId).toSet();
    final unmatched = actions
        .where((action) => !knownServers.contains(action.serverId))
        .toList(growable: false);
    if (unmatched.isNotEmpty) {
      await notifications.restoreIncomingActions(unmatched);
    }
    return successfulProfiles;
  }

  Future<bool> _pollProfile(
    ConnectionProfile profile,
    NotificationService notifications,
    List<IncomingNotificationAction> actions,
  ) async {
    final normalized = ServerAddressNormalizer.normalize(profile.preferredUrl);
    if (normalized is! ValidAddress) {
      await notifications.restoreIncomingActions(actions);
      return false;
    }
    var address = normalized.address;
    if (profile.certificateFingerprint case final fingerprint?) {
      address = address.trustFingerprint(fingerprint);
    }

    final info = await linkService.fetchInfo(address);
    if (info is! LinkSuccess<ServerInfo> ||
        verifyServerIdentity(profile.serverId, info.value)
            is IdentityMismatch) {
      await notifications.restoreIncomingActions(actions);
      return false;
    }
    final credential = await credentialStore.read(profile.serverId);
    if (credential == null) {
      await notifications.restoreIncomingActions(actions);
      return false;
    }

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
      await notifications.restoreIncomingActions(actions);
      return false;
    }
    if (pendingAcknowledgements.isNotEmpty) {
      await acknowledgementStore.write(profile.serverId, const []);
    }

    final resolved = <String>[];
    final retryActions = <IncomingNotificationAction>[];
    final actionsByEvent = {
      for (final action in actions) action.eventId: action,
    };
    final previouslyNotifiedOffers = includeIncomingOffers
        ? (await offerNoticeStore.read(profile.serverId)).toSet()
        : const <String>{};
    final currentOfferIds = <String>[];
    for (final event in result.value.events) {
      if (includeIncomingOffers) {
        final offerDescription = _incomingOfferDescription(event);
        if (offerDescription != null) {
          currentOfferIds.add(event.id);
          final action = actionsByEvent[event.id];
          if (action?.kind == IncomingNotificationActionKind.decline) {
            resolved.add(event.id);
            continue;
          }
          if (action?.kind == IncomingNotificationActionKind.accept &&
              offerDescription.acceptInBackground) {
            final offer = _backgroundFileOffer(event);
            final saved =
                offer != null &&
                await _downloadAcceptedFile(
                  event.id,
                  address,
                  credential,
                  offer,
                  notifications,
                );
            if (saved) {
              resolved.add(event.id);
            } else {
              retryActions.add(action!);
            }
            continue;
          }
          if (action == null &&
              seamlessOwnAccountTransfers &&
              event.payload['sameAccount'] == true &&
              offerDescription.acceptInBackground) {
            final offer = _backgroundFileOffer(event);
            final saved =
                offer != null &&
                await _downloadAcceptedFile(
                  event.id,
                  address,
                  credential,
                  offer,
                  notifications,
                );
            if (saved) resolved.add(event.id);
            if (saved) continue;
          }
          if (!previouslyNotifiedOffers.contains(event.id) && action == null) {
            await notifications.showIncomingOffer(
              event.id,
              profile.serverId,
              useRussianLabels ? 'Новое в HomePlace' : 'New in HomePlace',
              offerDescription.text,
              useRussianLabels ? 'Принять' : 'Accept',
              useRussianLabels ? 'Отклонить' : 'Decline',
              acceptInBackground: offerDescription.acceptInBackground,
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
      resolved.add(event.id);
    }
    if (includeIncomingOffers) {
      await offerNoticeStore.write(profile.serverId, currentOfferIds);
    }
    if (retryActions.isNotEmpty) {
      await notifications.restoreIncomingActions(retryActions);
    }
    if (resolved.isEmpty) return true;

    final acknowledgement = await linkService.heartbeat(
      address,
      credential,
      resolved,
    );
    if (acknowledgement is! LinkSuccess<HeartbeatResponse> ||
        acknowledgement.value.serverId != profile.serverId) {
      await acknowledgementStore.write(profile.serverId, resolved);
    }
    return true;
  }

  ({String text, bool acceptInBackground})? _incomingOfferDescription(
    DeviceEvent event,
  ) {
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
      return (
        text: useRussianLabels
            ? 'Буфер обмена от $source ждёт подтверждения'
            : 'Clipboard from $source is waiting for approval',
        acceptInBackground: false,
      );
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
    return (
      text: useRussianLabels
          ? '$label от $source ждёт подтверждения'
          : '$label from $source is waiting for approval',
      acceptInBackground: type == 'file',
    );
  }

  BackgroundFileOffer? _backgroundFileOffer(DeviceEvent event) {
    if (event.type != 'share.offer' || event.payload['type'] != 'file') {
      return null;
    }
    final transferId = event.payload['transferId'];
    final filename = event.payload['filename'];
    final mimeType = event.payload['mimeType'];
    final size = event.payload['size'];
    final sha256 = event.payload['sha256'];
    if (transferId is! String ||
        transferId.isEmpty ||
        filename is! String ||
        filename.isEmpty ||
        filename.length > 180 ||
        size is! int ||
        size < 1 ||
        size > maxShareFileBytes ||
        sha256 is! String ||
        !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(sha256)) {
      return null;
    }
    final safeMimeType =
        mimeType is String &&
            RegExp(
              r'^[A-Za-z0-9][A-Za-z0-9!#$&^_.+-]*/[A-Za-z0-9][A-Za-z0-9!#$&^_.+-]{0,99}$',
            ).hasMatch(mimeType)
        ? mimeType
        : 'application/octet-stream';
    return BackgroundFileOffer(
      transferId: transferId,
      filename: filename,
      mimeType: safeMimeType,
      size: size,
      sha256: sha256.toLowerCase(),
    );
  }

  Future<bool> _downloadAcceptedFile(
    String eventId,
    ServerAddress address,
    String credential,
    BackgroundFileOffer offer,
    NotificationService notifications,
  ) async {
    String? temporaryPath;
    try {
      temporaryPath = await fileStore.createTemporaryFilePath();
      final result = await fileTransferClient.download(
        address,
        credential,
        offer,
        temporaryPath,
      );
      if (result is! LinkSuccess<DownloadedLinkFile>) return false;
      await fileStore.saveFilePath(
        result.value.file.path,
        offer.filename,
        offer.mimeType,
      );
      await notifications.show(
        'saved:$eventId',
        useRussianLabels ? 'Файл загружен' : 'File downloaded',
        useRussianLabels
            ? '${offer.filename} сохранён в Downloads/HomePlace'
            : '${offer.filename} was saved to Downloads/HomePlace',
      );
      return true;
    } on Object {
      return false;
    } finally {
      if (temporaryPath != null) {
        try {
          await File(temporaryPath).delete();
        } on Object {
          // A failed cleanup must not acknowledge an unverified transfer.
        }
      }
    }
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
      await Workmanager().cancelByUniqueName(backgroundHeartbeatUniqueName);
      return;
    }
    await Workmanager().registerPeriodicTask(
      backgroundHeartbeatUniqueName,
      backgroundHeartbeatTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }

  Future<void> refreshNow() async {
    if (!Platform.isAndroid) return;
    await Workmanager().registerOneOffTask(
      backgroundHeartbeatNowUniqueName,
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
      final seamlessOwnAccountTransfers =
          preferences.getBool(AppPreferences.seamlessOwnAccountTransfersKey) ??
          false;
      final useRussianLabels =
          preferences.getString('app.language') == 'russian';
      final successfulProfiles = await BackgroundHeartbeatRunner(
        includeIncomingOffers: includeIncomingOffers,
        seamlessOwnAccountTransfers: seamlessOwnAccountTransfers,
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
