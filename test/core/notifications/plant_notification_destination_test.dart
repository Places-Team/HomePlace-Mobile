import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/notifications/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('plant notification URL selects only a valid internal plant', () {
    const id = 'e54f9bfa-2543-4be2-bc07-c1eb3d0947ee';
    expect(plantIdFromNotificationUrl('/plants?plant=$id'), id);
    expect(
      plantIdFromNotificationUrl('https://home.example/plants?plant=$id'),
      id,
    );
    expect(
      plantIdFromNotificationUrl('https://other.example/admin?plant=$id'),
      isNull,
    );
    expect(
      plantIdFromNotificationUrl('/plants?plant=../../etc/passwd'),
      isNull,
    );
    expect(plantIdFromNotificationUrl('/plants'), isEmpty);
    expect(plantIdFromNotificationUrl('/plants?other=value'), isNull);
    expect(plantIdFromNotificationUrl('/plants?plant='), isNull);
  });

  test('same watering tag replaces its notification for one server', () {
    const tag =
        'plant-care-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
    const otherTag =
        'plant-care-bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
    final first = notificationIdForEvent(
      'event-1',
      serverId: 'server-1',
      tag: tag,
    );
    expect(
      notificationIdForEvent('event-2', serverId: 'server-1', tag: tag),
      first,
    );
    expect(
      notificationIdForEvent('event-2', serverId: 'server-2', tag: tag),
      isNot(first),
    );
    expect(
      notificationIdForEvent('event-2', serverId: 'server-1', tag: otherTag),
      isNot(first),
    );
    expect(notificationIdForEvent('event-1'), 'event-1'.hashCode & 0x7fffffff);
    expect(
      notificationIdForEvent('event-1', serverId: 'server-1', tag: 'other'),
      'event-1'.hashCode & 0x7fffffff,
    );
  });

  test('tapping a grouped digest opens the list only for its server', () async {
    SharedPreferences.setMockInitialValues({});
    homePlaceNotificationResponse(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'plant|server-1|',
      ),
    );
    await pumpEventQueue();

    final notifications = LocalNotificationService();
    expect(await notifications.takePlantNavigation('server-2'), isNull);
    expect(await notifications.takePlantNavigation('server-1'), isEmpty);
    expect(await notifications.takePlantNavigation('server-1'), isNull);
  });

  test('legacy plant notification still opens its specific plant', () async {
    SharedPreferences.setMockInitialValues({});
    const id = 'e54f9bfa-2543-4be2-bc07-c1eb3d0947ee';
    homePlaceNotificationResponse(
      const NotificationResponse(
        notificationResponseType: NotificationResponseType.selectedNotification,
        payload: 'plant|server-1|$id',
      ),
    );
    await pumpEventQueue();

    expect(
      await LocalNotificationService().takePlantNavigation('server-1'),
      id,
    );
  });
}
