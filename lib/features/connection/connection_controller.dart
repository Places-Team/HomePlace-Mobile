import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/clipboard/clipboard_service.dart';
import '../../core/network/server_address.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/platform/platform_identity.dart';
import '../../core/sharing/share_service.dart';
import '../../core/storage/connection_profile.dart';
import '../../core/storage/credential_store.dart';
import '../../link/link_client.dart';
import '../../link/models.dart';

enum ConnectionStage {
  welcome,
  address,
  validating,
  preview,
  pairing,
  connected,
}

final class AuthenticatedLinkSession {
  const AuthenticatedLinkSession({
    required this.address,
    required this.credential,
    required this.serverId,
    required this.serverName,
  });

  final ServerAddress address;
  final String credential;
  final String serverId;
  final String serverName;
}

final class PendingClipboard {
  const PendingClipboard({
    required this.eventId,
    required this.text,
    required this.sourceName,
  });
  final String eventId;
  final String text;
  final String sourceName;
}

final class PendingShareOffer {
  const PendingShareOffer({
    required this.eventId,
    required this.kind,
    required this.sourceName,
    this.value,
    this.transferId,
    this.filename,
    this.mimeType,
    this.size,
    this.sha256,
  });
  final String eventId;
  final SharedContentKind kind;
  final String sourceName;
  final String? value;
  final String? transferId;
  final String? filename;
  final String? mimeType;
  final int? size;
  final String? sha256;
}

abstract interface class DeviceDescriptionProvider {
  Future<DeviceDescription> describe();
}

final class PlatformDeviceDescriptionProvider
    implements DeviceDescriptionProvider {
  @override
  Future<DeviceDescription> describe() async {
    final package = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      return DeviceDescription(
        name: info.model,
        platform: 'android',
        platformVersion: info.version.release,
        appVersion: package.version,
      );
    }
    final info = await deviceInfo.iosInfo;
    return DeviceDescription(
      name: info.name,
      platform: 'ios',
      platformVersion: info.systemVersion,
      appVersion: package.version,
    );
  }
}

final class ConnectionController extends ChangeNotifier {
  ConnectionController({
    LinkService? linkService,
    ProfileStore? profileStore,
    CredentialStore? credentialStore,
    DeviceIdentity? deviceIdentity,
    NotificationService? notificationService,
    DeviceDescriptionProvider? descriptionProvider,
    Future<void> Function(Duration)? pollDelay,
    ClipboardService? clipboardService,
    ShareService? shareService,
  }) : _link = linkService ?? const HttpLinkService(),
       _profiles = profileStore ?? SharedPreferencesProfileStore(),
       _credentials = credentialStore ?? const PlatformCredentialStore(),
       _identity = deviceIdentity ?? const PlatformDeviceIdentity(),
       _notifications = notificationService ?? LocalNotificationService(),
       _description =
           descriptionProvider ?? PlatformDeviceDescriptionProvider(),
       _pollDelay = pollDelay ?? Future<void>.delayed,
       _clipboard = clipboardService ?? const PlatformClipboardService(),
       _sharing = shareService ?? const PlatformShareService();

  final LinkService _link;
  final ProfileStore _profiles;
  final CredentialStore _credentials;
  final DeviceIdentity _identity;
  final NotificationService _notifications;
  final DeviceDescriptionProvider _description;
  final Future<void> Function(Duration) _pollDelay;
  final ClipboardService _clipboard;
  final ShareService _sharing;

  ConnectionStage stage = ConnectionStage.welcome;
  String addressInput = '';
  String? error;
  String? diagnostics;
  String? pendingCertificateFingerprint;
  ServerAddress? serverAddress;
  ServerInfo? serverInfo;
  PairingSession? pairingSession;
  ConnectionProfile? profile;
  String? lastNotification;
  PendingClipboard? pendingClipboard;
  String? _clipboardTextToSuppress;
  SharedContent? pendingOutgoingShare;
  PendingShareOffer? pendingIncomingShare;
  Timer? _heartbeatTimer;
  bool _polling = false;
  List<String> _acknowledgedEventIds = const [];

