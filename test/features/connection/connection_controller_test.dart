import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/storage/connection_profile.dart';
import 'package:homeplace/features/connection/connection_controller.dart';

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
}
