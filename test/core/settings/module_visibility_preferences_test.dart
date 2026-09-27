import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/settings/module_visibility_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('hidden sections persist without affecting the main tabs', () async {
    SharedPreferences.setMockInitialValues({});
    final visibility = ModuleVisibilityPreferences(['devices', 'security']);
    await visibility.initialize();
    expect(visibility.isVisible('devices'), isTrue);

    await visibility.setVisible('devices', false);
    expect(visibility.isVisible('devices'), isFalse);
    expect(visibility.isVisible('security'), isTrue);

    final restored = ModuleVisibilityPreferences(['devices', 'security']);
    await restored.initialize();
    expect(restored.isVisible('devices'), isFalse);
    await restored.reset();
    expect(restored.isVisible('devices'), isTrue);
    visibility.dispose();
    restored.dispose();
  });

  test('unknown section identifiers are ignored', () async {
    SharedPreferences.setMockInitialValues({});
    final visibility = ModuleVisibilityPreferences(['devices']);
    await visibility.initialize();
    await visibility.setVisible('transfers', false);
    expect(visibility.isVisible('devices'), isTrue);
    expect(
      (await SharedPreferences.getInstance()).getStringList(
        ModuleVisibilityPreferences.storageKey,
      ),
      isNull,
    );
    visibility.dispose();
  });
}
