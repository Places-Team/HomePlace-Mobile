import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/storage/notification_history_store.dart';

void main() {
  test('notification history serializes bounded display content', () {
    final item = NotificationHistoryItem(
      id: 'event-1',
      title: 'HomePlace',
      body: 'The reminder is due.',
      receivedAt: DateTime.utc(2026, 9, 21, 12, 30),
    );

    final restored = NotificationHistoryItem.fromJson(item.toJson());

    expect(restored.id, 'event-1');
    expect(restored.title, 'HomePlace');
    expect(restored.body, 'The reminder is due.');
    expect(restored.receivedAt, DateTime.utc(2026, 9, 21, 12, 30));
  });

  test('notification history scope changes with server and credential', () {
    final first = notificationHistoryScope('server-1', 'credential-1');

    expect(first, isNot(notificationHistoryScope('server-2', 'credential-1')));
    expect(first, isNot(notificationHistoryScope('server-1', 'credential-2')));
    expect(first, hasLength(64));
  });
}
