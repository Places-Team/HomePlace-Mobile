import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/background/background_delivery.dart';
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
