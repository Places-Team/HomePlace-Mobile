import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/features/home/device_platform_icon.dart';

void main() {
  for (final (platform, icon) in <(String, IconData)>[
    ('macos', Icons.apple),
    ('ios', Icons.apple),
    ('android', Icons.android_rounded),
    ('windows', Icons.desktop_windows_rounded),
    ('linux', Icons.terminal_rounded),
    ('unknown', Icons.devices_rounded),
  ]) {
    testWidgets('shows the $platform device symbol', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: DevicePlatformIcon(platform: platform)),
        ),
      );

      expect(find.byIcon(icon), findsOneWidget);
    });
  }
}