  Future<void> initialize() async {
    await _notifications.initialize();
    await _sharing.initialize((content) {
      _discardOutgoingFile();
      pendingOutgoingShare = content;
      notifyListeners();
    });
    final saved = await _profiles.readAll();
    if (saved.isEmpty) return;
    final candidate = saved.first;
    final normalized = ServerAddressNormalizer.normalize(
      candidate.preferredUrl,
    );
    if (normalized is! ValidAddress) return;
    var restored = normalized.address;
    if (candidate.certificateFingerprint case final fingerprint?) {
      restored = restored.trustFingerprint(fingerprint);
    }
    final credential = await _credentials.read(candidate.serverId);
    if (credential == null) return;
    final result = await _link.fetchInfo(restored);
    if (result is! LinkSuccess<ServerInfo>) {
      diagnostics = result is LinkFailure<ServerInfo> ? result.message : null;
      return;
    }
    if (verifyServerIdentity(candidate.serverId, result.value)
        is IdentityMismatch) {
      error = 'The server at this address has a different identity.';
      diagnostics =
          'Expected ${candidate.serverId}; received ${result.value.server.id}.';
      return;
    }
    serverAddress = restored;
    serverInfo = result.value;
    profile = candidate;
    addressInput = candidate.preferredUrl;
    stage = ConnectionStage.connected;
    _startHeartbeat();
    notifyListeners();
  }

  void continueFromWelcome() {
    stage = ConnectionStage.address;
    error = null;
    notifyListeners();
  }

  void setAddress(String value) {
    addressInput = value;
    error = null;
    pendingCertificateFingerprint = null;
    notifyListeners();
  }

  Future<void> validateAddress() async {
    final normalized = ServerAddressNormalizer.normalize(addressInput);
    if (normalized is InvalidAddress) {
      error = normalized.message;
      stage = ConnectionStage.address;
      notifyListeners();
      return;
    }
    serverAddress = (normalized as ValidAddress).address;
    await _fetchServerInfo();
  }

  Future<void> confirmCertificate() async {
    final fingerprint = pendingCertificateFingerprint;
    final address = serverAddress;
    if (fingerprint == null || address == null) return;
    serverAddress = address.trustFingerprint(fingerprint);
    pendingCertificateFingerprint = null;
    await _fetchServerInfo();
  }

  Future<void> _fetchServerInfo() async {
    final address = serverAddress;
    if (address == null) return;
    stage = ConnectionStage.validating;
    error = null;
    diagnostics = null;
    notifyListeners();
    final result = await _link.fetchInfo(address);
    switch (result) {
      case LinkSuccess<ServerInfo>():
        serverInfo = result.value;
        stage = ConnectionStage.preview;
      case LinkFailure<ServerInfo>():
        error = result.message;
        diagnostics = result.kind.name;
        if (result.kind == LinkFailureKind.tls &&
            result.certificateFingerprint != null) {
          pendingCertificateFingerprint = result.certificateFingerprint;
        }
        stage = ConnectionStage.address;
    }
    notifyListeners();
  }

