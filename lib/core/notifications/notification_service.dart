import 'dart:io';
import 'dart:ui';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../background/background_tasks.dart';

enum IncomingNotificationActionKind { accept, decline }

bool incomingOfferActionOpensApp(String actionId, bool acceptInBackground) =>
    actionId == 'accept_incoming' && !acceptInBackground;

String? plantIdFromNotificationUrl(String? value) {
  final uri = Uri.tryParse(value ?? '');
  if (uri == null || uri.path != '/plants') return null;
  final id = uri.queryParameters['plant'];
  if (id == null ||
      !RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
      ).hasMatch(id)) {
    return null;
  }
  return id;
}

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
  Future<void> restoreIncomingActions(List<IncomingNotificationAction> actions);
  Future<String?> takePlantNavigation(String serverId);
  Future<bool> requestPermission();
  Future<bool> isAvailable();
  Future<void> show(
    String id,
    String title,
    String body, {
    bool urgent = false,
    String? plantId,
    String? serverId,
  });
  Future<void> showIncomingOffer(
    String id,
    String serverId,
    String title,
    String body,
    String acceptLabel,
    String declineLabel, {
    required bool acceptInBackground,
  });
}

@pragma('vm:entry-point')
void homePlaceNotificationResponse(NotificationResponse response) async {
  DartPluginRegistrant.ensureInitialized();
  await _PlantNavigationStore.record(response);
  final processInBackground = await _IncomingNotificationActionStore.record(
    response,
  );
  if (processInBackground) await scheduleIncomingActionProcessing();
}

final class _PlantNavigationStore {
  static const _key = 'homeplace.pendingPlantNavigation';

  static Future<void> record(NotificationResponse response) async {
    if (response.actionId != null && response.actionId!.isNotEmpty) return;
    final parts = response.payload?.split('|') ?? const [];
    if (parts.length != 3 ||
        parts[0] != 'plant' ||
        parts[1].isEmpty ||
        plantIdFromNotificationUrl('/plants?plant=${parts[2]}') == null) {
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_key, '${parts[1]}|${parts[2]}');
  }

  static Future<String?> take(String serverId) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return null;
    final parts = raw.split('|');
    if (parts.length != 2 || parts[0] != serverId) return null;
    await preferences.remove(_key);
    return parts[1];
  }
}

final class _IncomingNotificationActionStore {
  static const _key = 'homeplace.incomingNotificationActions';

  static Future<bool> record(NotificationResponse response) async {
    final kind = switch (response.actionId) {
      'accept_incoming' => IncomingNotificationActionKind.accept,
      'decline_incoming' => IncomingNotificationActionKind.decline,
      _ => null,
    };
    final parts = response.payload?.split('|') ?? const [];
    if (kind == null || parts.length != 4 || parts.first != 'incoming') {
      return false;
    }
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
    return kind == IncomingNotificationActionKind.decline ||
        parts[3] == 'background';
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

  static Future<void> restore(List<IncomingNotificationAction> actions) async {
    if (actions.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    final current = preferences.getStringList(_key) ?? const [];
    final restored = [
      ...current.where(
        (entry) =>
            !actions.any((action) => entry.split('|').last == action.eventId),
      ),
      ...actions.map(
        (action) => '${action.kind.name}|${action.serverId}|${action.eventId}',
      ),
    ];
    await preferences.setStringList(
      _key,
      restored.length <= 20 ? restored : restored.sublist(restored.length - 20),
    );
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
      await _PlantNavigationStore.record(response);
    }
  }

  @override
  Future<List<IncomingNotificationAction>> takeIncomingActions() =>
      _IncomingNotificationActionStore.take();

  @override
  Future<String?> takePlantNavigation(String serverId) =>
      _PlantNavigationStore.take(serverId);

  @override
  Future<void> restoreIncomingActions(
    List<IncomingNotificationAction> actions,
  ) => _IncomingNotificationActionStore.restore(actions);

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
          false;
    }
    if (Platform.isIOS) {
      final permissions = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      return permissions?.isEnabled == true ||
          permissions?.isProvisionalEnabled == true;
    }
    return false;
  }

  @override
  Future<void> show(
    String id,
    String title,
    String body, {
    bool urgent = false,
    String? plantId,
    String? serverId,
  }) => _plugin.show(
    id.hashCode & 0x7fffffff,
    title,
    body,
    NotificationDetails(
      android: AndroidNotificationDetails(
        urgent ? 'homeplace_alerts' : 'homeplace_received',
        urgent ? 'HomePlace alerts' : 'Received from HomePlace',
        channelDescription: urgent
            ? 'Urgent incidents from your HomePlace server'
            : 'Notifications delivered by your HomePlace server',
        importance: urgent ? Importance.high : Importance.defaultImportance,
        priority: urgent ? Priority.high : Priority.defaultPriority,
        visibility: NotificationVisibility.private,
        category: AndroidNotificationCategory.message,
      ),
      iOS: const DarwinNotificationDetails(),
    ),
    payload: plantId != null && serverId != null
        ? 'plant|$serverId|$plantId'
        : null,
  );

  @override
  Future<void> showIncomingOffer(
    String id,
    String serverId,
    String title,
    String body,
    String acceptLabel,
    String declineLabel, {
    required bool acceptInBackground,
  }) => _plugin.show(
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
            showsUserInterface: incomingOfferActionOpensApp(
              'accept_incoming',
              acceptInBackground,
            ),
            cancelNotification: true,
          ),
          AndroidNotificationAction(
            'decline_incoming',
            declineLabel,
            showsUserInterface: incomingOfferActionOpensApp(
              'decline_incoming',
              acceptInBackground,
            ),
            cancelNotification: true,
          ),
        ],
      ),
    ),
    payload:
        'incoming|$serverId|$id|${acceptInBackground ? 'background' : 'foreground'}',
  );
}
