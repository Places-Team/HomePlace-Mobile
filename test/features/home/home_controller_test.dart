import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/features/home/home_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('clipboard polling starts only while the app is foregrounded', () async {
    SharedPreferences.setMockInitialValues({'clipboard.autoSend': true});
    var reads = 0;
    final controller = HomeController(sessionProvider: () async => null);
    controller.setForeground(false);
    controller.bindClipboardReader(() async {
      reads += 1;
      return null;
    });
    await controller.initialize();
    expect(reads, 0);

    controller.setForeground(true);
    await pumpEventQueue();
    expect(reads, 1);
    controller.setForeground(false);
    controller.dispose();
  });

  test(
    'refresh always leaves the loading state when secure storage fails',
    () async {
      final controller = HomeController(
        sessionProvider: () => Future.error(const FormatException('corrupt')),
      );

      await controller.refresh(initial: true);

      expect(controller.loading, isFalse);
      expect(controller.refreshing, isFalse);
      expect(
        controller.error,
        'HomePlace could not refresh securely. Pull down to try again.',
      );
    },
  );
}