  Future<void> startPairing({required bool requestNotifications}) async {
    final address = serverAddress;
    final info = serverInfo;
    if (address == null || info == null || !info.features.pairing) return;
    stage = ConnectionStage.pairing;
    error = null;
    pairingSession = null;
    notifyListeners();
    try {
      final notificationAvailable =
          requestNotifications && await _notifications.requestPermission();
      final capabilities = CapabilityNegotiator.available(
        PlatformFeatures(
          notificationReceive: notificationAvailable,
          foregroundPresence: true,
          clipboardSend: _clipboard.isSupported,
          clipboardReceive: _clipboard.isSupported,
          shareSend: _sharing.isSupported,
          textReceive: _sharing.isSupported,
          urlOpen: _sharing.isSupported,
          fileReceive: _sharing.isSupported,
        ),
      );
      final result = await _link.startPairing(
        address,
        await _description.describe(),
        await _identity.publicKey(info.server.id),
        capabilities,
        [
          'dashboard.read',
          'calendar.read',
          'calendar.manage',
          'reminder.manage',
          'media.request',
          'telegram.send',
          'clipboard.relay',
          if (_sharing.isSupported) 'share.relay',
        ],
      );
      switch (result) {
        case LinkSuccess<PairingSession>():
          pairingSession = result.value;
          notifyListeners();
          unawaited(_pollPairing(result.value));
        case LinkFailure<PairingSession>():
          error = result.message;
          diagnostics = result.kind.name;
          stage = ConnectionStage.preview;
          notifyListeners();
      }
    } on Object catch (exception) {
      error = 'Secure device identity is unavailable.';
      diagnostics = exception.runtimeType.toString();
      stage = ConnectionStage.preview;
      notifyListeners();
    }
  }

  Future<void> _pollPairing(PairingSession session) async {
    if (_polling) return;
    _polling = true;
    try {
      while (stage == ConnectionStage.pairing &&
          DateTime.now().isBefore(session.expiresAt)) {
        await _pollDelay(
          Duration(seconds: session.pollAfterSeconds.clamp(1, 10)),
        );
        if (stage != ConnectionStage.pairing) return;
        final address = serverAddress!;
        final result = await _link.claimPairing(address, session);
        if (result is LinkFailure<PairingClaim>) {
          if (result.kind == LinkFailureKind.network) continue;
          error = result.message;
          diagnostics = result.kind.name;
          stage = ConnectionStage.preview;
          notifyListeners();
          return;
        }
        final claim = (result as LinkSuccess<PairingClaim>).value;
        switch (claim.status) {
          case 'pending':
            continue;
          case 'approved':
            await _completePairing(claim);
            return;
          case 'rejected':
            error = 'Pairing was rejected in HomePlace.';
          default:
            error = 'The pairing session expired.';
        }
        stage = ConnectionStage.preview;
        notifyListeners();
        return;
      }
      if (stage == ConnectionStage.pairing) {
        error = 'The pairing session expired.';
        stage = ConnectionStage.preview;
        notifyListeners();
      }
    } finally {
      _polling = false;
    }
  }

  Future<void> _completePairing(PairingClaim claim) async {
    final info = serverInfo!;
    final address = serverAddress!;
    if (claim.serverId != info.server.id ||
        claim.deviceId == null ||
        claim.credential == null) {
      error = 'HomePlace returned a different server identity.';
      diagnostics = 'Pairing claim did not match ${info.server.id}.';
      stage = ConnectionStage.preview;
      notifyListeners();
      return;
    }
    await _credentials.write(info.server.id, claim.credential!);
    final connectedProfile = ConnectionProfile(
      serverId: info.server.id,
      serverName: info.server.name,
      preferredUrl: address.uri.toString(),
      deviceId: claim.deviceId!,
      secure: address.security != ConnectionSecurity.localHttp,
      certificateFingerprint: address.certificateFingerprint,
    );
    await _profiles.save(connectedProfile);
    profile = connectedProfile;
    pairingSession = null;
    stage = ConnectionStage.connected;
    notifyListeners();
    _startHeartbeat();
  }

  void cancelPairing() {
    pairingSession = null;
    stage = ConnectionStage.preview;
    notifyListeners();
  }

  Future<AuthenticatedLinkSession?> authenticatedSession() async {
    final connectedProfile = profile;
    final address = serverAddress;
    if (stage != ConnectionStage.connected ||
        connectedProfile == null ||
        address == null) {
      return null;
    }
    final credential = await _credentials.read(connectedProfile.serverId);
    if (credential == null) return null;
    return AuthenticatedLinkSession(
      address: address,
      credential: credential,
      serverId: connectedProfile.serverId,
      serverName: connectedProfile.serverName,
    );
  }

  Future<String?> readClipboardText() async {
    if (!_clipboard.isSupported) return null;
    return _clipboard.readText();
  }

