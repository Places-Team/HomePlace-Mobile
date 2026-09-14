import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract interface class NotificationService {
  Future<void> initialize();
  Future<bool> requestPermission();
  Future<bool> isAvailable();
  Future<void> show(String id, String title, String body);
}

final class LocalNotificationService implements NotificationService {
  LocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> initialize() => _plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

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
}
