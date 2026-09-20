import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../sharing/share_service.dart';

enum TransferDirection { sent, received }

final class TransferActivity {
  const TransferActivity({
    required this.direction,
    required this.kind,
    required this.peerName,
    required this.at,
  });

  factory TransferActivity.fromJson(Map<String, dynamic> json) =>
      TransferActivity(
        direction: TransferDirection.values.byName(json['direction'] as String),
        kind: SharedContentKind.values.byName(json['kind'] as String),
        peerName: json['peerName'] as String,
        at: DateTime.parse(json['at'] as String),
      );

  final TransferDirection direction;
  final SharedContentKind kind;
  final String peerName;
  final DateTime at;

  Map<String, dynamic> toJson() => {
    'direction': direction.name,
    'kind': kind.name,
    'peerName': peerName,
    'at': at.toUtc().toIso8601String(),
  };
}

abstract interface class TransferActivityStore {
  Future<List<TransferActivity>> read(String scope);
  Future<void> write(String scope, List<TransferActivity> activities);
  Future<void> clear(String scope);
}

final class PlatformTransferActivityStore implements TransferActivityStore {
  const PlatformTransferActivityStore({
    this.storage = const FlutterSecureStorage(),
  });

  final FlutterSecureStorage storage;
  String _key(String scope) => 'homeplace.activity.$scope';

  @override
  Future<List<TransferActivity>> read(String scope) async {
    final value = await storage.read(
      key: _key(scope),
      aOptions: const AndroidOptions(),
      iOptions: const IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
    if (value == null) return const [];
    try {
      return (jsonDecode(value) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(TransferActivity.fromJson)
          .take(20)
          .toList(growable: false);
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> write(String scope, List<TransferActivity> activities) =>
      storage.write(
        key: _key(scope),
        value: jsonEncode(
          activities.take(20).map((activity) => activity.toJson()).toList(),
        ),
        aOptions: const AndroidOptions(),
        iOptions: const IOSOptions(
          accessibility: KeychainAccessibility.first_unlock_this_device,
        ),
      );

  @override
  Future<void> clear(String scope) => storage.delete(
    key: _key(scope),
    aOptions: const AndroidOptions(),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
}