  Future<String?> readClipboardTextForAutoRelay() async {
    final text = (await readClipboardText())?.trim();
    if (text == null || text.isEmpty) return null;
    if (text == _clipboardTextToSuppress) return null;
    _clipboardTextToSuppress = null;
    return text;
  }

  Future<void> acceptPendingClipboard() async {
    final pending = pendingClipboard;
    if (pending == null || !_clipboard.isSupported) return;
    await _clipboard.writeText(pending.text);
    _clipboardTextToSuppress = pending.text.trim();
    _acknowledgedEventIds = {
      ..._acknowledgedEventIds,
      pending.eventId,
    }.toList(growable: false);
    pendingClipboard = null;
    notifyListeners();
  }

  void dismissPendingClipboard() {
    final pending = pendingClipboard;
    if (pending == null) return;
    _acknowledgedEventIds = {
      ..._acknowledgedEventIds,
      pending.eventId,
    }.toList(growable: false);
    pendingClipboard = null;
    notifyListeners();
  }

  void clearOutgoingShare() {
    _discardOutgoingFile();
    pendingOutgoingShare = null;
    notifyListeners();
  }

  Future<void> acceptIncomingTextOrUrl() async {
    final pending = pendingIncomingShare;
    if (pending == null) return;
    if (pending.kind == SharedContentKind.text && pending.value != null) {
      await _clipboard.writeText(pending.value!);
    } else if (pending.kind == SharedContentKind.url && pending.value != null) {
      await _sharing.openUrl(pending.value!);
    } else {
      return;
    }
    _acknowledgeIncomingShare(pending.eventId);
  }

  Future<void> saveIncomingFile(Uint8List bytes) async {
    final pending = pendingIncomingShare;
    if (pending == null ||
        pending.kind != SharedContentKind.file ||
        pending.filename == null) {
      return;
    }
    await _sharing.saveFile(
      bytes,
      pending.filename!,
      pending.mimeType ?? 'application/octet-stream',
    );
    _acknowledgeIncomingShare(pending.eventId);
  }

  void dismissIncomingShare() {
    final pending = pendingIncomingShare;
    if (pending != null) _acknowledgeIncomingShare(pending.eventId);
  }

  void _acknowledgeIncomingShare(String eventId) {
    _acknowledgedEventIds = {
      ..._acknowledgedEventIds,
      eventId,
    }.toList(growable: false);
    pendingIncomingShare = null;
    notifyListeners();
  }

  void _discardOutgoingFile() {
    final path = pendingOutgoingShare?.path;
    if (path != null) {
      unawaited(File(path).delete().catchError((_) => File(path)));
    }
  }

  Future<void> disconnect() async {
    final connectedProfile = profile;
    final address = serverAddress;
    if (connectedProfile == null || address == null) return;
    final credential = await _credentials.read(connectedProfile.serverId);
    if (credential == null) {
      await _forgetConnection(connectedProfile);
      return;
    }
    final result = await _link.revoke(address, credential);
    if (result is LinkFailure<void> &&
        result.kind != LinkFailureKind.authentication) {
      error = result.message;
      diagnostics = result.kind.name;
      notifyListeners();
      return;
    }
    await _forgetConnection(connectedProfile);
  }

  Future<void> _forgetConnection(ConnectionProfile connectedProfile) async {
    _heartbeatTimer?.cancel();
    await _credentials.remove(connectedProfile.serverId);
    await _profiles.remove(connectedProfile.serverId);
    stage = ConnectionStage.welcome;
    serverAddress = null;
    serverInfo = null;
    profile = null;
    error = null;
    diagnostics = null;
    lastNotification = null;
    pendingClipboard = null;
    _clipboardTextToSuppress = null;
    pendingIncomingShare = null;
    clearOutgoingShare();
    notifyListeners();
  }

