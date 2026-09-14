import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/core/notifications/notification_service.dart';
import 'package:homeplace/core/platform/platform_identity.dart';
import 'package:homeplace/core/storage/connection_profile.dart';
import 'package:homeplace/core/storage/credential_store.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/link/link_client.dart';
import 'package:homeplace/link/models.dart';

const testServerId = '9d55059f-5a47-4f23-a778-5714c6744907';

const testServerInfo = ServerInfo(
  product: 'HomePlace',
  server: LinkServer(id: testServerId, name: 'Test Home'),
  protocol: LinkProtocolRange(min: 1, max: 1),
  serverTime: '2026-09-13T12:00:00Z',
  features: LinkFeatures(pairing: true, realtime: true),
);

final class FakeLinkService implements LinkService {
  LinkResult<ServerInfo> infoResult = const LinkSuccess(testServerInfo);
  LinkResult<PairingSession>? pairingResult;
  LinkResult<PairingClaim>? claimResult;
  List<Capability> reportedCapabilities = const [];

  @override
  Future<LinkResult<ServerInfo>> fetchInfo(ServerAddress address) async =>
      infoResult;

  @override
  Future<LinkResult<PairingSession>> startPairing(
    ServerAddress address,
    DeviceDescription device,
    String publicKey,
    List<Capability> capabilities,
  ) async {
    reportedCapabilities = capabilities;
    return pairingResult ??
        LinkSuccess(
          PairingSession(
            id: 'pairing-1',
            code: '123456',
            claimSecret: 'claim-secret',
            expiresAt: DateTime.now().add(const Duration(minutes: 1)),
            pollAfterSeconds: 1,
          ),
        );
  }

  @override
  Future<LinkResult<PairingClaim>> claimPairing(
    ServerAddress address,
    PairingSession session,
  ) async =>
      claimResult ??
      const LinkSuccess(
        PairingClaim(
          status: 'approved',
          serverId: testServerId,
          deviceId: 'device-1',
          credential: 'device-credential',
        ),
      );

  @override
  Future<LinkResult<HeartbeatResponse>> heartbeat(
    ServerAddress address,
    String credential,
    List<String> acknowledgedEventIds,
  ) async =>
      const LinkSuccess(HeartbeatResponse(serverId: testServerId, events: []));

  @override
  Future<LinkResult<void>> revoke(
    ServerAddress address,
    String credential,
  ) async => const LinkSuccess(null);
}

final class MemoryProfileStore implements ProfileStore {
  final List<ConnectionProfile> profiles = [];

  @override
  Future<List<ConnectionProfile>> readAll() async => List.of(profiles);

  @override
  Future<void> remove(String serverId) async {
    profiles.removeWhere((profile) => profile.serverId == serverId);
  }

  @override
  Future<void> save(ConnectionProfile profile) async {
    await remove(profile.serverId);
    profiles.add(profile);
  }
}

final class MemoryCredentialStore implements CredentialStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String serverId) async => values[serverId];

  @override
  Future<void> remove(String serverId) async {
    values.remove(serverId);
  }

  @override
  Future<void> write(String serverId, String credential) async {
    values[serverId] = credential;
  }
}

final class FakeNotificationService implements NotificationService {
  FakeNotificationService({this.permissionGranted = true});
  final bool permissionGranted;
  final List<String> delivered = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> isAvailable() async => permissionGranted;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> show(String id, String title, String body) async {
    delivered.add('$title:$body');
  }
}

final class FakeDeviceIdentity implements DeviceIdentity {
  const FakeDeviceIdentity();

  @override
  Future<String> publicKey(String serverId) async => 'public-key';
}

final class FakeDescriptionProvider implements DeviceDescriptionProvider {
  const FakeDescriptionProvider();

  @override
  Future<DeviceDescription> describe() async => const DeviceDescription(
    name: 'Test phone',
    platform: 'android',
    platformVersion: '15',
    appVersion: '0.1.0',
  );
}
