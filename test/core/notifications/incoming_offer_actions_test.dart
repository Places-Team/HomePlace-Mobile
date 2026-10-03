import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/notifications/notification_service.dart';

void main() {
  test('file offer can be accepted or declined without opening the app', () {
    expect(incomingOfferActionOpensApp('accept_incoming', true), isFalse);
    expect(incomingOfferActionOpensApp('decline_incoming', true), isFalse);
  });

  test('text and link acceptance still opens app for explicit review', () {
    expect(incomingOfferActionOpensApp('accept_incoming', false), isTrue);
    expect(incomingOfferActionOpensApp('decline_incoming', false), isFalse);
  });
}
