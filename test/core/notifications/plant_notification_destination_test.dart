import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/notifications/notification_service.dart';

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
    expect(plantIdFromNotificationUrl('/plants'), isNull);
  });
}
