import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final class NotificationHistoryItem {
  const NotificationHistoryItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
  });

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) =>
      NotificationHistoryItem(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        receivedAt: DateTime.parse(json['receivedAt'] as String),
      );

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'receivedAt': receivedAt.toUtc().toIso8601String(),
  };
}

String notificationHistoryScope(String serverId, String credential) =>
    sha256.convert(utf8.encode('$serverId:$credential')).toString();

abstract interface class NotificationHistoryStore {
  Future<List<NotificationHistoryItem>> read(String scope);
  Future<void> write(String scope, List<NotificationHistoryItem> items);
  Future<void> clear(String scope);
}

final class PlatformNotificationHistoryStore
    implements NotificationHistoryStore {
  const PlatformNotificationHistoryStore({
    this.storage = const FlutterSecureStorage(),
  });

  final FlutterSecureStorage storage;
  String _key(String scope) => 'homeplace.notifications.$scope';

  @override
  Future<List<NotificationHistoryItem>> read(String scope) async {
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
          .map(NotificationHistoryItem.fromJson)
          .where(
            (item) =>
                item.id.isNotEmpty &&
                item.title.isNotEmpty &&
                item.title.length <= 120 &&
                item.body.isNotEmpty &&
                item.body.length <= 2000,
          )
          .take(30)
          .toList(growable: false);
    } on Object {
      return const [];
    }
  }

  @override
  Future<void> write(String scope, List<NotificationHistoryItem> items) =>
      storage.write(
        key: _key(scope),
        value: jsonEncode(items.take(30).map((item) => item.toJson()).toList()),
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

Future<void> appendNotificationHistory(
  NotificationHistoryStore store,
  String scope,
  NotificationHistoryItem item,
) async {
  final existing = await store.read(scope);
  await store.write(
    scope,
    [
      item,
      ...existing.where((existingItem) => existingItem.id != item.id),
    ].take(30).toList(growable: false),
  );
}
