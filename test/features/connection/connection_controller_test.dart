import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/storage/connection_profile.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/link/link_client.dart';
import 'package:homeplace/link/models.dart';

import 'test_doubles.dart';

void main() {
  test('completes pairing and persists the connection securely', () async {
    final link = FakeLinkService();
    final profiles = MemoryProfileStore();
    final credentials = MemoryCredentialStore();
    final controller = ConnectionController(
      linkService: link,
      profileStore: profiles,
      credentialStore: credentials,
      deviceIdentity: const FakeDeviceIdentity(),
      notificationService: FakeNotificationService(),
      descriptionProvider: const FakeDescriptionProvider(),
      pollDelay: (_) async {},
      clipboardService: FakeClipboardService(),
      shareService: FakeShareService(),
    );

    controller.continueFromWelcome();
    controller.setAddress('192.168.1.10');
    await controller.validateAddress();
    expect(controller.stage, ConnectionStage.preview);

    await controller.startPairing(requestNotifications: true);
    for (
      var attempt = 0;
      attempt < 10 && controller.stage != ConnectionStage.connected;
      attempt++
    ) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(controller.stage, ConnectionStage.connected);
    expect(credentials.values[testServerId], 'device-credential');
    expect(profiles.profiles.single.deviceId, 'device-1');
    expect(link.reportedCapabilities.map((capability) => capability.name), [
      'notification.receive',
      'url.open',
      'text.receive',
      'file.receive',
      'share.send',
      'device.presence',
      'clipboard.send',
      'clipboard.receive',
    ]);
    expect(link.requestedPermissions, [
      'dashboard.read',
      'calendar.read',
      'calendar.manage',
      'reminder.manage',
      'media.request',
      'telegram.send',
      'clipboard.relay',
      'share.relay',
    ]);
    controller.dispose();
  });

  test('refuses a saved profile when the server identity changes', () async {
    final profiles = MemoryProfileStore();
    profiles.profiles.add(
      const ConnectionProfile(
        serverId: '067ee4ce-60d1-44f6-b7bc-c1d6528e47aa',
        serverName: 'Old Home',
        preferredUrl: 'http://192.168.1.10',
        deviceId: 'device-1',
        secure: false,
      ),
    );
    final credentials = MemoryCredentialStore();
    credentials.values['067ee4ce-60d1-44f6-b7bc-c1d6528e47aa'] = 'credential';
    final controller = ConnectionController(
      linkService: FakeLinkService(),
      profileStore: profiles,
      credentialStore: credentials,
      deviceIdentity: const FakeDeviceIdentity(),
      notificationService: FakeNotificationService(),
      descriptionProvider: const FakeDescriptionProvider(),
    );

    await controller.initialize();

    expect(controller.stage, ConnectionStage.welcome);
    expect(controller.error, contains('different identity'));
    controller.dispose();
  });

  test('switches profiles only after validating the saved server ID', () async {
    const otherServerId = 'c956a1b1-244c-46c2-b4c8-a0dbf7449558';
    const otherInfo = ServerInfo(
      product: 'HomePlace',
      server: LinkServer(id: otherServerId, name: 'Family Home'),
      protocol: LinkProtocolRange(min: 1, max: 1),
      serverTime: '2026-09-21T12:00:00Z',
      features: LinkFeatures(pairing: true, realtime: false),
    );
    const primary = ConnectionProfile(
      serverId: testServerId,
      serverName: 'Test Home',
      preferredUrl: 'https://home.example.test',
      deviceId: 'device-1',
      secure: true,
    );
    const other = ConnectionProfile(
      serverId: otherServerId,
      serverName: 'Family Home',
      preferredUrl: 'https://family.example.test',
      deviceId: 'device-2',
      secure: true,
    );
    final link = FakeLinkService();
    final profiles = MemoryProfileStore()..profiles.addAll([other, primary]);
    final credentials = MemoryCredentialStore()
      ..values.addAll({
        testServerId: 'primary-credential',
        otherServerId: 'other-credential',
      });
    final controller = ConnectionController(
      linkService: link,
      profileStore: profiles,
      credentialStore: credentials,
      deviceIdentity: const FakeDeviceIdentity(),
      notificationService: FakeNotificationService(),
      descriptionProvider: const FakeDescriptionProvider(),
    );

    await controller.initialize();
    expect(controller.profile?.serverId, testServerId);
    expect(controller.profiles, hasLength(2));

    link.infoResult = const LinkSuccess(otherInfo);
    link.heartbeatServerId = otherServerId;
    expect(await controller.switchProfile(other), isTrue);
    expect(controller.profile?.serverId, otherServerId);
    expect(profiles.profiles.last.serverId, otherServerId);
    expect(credentials.values[testServerId], 'primary-credential');
    expect(credentials.values[otherServerId], 'other-credential');
    controller.dispose();
  });

  test(
    'keeps the active profile when another address has a different ID',
    () async {
      const impostorProfile = ConnectionProfile(
        serverId: 'c956a1b1-244c-46c2-b4c8-a0dbf7449558',
        serverName: 'Other Home',
        preferredUrl: 'https://other.example.test',
        deviceId: 'device-2',
        secure: true,
      );
      const primary = ConnectionProfile(
        serverId: testServerId,
        serverName: 'Test Home',
        preferredUrl: 'https://home.example.test',
        deviceId: 'device-1',
        secure: true,
      );
      final link = FakeLinkService();
      final profiles = MemoryProfileStore()
        ..profiles.addAll([impostorProfile, primary]);
      final credentials = MemoryCredentialStore()
        ..values.addAll({
          testServerId: 'primary-credential',
          impostorProfile.serverId: 'other-credential',
        });
      final controller = ConnectionController(
        linkService: link,
        profileStore: profiles,
        credentialStore: credentials,
        deviceIdentity: const FakeDeviceIdentity(),
        notificationService: FakeNotificationService(),
        descriptionProvider: const FakeDescriptionProvider(),
      );

      await controller.initialize();
      expect(await controller.switchProfile(impostorProfile), isFalse);
      expect(controller.profile?.serverId, testServerId);
      expect(controller.error, contains('different identity'));
      controller.dispose();
    },
  );

  test('keeps multiple incoming file offers until each is reviewed', () async {
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
      ..heartbeatResults.add(
        const LinkSuccess(
          HeartbeatResponse(
            serverId: testServerId,
            events: [
              DeviceEvent(
                id: 'file-1',
                type: 'share.offer',
                payload: {
                  'type': 'file',
                  'sourceName': 'Phone',
                  'transferId': 'transfer-1',
                  'filename': 'first.txt',
                  'size': 200 * 1024 * 1024,
                  'sha256': 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
                },
              ),
              DeviceEvent(
                id: 'file-2',
                type: 'share.offer',
                payload: {
                  'type': 'file',
                  'sourceName': 'Tablet',
                  'transferId': 'transfer-2',
                  'filename': 'second.txt',
                  'size': 6,
                  'sha256': 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
                },
              ),
            ],
          ),
        ),
      );
    final controller = ConnectionController(
      linkService: link,
      profileStore: profiles,
      credentialStore: credentials,
      deviceIdentity: const FakeDeviceIdentity(),
      notificationService: FakeNotificationService(),
      descriptionProvider: const FakeDescriptionProvider(),
      clipboardService: FakeClipboardService(),
      shareService: FakeShareService(),
    );

    await controller.initialize();
    for (
      var attempt = 0;
      attempt < 10 && controller.pendingIncomingShares.length < 2;
      attempt++
    ) {
      await Future<void>.delayed(Duration.zero);
    }

    expect(controller.pendingIncomingShares.map((offer) => offer.filename), [
      'first.txt',
      'second.txt',
    ]);
    controller.dismissIncomingShare(controller.pendingIncomingShares.first);
    expect(controller.pendingIncomingShares.single.filename, 'second.txt');
    controller.dispose();
  });
}
