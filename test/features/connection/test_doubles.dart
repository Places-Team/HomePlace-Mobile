import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/core/clipboard/clipboard_service.dart';
import 'package:homeplace/core/notifications/notification_service.dart';
import 'package:homeplace/core/platform/platform_identity.dart';
import 'package:homeplace/core/sharing/share_service.dart';
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
  String heartbeatServerId = testServerId;
  LinkResult<PairingSession>? pairingResult;
  LinkResult<PairingClaim>? claimResult;
  final List<LinkResult<HeartbeatResponse>> heartbeatResults = [];
  final List<List<String>> heartbeatAcknowledgements = [];
  List<Capability> reportedCapabilities = const [];
  List<String> requestedPermissions = const [];

  @override
  Future<LinkResult<ServerInfo>> fetchInfo(ServerAddress address) async =>
      infoResult;

  @override
  Future<LinkResult<PairingSession>> startPairing(
    ServerAddress address,
    DeviceDescription device,
    String publicKey,
    List<Capability> capabilities,
    List<String> permissions,
  ) async {
    reportedCapabilities = capabilities;
    requestedPermissions = permissions;
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
  ) async {
    heartbeatAcknowledgements.add(List.of(acknowledgedEventIds));
    if (heartbeatResults.isNotEmpty) return heartbeatResults.removeAt(0);
    return LinkSuccess(
      HeartbeatResponse(serverId: heartbeatServerId, events: const []),
    );
  }

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
  final List<String> incomingOffers = [];

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

  @override
  Future<void> showIncomingOffer(
    String id,
    String title,
    String body,
    String reviewLabel,
  ) async {
    incomingOffers.add('$id:$title:$body:$reviewLabel');
  }
}

final class FakeDeviceIdentity implements DeviceIdentity {
  const FakeDeviceIdentity();

  @override
  Future<String> publicKey(String serverId) async => 'public-key';
}

final class FakeClipboardService implements ClipboardService {
  FakeClipboardService({this.value});
  String? value;
  @override
  bool get isSupported => true;
  @override
  Future<String?> readText() async => value;
  @override
  Future<void> writeText(String text) async => value = text;
}

final class FakeShareService implements ShareService {
  List<SharedContent> pending = const [];
  @override
  bool get isSupported => true;
  @override
  Future<void> initialize(void Function(SharedContent content) onShare) async {
    for (final content in pending) {
      onShare(content);
    }
  }

  @override
  Future<void> openUrl(String url) async {}
  @override
  Future<void> saveFilePath(
    String path,
    String filename,
    String mimeType,
  ) async {}
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
