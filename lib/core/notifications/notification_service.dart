import 'dart:io';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum IncomingNotificationActionKind { accept, decline }

final class IncomingNotificationAction {
  const IncomingNotificationAction({
    required this.serverId,
    required this.eventId,
    required this.kind,
  });

  final String serverId;
  final String eventId;
  final IncomingNotificationActionKind kind;
}

abstract interface class NotificationService {
  Future<void> initialize();
  Future<List<IncomingNotificationAction>> takeIncomingActions();
  Future<bool> requestPermission();
  Future<bool> isAvailable();
  Future<void> show(String id, String title, String body);
  Future<void> showIncomingOffer(
    String id,
    String serverId,
    String title,
    String body,
    String acceptLabel,
    String declineLabel,
  );
}

@pragma('vm:entry-point')
void homePlaceNotificationResponse(NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();
  await _IncomingNotificationActionStore.record(response);
}

final class _IncomingNotificationActionStore {
  static const _key = 'homeplace.incomingNotificationActions';

  static Future<void> record(NotificationResponse response) async {
    final kind = switch (response.actionId) {
      'accept_incoming' => IncomingNotificationActionKind.accept,
      'decline_incoming' => IncomingNotificationActionKind.decline,
      _ => null,
    };
    final parts = response.payload?.split('|') ?? const [];
    if (kind == null || parts.length != 3 || parts.first != 'incoming') return;
    final preferences = await SharedPreferences.getInstance();
    final entry = '${kind.name}|${parts[1]}|${parts[2]}';
    final current = preferences.getStringList(_key) ?? const [];
    final updated = [
      ...current.where((item) => item.split('|').last != parts[2]),
      entry,
    ];
    await preferences.setStringList(
      _key,
      updated.length <= 20 ? updated : updated.sublist(updated.length - 20),
    );
  }

  static Future<List<IncomingNotificationAction>> take() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_key) ?? const [];
    await preferences.remove(_key);
    return raw
        .expand((entry) {
          final parts = entry.split('|');
          if (parts.length != 3) return const <IncomingNotificationAction>[];
          final kind = IncomingNotificationActionKind.values
              .where((value) => value.name == parts[0])
              .firstOrNull;
          if (kind == null || parts[1].isEmpty || parts[2].isEmpty) {
            return const <IncomingNotificationAction>[];
          }
          return [
            IncomingNotificationAction(
              serverId: parts[1],
              eventId: parts[2],
              kind: kind,
            ),
          ];
        })
        .toList(growable: false);
  }
}

final class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize() async {
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: homePlaceNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: homePlaceNotificationResponse,
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    final response = launch?.notificationResponse;
    if (launch?.didNotificationLaunchApp == true && response != null) {
      await _IncomingNotificationActionStore.record(response);
    }
  }

  @override
  Future<List<IncomingNotificationAction>> takeIncomingActions() =>
      _IncomingNotificationActionStore.take();

  @override
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          true;
    }
    if (Platform.isIOS) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return false;
  }

  @override
  Future<bool> isAvailable() async {
    if (Platform.isAndroid) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          true;
    }
    return false;
  }

  @override
  Future<void> show(String id, String title, String body) => _plugin.show(
    id.hashCode & 0x7fffffff,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'homeplace_received',
        'Received from HomePlace',
        channelDescription: 'Notifications delivered by your HomePlace server',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    ),
  );

  @override
  Future<void> showIncomingOffer(
    String id,
    String serverId,
    String title,
    String body,
    String acceptLabel,
    String declineLabel,
  ) => _plugin.show(
    id.hashCode & 0x7fffffff,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        'homeplace_incoming',
        'Incoming HomePlace items',
        channelDescription:
            'Private text, link, clipboard and file offers awaiting review',
        importance: Importance.high,
        priority: Priority.high,
        visibility: NotificationVisibility.private,
        category: AndroidNotificationCategory.message,
        actions: [
          AndroidNotificationAction(
            'accept_incoming',
            acceptLabel,
            showsUserInterface: true,
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'decline_incoming',
            declineLabel,
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
    ),
    payload: 'incoming|$serverId|$id',
  );
}
