import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/design/home_atlas_theme.dart';

void main() {
  test('uses the Home Atlas light palette and offline font families', () {
    final theme = buildHomeAtlasTheme(Brightness.light);

    expect(theme.scaffoldBackgroundColor, const Color(0xfff6f2e8));
    expect(theme.colorScheme.onSurface, const Color(0xff1d2922));
    expect(theme.colorScheme.primary, const Color(0xff2e6048));
    expect(theme.textTheme.bodyMedium?.fontFamily, 'Onest');
    expect(theme.textTheme.displaySmall?.fontFamily, 'Literata');
  });

  test('keeps the dark palette distinct and readable', () {
    final light = buildHomeAtlasTheme(Brightness.light);
    final dark = buildHomeAtlasTheme(Brightness.dark);

    expect(dark.scaffoldBackgroundColor, const Color(0xff121a17));
    expect(dark.brightness, Brightness.dark);
    expect(dark.colorScheme.onSurface, const Color(0xffedf2eb));
    expect(dark.colorScheme.primary, const Color(0xffa8d3b7));
    expect(dark.scaffoldBackgroundColor, isNot(light.scaffoldBackgroundColor));
  });
}