  void useAnotherAddress() {
    _heartbeatTimer?.cancel();
    stage = ConnectionStage.address;
    serverAddress = null;
    serverInfo = null;
    pairingSession = null;
    _clipboardTextToSuppress = null;
    error = null;
    notifyListeners();
  }

  void applyQrPayload(String value) {
    try {
      final decoded = Uri.tryParse(value);
      if (decoded?.hasScheme == true) {
        setAddress(value);
        return;
      }
      final jsonUrl = RegExp(r'"serverUrl"\s*:\s*"([^"]+)"')
          .firstMatch(value)
          ?.group(1);
      setAddress(jsonUrl ?? value);
    } on Object {
      setAddress(value);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    unawaited(_heartbeat());
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 25),
      (_) => unawaited(_heartbeat()),
    );
  }

  Future<void> _heartbeat() async {
    final connectedProfile = profile;
    final address = serverAddress;
    if (stage != ConnectionStage.connected ||
        connectedProfile == null ||
        address == null) {
      return;
    }
    final credential = await _credentials.read(connectedProfile.serverId);
    if (credential == null) return;
    final result = await _link.heartbeat(
      address,
      credential,
      _acknowledgedEventIds,
    );
    if (result is LinkFailure<HeartbeatResponse>) {
      diagnostics = result.message;
      notifyListeners();
      return;
    }
    final response = (result as LinkSuccess<HeartbeatResponse>).value;
    if (response.serverId != connectedProfile.serverId) {
      _heartbeatTimer?.cancel();
      error = 'The server identity changed. Connection stopped.';
      diagnostics =
          'Expected ${connectedProfile.serverId}; received ${response.serverId}.';
      notifyListeners();
      return;
    }
    final acknowledged = <String>[];
    for (final event in response.events) {
      if (event.type == 'clipboard.offer') {
        final text = event.payload['text'];
        final sourceName = event.payload['sourceName'];
        if (text is String &&
            text.isNotEmpty &&
            text.length <= 8000 &&
            sourceName is String) {
          pendingClipboard = PendingClipboard(
            eventId: event.id,
            text: text,
            sourceName: sourceName,
          );
        }
        continue;
      }
      if (event.type == 'share.offer') {
        final type = event.payload['type'];
        final sourceName = event.payload['sourceName'];
        if (sourceName is! String) continue;
        if ((type == 'text' || type == 'url') &&
            event.payload['value'] is String) {
          final value = event.payload['value'] as String;
          final uri = type == 'url' ? Uri.tryParse(value) : null;
          if (value.isEmpty || value.length > (type == 'url' ? 4096 : 8000)) {
            continue;
          }
          if (type == 'url' &&
              (uri == null ||
                  !{'http', 'https'}.contains(uri.scheme) ||
                  uri.userInfo.isNotEmpty)) {
            continue;
          }
          pendingIncomingShare = PendingShareOffer(
            eventId: event.id,
            kind: type == 'url'
                ? SharedContentKind.url
                : SharedContentKind.text,
            sourceName: sourceName,
            value: value,
          );
        } else if (type == 'file') {
          final transferId = event.payload['transferId'];
          final filename = event.payload['filename'];
          final size = event.payload['size'];
          final sha256 = event.payload['sha256'];
          if (transferId is String &&
              filename is String &&
              size is int &&
              size > 0 &&
              size <= 5 * 1024 * 1024 &&
              sha256 is String) {
            pendingIncomingShare = PendingShareOffer(
              eventId: event.id,
              kind: SharedContentKind.file,
              sourceName: sourceName,
              transferId: transferId,
              filename: filename,
              mimeType: event.payload['mimeType'] as String?,
              size: size,
              sha256: sha256,
            );
          }
        }
        continue;
      }
      if (event.type != 'notification.deliver') continue;
      final title = event.payload['title'];
      final body = event.payload['body'];
      if (title is! String || body is! String) continue;
      await _notifications.show(event.id, title, body);
      acknowledged.add(event.id);
      lastNotification = '$title — $body';
    }
    _acknowledgedEventIds = acknowledged;
    diagnostics = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}
