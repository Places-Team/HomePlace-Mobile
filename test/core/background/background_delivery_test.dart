import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/background/background_delivery.dart';
import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/core/notifications/notification_service.dart';
import 'package:homeplace/core/storage/connection_profile.dart';
import 'package:homeplace/core/storage/notification_history_store.dart';
import 'package:homeplace/link/link_client.dart';

import '../../features/connection/test_doubles.dart';

void main() {
  test('delivers and acknowledges only bounded notification events', () async {
    const profile = ConnectionProfile(
      serverId: testServerId,
      serverName: 'Test Home',
      preferredUrl: 'https://home.example.test',
      deviceId: 'device-1',
      secure: true,
    );
    final profiles = MemoryProfileStore()..profiles.add(profile);
    final credentials = MemoryCredentialStore()
      ..values[testServerId] = 'device-credential';
    final link = FakeLinkService()
      ..heartbeatResults.addAll([
        const LinkSuccess(
          HeartbeatResponse(
            serverId: testServerId,
            events: [
              DeviceEvent(
                id: 'notification-1',
                type: 'notification.deliver',
                payload: {'title': 'HomePlace', 'body': 'Test delivered'},
              ),
              DeviceEvent(
                id: 'clipboard-1',
                type: 'clipboard.offer',
                payload: {'text': 'private text'},
              ),
              DeviceEvent(
                id: 'invalid-1',
                type: 'notification.deliver',
                payload: {'title': '', 'body': 'Ignored'},
              ),
            ],
          ),
        ),
        const LinkSuccess(
          HeartbeatResponse(serverId: testServerId, events: []),
        ),
      ]);
    final notifications = FakeNotificationService();
    final acknowledgements = MemoryBackgroundAcknowledgementStore();
    final history = MemoryNotificationHistoryStore();

    final successfulProfiles = await BackgroundHeartbeatRunner(
      profileStore: profiles,
      credentialStore: credentials,
      linkService: link,
      notificationService: notifications,
      acknowledgementStore: acknowledgements,
      notificationHistoryStore: history,
    ).run();

    expect(successfulProfiles, 1);
    expect(notifications.delivered, ['HomePlace:Test delivered']);
    expect(link.heartbeatAcknowledgements, [
      <String>[],
      ['notification-1'],
    ]);
    expect(acknowledgements.values, isEmpty);
    expect(history.items.single.title, 'HomePlace');
    expect(history.items.single.body, 'Test delivered');
  });

  test('does not use credentials when the saved server ID changed', () async {
    const profile = ConnectionProfile(
      serverId: '067ee4ce-60d1-44f6-b7bc-c1d6528e47aa',
      serverName: 'Old Home',
      preferredUrl: 'https://home.example.test',
      deviceId: 'device-1',
      secure: true,
    );
    final profiles = MemoryProfileStore()..profiles.add(profile);
    final credentials = MemoryCredentialStore()
      ..values[profile.serverId] = 'must-not-be-used';
    final link = FakeLinkService();
    final notifications = FakeNotificationService();

    final successfulProfiles = await BackgroundHeartbeatRunner(
      profileStore: profiles,
      credentialStore: credentials,
      linkService: link,
      notificationService: notifications,
      acknowledgementStore: MemoryBackgroundAcknowledgementStore(),
    ).run();

    expect(successfulProfiles, 0);
    expect(link.heartbeatAcknowledgements, isEmpty);
    expect(notifications.delivered, isEmpty);
  });

  test('retries a notification acknowledgement on the next run', () async {
    const profile = ConnectionProfile(
      serverId: testServerId,
      serverName: 'Test Home',
      preferredUrl: 'https://home.example.test',
      deviceId: 'device-1',
      secure: true,
    );
    final profiles = MemoryProfileStore()..profiles.add(profile);
    final credentials = MemoryCredentialStore()
      ..values[testServerId] = 'device-credential';
    final acknowledgements = MemoryBackgroundAcknowledgementStore();
    final firstLink = FakeLinkService()
      ..heartbeatResults.addAll([
        const LinkSuccess(
          HeartbeatResponse(
            serverId: testServerId,
            events: [
              DeviceEvent(
                id: 'notification-2',
                type: 'notification.deliver',
                payload: {'title': 'HomePlace', 'body': 'Keep acknowledgement'},
              ),
            ],
          ),
        ),
        const LinkFailure(LinkFailureKind.network, 'Offline'),
      ]);
    final runner = BackgroundHeartbeatRunner(
      profileStore: profiles,
      credentialStore: credentials,
      linkService: firstLink,
      notificationService: FakeNotificationService(),
      acknowledgementStore: acknowledgements,
    );

    await runner.run();
    expect(acknowledgements.values[testServerId], ['notification-2']);

    final nextLink = FakeLinkService();
    await BackgroundHeartbeatRunner(
      profileStore: profiles,
      credentialStore: credentials,
      linkService: nextLink,
      notificationService: FakeNotificationService(),
      acknowledgementStore: acknowledgements,
    ).run();

    expect(nextLink.heartbeatAcknowledgements.single, ['notification-2']);
    expect(acknowledgements.values, isEmpty);
  });

  test(
    'notifies once for valid incoming offers without acknowledging them',
    () async {
      const profile = ConnectionProfile(
        serverId: testServerId,
        serverName: 'Test Home',
        preferredUrl: 'https://home.example.test',
        deviceId: 'device-1',
        secure: true,
      );
      final profiles = MemoryProfileStore()..profiles.add(profile);
      final credentials = MemoryCredentialStore()
        ..values[testServerId] = 'device-credential';
      final notices = MemoryBackgroundOfferNoticeStore();
      final notifications = FakeNotificationService();
      const response = LinkSuccess(
        HeartbeatResponse(
          serverId: testServerId,
          events: [
            DeviceEvent(
              id: 'file-1',
              type: 'share.offer',
              payload: {
                'type': 'file',
                'sourceName': 'Family tablet',
                'transferId': 'transfer-1',
                'filename': 'photo.jpg',
                'mimeType': 'image/jpeg',
                'size': 1200,
                'sha256': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
              },
            ),
          ],
        ),
      );
      final firstLink = FakeLinkService()..heartbeatResults.add(response);

      await BackgroundHeartbeatRunner(
        profileStore: profiles,
        credentialStore: credentials,
        linkService: firstLink,
        notificationService: notifications,
        acknowledgementStore: MemoryBackgroundAcknowledgementStore(),
        offerNoticeStore: notices,
        includeIncomingOffers: true,
      ).run();

      expect(notifications.incomingOffers.single, contains('Family tablet'));
      expect(firstLink.heartbeatAcknowledgements.single, isEmpty);
      expect(notices.values[testServerId], ['file-1']);

      final secondLink = FakeLinkService()..heartbeatResults.add(response);
      await BackgroundHeartbeatRunner(
        profileStore: profiles,
        credentialStore: credentials,
        linkService: secondLink,
        notificationService: notifications,
        acknowledgementStore: MemoryBackgroundAcknowledgementStore(),
        offerNoticeStore: notices,
        includeIncomingOffers: true,
      ).run();

      expect(notifications.incomingOffers, hasLength(1));
    },
  );

  test(
    'downloads an explicitly accepted file before acknowledging it',
    () async {
      const profile = ConnectionProfile(
        serverId: testServerId,
        serverName: 'Test Home',
        preferredUrl: 'https://home.example.test',
        deviceId: 'device-1',
        secure: true,
      );
      final profiles = MemoryProfileStore()..profiles.add(profile);
      final credentials = MemoryCredentialStore()
        ..values[testServerId] = 'device-credential';
      final notifications = FakeNotificationService()
        ..pendingActions.add(
          const IncomingNotificationAction(
            serverId: testServerId,
            eventId: 'file-background-1',
            kind: IncomingNotificationActionKind.accept,
          ),
        );
      final link = FakeLinkService()
        ..heartbeatResults.addAll([
          const LinkSuccess(
            HeartbeatResponse(
              serverId: testServerId,
              events: [
                DeviceEvent(
                  id: 'file-background-1',
                  type: 'share.offer',
                  payload: {
                    'type': 'file',
                    'sourceName': 'Family tablet',
                    'transferId': 'transfer-background-1',
                    'filename': 'archive.zip',
                    'mimeType': 'application/zip',
                    'size': 4,
                    'sha256': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                    'sameAccount': false,
                  },
                ),
              ],
            ),
          ),
          const LinkSuccess(
            HeartbeatResponse(serverId: testServerId, events: []),
          ),
        ]);
      final files = FakeBackgroundFileStore();

      final successful = await BackgroundHeartbeatRunner(
        profileStore: profiles,
        credentialStore: credentials,
        linkService: link,
        notificationService: notifications,
        acknowledgementStore: MemoryBackgroundAcknowledgementStore(),
        offerNoticeStore: MemoryBackgroundOfferNoticeStore(),
        fileStore: files,
        fileTransferClient: const FakeBackgroundFileTransferClient(),
        includeIncomingOffers: true,
      ).run();

      expect(successful, 1);
      expect(files.savedNames, ['archive.zip']);
      expect(link.heartbeatAcknowledgements, [
        <String>[],
        ['file-background-1'],
      ]);
      expect(notifications.restoredActions, isEmpty);
      expect(notifications.delivered.single, contains('archive.zip'));
    },
  );

  test('keeps a failed accepted file action for a safe retry', () async {
    const profile = ConnectionProfile(
      serverId: testServerId,
      serverName: 'Test Home',
      preferredUrl: 'https://home.example.test',
      deviceId: 'device-1',
      secure: true,
    );
    final profiles = MemoryProfileStore()..profiles.add(profile);
    final credentials = MemoryCredentialStore()
      ..values[testServerId] = 'device-credential';
    final notifications = FakeNotificationService()
      ..pendingActions.add(
        const IncomingNotificationAction(
          serverId: testServerId,
          eventId: 'file-background-2',
          kind: IncomingNotificationActionKind.accept,
        ),
      );
    final link = FakeLinkService()
      ..heartbeatResults.add(
        const LinkSuccess(
          HeartbeatResponse(
            serverId: testServerId,
            events: [
              DeviceEvent(
                id: 'file-background-2',
                type: 'share.offer',
                payload: {
                  'type': 'file',
                  'sourceName': 'Phone',
                  'transferId': 'transfer-background-2',
                  'filename': 'large.bin',
                  'size': 4,
                  'sha256': 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
                },
              ),
            ],
          ),
        ),
      );

    await BackgroundHeartbeatRunner(
      profileStore: profiles,
      credentialStore: credentials,
      linkService: link,
      notificationService: notifications,
      acknowledgementStore: MemoryBackgroundAcknowledgementStore(),
      offerNoticeStore: MemoryBackgroundOfferNoticeStore(),
      fileStore: FakeBackgroundFileStore(),
      fileTransferClient: const FailingBackgroundFileTransferClient(),
      includeIncomingOffers: true,
    ).run();

    expect(link.heartbeatAcknowledgements, [<String>[]]);
    expect(notifications.restoredActions.single.eventId, 'file-background-2');
  });

  test('seamless background saving is limited to same-account files', () async {
    const profile = ConnectionProfile(
      serverId: testServerId,
      serverName: 'Test Home',
      preferredUrl: 'https://home.example.test',
      deviceId: 'device-1',
      secure: true,
    );
    final profiles = MemoryProfileStore()..profiles.add(profile);
    final credentials = MemoryCredentialStore()
      ..values[testServerId] = 'device-credential';
    final notifications = FakeNotificationService();
    final link = FakeLinkService()
      ..heartbeatResults.addAll([
        const LinkSuccess(
          HeartbeatResponse(
            serverId: testServerId,
            events: [
              DeviceEvent(
                id: 'own-file-1',
                type: 'share.offer',
                payload: {
                  'type': 'file',
                  'sourceName': 'My laptop',
                  'transferId': 'own-transfer-1',
                  'filename': 'notes.pdf',
                  'mimeType': 'application/pdf',
                  'size': 4,
                  'sha256': 'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
                  'sameAccount': true,
                },
              ),
            ],
          ),
        ),
        const LinkSuccess(
          HeartbeatResponse(serverId: testServerId, events: []),
        ),
      ]);
    final files = FakeBackgroundFileStore();

    await BackgroundHeartbeatRunner(
      profileStore: profiles,
      credentialStore: credentials,
      linkService: link,
      notificationService: notifications,
      acknowledgementStore: MemoryBackgroundAcknowledgementStore(),
      offerNoticeStore: MemoryBackgroundOfferNoticeStore(),
      fileStore: files,
      fileTransferClient: const FakeBackgroundFileTransferClient(),
      includeIncomingOffers: true,
      seamlessOwnAccountTransfers: true,
    ).run();

    expect(files.savedNames, ['notes.pdf']);
    expect(notifications.incomingOffers, isEmpty);
    expect(link.heartbeatAcknowledgements.last, ['own-file-1']);
  });
}

