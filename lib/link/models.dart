const supportedLinkProtocol = 1;

final class LinkServer {
  const LinkServer({required this.id, required this.name});
  factory LinkServer.fromJson(Map<String, dynamic> json) => LinkServer(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
  );
  final String id;
  final String name;
}

final class LinkProtocolRange {
  const LinkProtocolRange({required this.min, required this.max});
  factory LinkProtocolRange.fromJson(Map<String, dynamic> json) =>
      LinkProtocolRange(
        min: json['min'] as int? ?? 0,
        max: json['max'] as int? ?? 0,
      );
  final int min;
  final int max;
}

final class LinkFeatures {
  const LinkFeatures({required this.pairing, required this.realtime});
  factory LinkFeatures.fromJson(Map<String, dynamic> json) => LinkFeatures(
    pairing: json['pairing'] as bool? ?? false,
    realtime: json['realtime'] as bool? ?? false,
  );
  final bool pairing;
  final bool realtime;
}

final class ServerInfo {
  const ServerInfo({
    required this.product,
    required this.server,
    required this.protocol,
    required this.serverTime,
    required this.features,
  });

  factory ServerInfo.fromJson(Map<String, dynamic> json) => ServerInfo(
    product: json['product'] as String? ?? '',
    server: LinkServer.fromJson(
      json['server'] as Map<String, dynamic>? ?? const {},
    ),
    protocol: LinkProtocolRange.fromJson(
      json['protocol'] as Map<String, dynamic>? ?? const {},
    ),
    serverTime: json['serverTime'] as String? ?? '',
    features: LinkFeatures.fromJson(
      json['features'] as Map<String, dynamic>? ?? const {},
    ),
  );

  final String product;
  final LinkServer server;
  final LinkProtocolRange protocol;
  final String serverTime;
  final LinkFeatures features;

  bool get supportsClient =>
      product == 'HomePlace' &&
      _uuid.hasMatch(server.id) &&
      server.name.trim().isNotEmpty &&
      protocol.min <= protocol.max &&
      supportedLinkProtocol >= protocol.min &&
      supportedLinkProtocol <= protocol.max;

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
  );
}

final class Capability {
  const Capability({
    required this.name,
    this.version = 1,
    this.constraints = const {},
  });
  final String name;
  final int version;
  final Map<String, String> constraints;

  Map<String, dynamic> toJson() => {
    'name': name,
    'version': version,
    'constraints': constraints,
  };
}

final class PlatformFeatures {
  const PlatformFeatures({
    this.notificationReceive = false,
    this.urlOpen = false,
    this.textReceive = false,
    this.fileReceive = false,
    this.shareSend = false,
    this.batteryReporting = false,
    this.networkReporting = false,
    this.foregroundPresence = false,
  });

  final bool notificationReceive;
  final bool urlOpen;
  final bool textReceive;
  final bool fileReceive;
  final bool shareSend;
  final bool batteryReporting;
  final bool networkReporting;
  final bool foregroundPresence;
}

abstract final class CapabilityNegotiator {
  static List<Capability> available(PlatformFeatures features) => [
    if (features.notificationReceive)
      const Capability(name: 'notification.receive'),
    if (features.urlOpen) const Capability(name: 'url.open'),
    if (features.textReceive) const Capability(name: 'text.receive'),
    if (features.fileReceive)
      const Capability(
        name: 'file.receive',
        constraints: {'requiresConfirmation': 'true'},
      ),
    if (features.shareSend) const Capability(name: 'share.send'),
    if (features.batteryReporting) const Capability(name: 'device.battery'),
    if (features.networkReporting) const Capability(name: 'device.network'),
    if (features.foregroundPresence)
      const Capability(
        name: 'device.presence',
        constraints: {'mode': 'foreground'},
      ),
  ];
}

sealed class IdentityCheck {
  const IdentityCheck();
}

final class IdentityMatch extends IdentityCheck {
  const IdentityMatch();
}

final class IdentityMismatch extends IdentityCheck {
  const IdentityMismatch({required this.expected, required this.actual});
  final String expected;
  final String actual;
}

IdentityCheck verifyServerIdentity(String expected, ServerInfo actual) =>
    expected == actual.server.id
    ? const IdentityMatch()
    : IdentityMismatch(expected: expected, actual: actual.server.id);
