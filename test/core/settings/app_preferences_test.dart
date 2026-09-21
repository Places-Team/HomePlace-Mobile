import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/settings/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'enabling background offers persists consent and requests a check',
    () async {
      SharedPreferences.setMockInitialValues({'app.backgroundDelivery': true});
      bool? incomingEnabled;
      final preferences = AppPreferences(
        onBackgroundIncomingOffersChanged: (enabled) async {
          incomingEnabled = enabled;
        },
      );

      await preferences.initialize();
      await preferences.setBackgroundIncomingOffersEnabled(true);

      expect(preferences.backgroundIncomingOffersEnabled, isTrue);
      expect(incomingEnabled, isTrue);
      expect(
        (await SharedPreferences.getInstance()).getBool(
          AppPreferences.backgroundIncomingOffersKey,
        ),
        isTrue,
      );
    },
  );

  test('seamless own-account transfers are opt-in and persisted', () async {
    SharedPreferences.setMockInitialValues({});
    bool? enabled;
    final preferences = AppPreferences(
      onSeamlessOwnAccountTransfersChanged: (value) async {
        enabled = value;
      },
    );

    await preferences.initialize();
    expect(preferences.seamlessOwnAccountTransfersEnabled, isFalse);

    await preferences.setSeamlessOwnAccountTransfersEnabled(true);

    expect(enabled, isTrue);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        AppPreferences.seamlessOwnAccountTransfersKey,
      ),
      isTrue,
    );
  });
}
