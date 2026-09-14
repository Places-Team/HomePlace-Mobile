import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/main.dart';

import 'features/connection/test_doubles.dart';

void main() {
  testWidgets('shows HomePlace onboarding', (tester) async {
    final controller = ConnectionController(
      linkService: FakeLinkService(),
      profileStore: MemoryProfileStore(),
      credentialStore: MemoryCredentialStore(),
      deviceIdentity: const FakeDeviceIdentity(),
      notificationService: FakeNotificationService(),
      descriptionProvider: const FakeDescriptionProvider(),
    );

    await tester.pumpWidget(HomePlaceApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Your HomePlace, on your phone'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
  });
}
