import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/platform/android_system_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('homeplace.test/system');
  const actions = AndroidSystemActions(channel: channel);
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'maps Quick Settings tile results without claiming unsupported state',
    () async {
      for (final (native, expected) in [
        ('added', TransferTileResult.added),
        ('already_added', TransferTileResult.alreadyAdded),
        ('not_added', TransferTileResult.notAdded),
        ('unsupported', TransferTileResult.unavailable),
        ('unexpected', TransferTileResult.unavailable),
      ]) {
        messenger.setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'requestTransferTile');
          return native;
        });
        expect(await actions.requestTransferTile(), expected);
      }
    },
  );

  test('system channel failures remain non-blocking', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'unavailable');
    });
    expect(await actions.requestTransferTile(), TransferTileResult.unavailable);
    expect(await actions.openNotificationSettings(), isFalse);
  });

  test('opens the application notification settings page', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'openNotificationSettings');
      return true;
    });
    expect(await actions.openNotificationSettings(), isTrue);
  });
}
