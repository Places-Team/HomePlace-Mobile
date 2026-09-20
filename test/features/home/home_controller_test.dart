import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/features/home/home_controller.dart';

void main() {
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
