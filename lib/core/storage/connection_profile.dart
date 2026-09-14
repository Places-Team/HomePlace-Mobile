import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

final class ConnectionProfile {
  const ConnectionProfile({
    required this.serverId,
    required this.serverName,
    required this.preferredUrl,
    required this.deviceId,
    required this.secure,
    this.certificateFingerprint,
  });

  factory ConnectionProfile.fromJson(Map<String, dynamic> json) =>
      ConnectionProfile(
        serverId: json['serverId'] as String,
        serverName: json['serverName'] as String,
        preferredUrl: json['preferredUrl'] as String,
        deviceId: json['deviceId'] as String,
        secure: json['secure'] as bool,
        certificateFingerprint: json['certificateFingerprint'] as String?,
      );

  final String serverId;
  final String serverName;
  final String preferredUrl;
  final String deviceId;
  final bool secure;
  final String? certificateFingerprint;

  Map<String, dynamic> toJson() => {
    'serverId': serverId,
    'serverName': serverName,
    'preferredUrl': preferredUrl,
    'deviceId': deviceId,
    'secure': secure,
    if (certificateFingerprint != null)
      'certificateFingerprint': certificateFingerprint,
  };
}

abstract interface class ProfileStore {
  Future<List<ConnectionProfile>> readAll();
  Future<void> save(ConnectionProfile profile);
  Future<void> remove(String serverId);
}

final class SharedPreferencesProfileStore implements ProfileStore {
  static const _key = 'homeplace.connectionProfiles.v1';

  @override
  Future<List<ConnectionProfile>> readAll() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_key);
    if (encoded == null) return const [];
    try {
      return (jsonDecode(encoded) as List<dynamic>)
          .map(
            (item) => ConnectionProfile.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on FormatException {
      return const [];
    } on TypeError {
      return const [];
    }
  }

  @override
  Future<void> save(ConnectionProfile profile) async {
    final profiles = [...await readAll()]
      ..removeWhere((item) => item.serverId == profile.serverId);
    profiles.add(profile);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode(profiles.map((item) => item.toJson()).toList()),
    );
  }

  @override
  Future<void> remove(String serverId) async {
    final profiles = [...await readAll()]
      ..removeWhere((item) => item.serverId == serverId);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode(profiles.map((item) => item.toJson()).toList()),
    );
  }
}