final class FakeBackgroundFileStore implements BackgroundFileStore {
  final List<String> savedNames = [];

  @override
  Future<String> createTemporaryFilePath() async {
    final file = File(
      '${Directory.systemTemp.path}/homeplace-background-${DateTime.now().microsecondsSinceEpoch}.bin',
    );
    await file.create();
    return file.path;
  }

  @override
  Future<String> saveFilePath(
    String path,
    String filename,
    String mimeType,
  ) async {
    expect(await File(path).readAsBytes(), [1, 2, 3, 4]);
    savedNames.add(filename);
    return 'content://homeplace.test/$filename';
  }
}

final class FakeBackgroundFileTransferClient
    implements BackgroundFileTransferClient {
  const FakeBackgroundFileTransferClient();

  @override
  Future<LinkResult<DownloadedLinkFile>> download(
    ServerAddress address,
    String credential,
    BackgroundFileOffer offer,
    String destinationPath,
  ) async {
    final file = File(destinationPath);
    await file.writeAsBytes(const [1, 2, 3, 4], flush: true);
    return LinkSuccess(DownloadedLinkFile(file: file, size: 4));
  }
}

final class FailingBackgroundFileTransferClient
    implements BackgroundFileTransferClient {
  const FailingBackgroundFileTransferClient();

  @override
  Future<LinkResult<DownloadedLinkFile>> download(
    ServerAddress address,
    String credential,
    BackgroundFileOffer offer,
    String destinationPath,
  ) async => const LinkFailure(LinkFailureKind.network, 'Offline');
}

final class MemoryBackgroundAcknowledgementStore
    implements BackgroundAcknowledgementStore {
  final Map<String, List<String>> values = {};

  @override
  Future<List<String>> read(String serverId) async =>
      List.of(values[serverId] ?? const []);

  @override
  Future<void> write(String serverId, List<String> eventIds) async {
    if (eventIds.isEmpty) {
      values.remove(serverId);
    } else {
      values[serverId] = List.of(eventIds);
    }
  }
}

final class MemoryNotificationHistoryStore implements NotificationHistoryStore {
  List<NotificationHistoryItem> items = const [];

  @override
  Future<void> clear(String scope) async => items = const [];

  @override
  Future<List<NotificationHistoryItem>> read(String scope) async =>
      List.of(items);

  @override
  Future<void> write(String scope, List<NotificationHistoryItem> items) async =>
      this.items = List.of(items);
}

final class MemoryBackgroundOfferNoticeStore
    implements BackgroundOfferNoticeStore {
  final Map<String, List<String>> values = {};

  @override
  Future<List<String>> read(String serverId) async =>
      List.of(values[serverId] ?? const []);

  @override
  Future<void> write(String serverId, List<String> eventIds) async {
    values[serverId] = List.of(eventIds);
  }
}
