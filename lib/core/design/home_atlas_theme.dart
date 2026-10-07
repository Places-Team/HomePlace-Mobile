import 'package:flutter/material.dart';

abstract final class HomeAtlasColors {
  static const lightCanvas = Color(0xfff6f2e8);
  static const lightPaper = Color(0xfffffcf5);
  static const lightInk = Color(0xff1d2922);
  static const lightQuietInk = Color(0xff57665b);
  static const lightEvergreen = Color(0xff2e6048);
  static const lightClay = Color(0xffa64f35);

  static const darkCanvas = Color(0xff121a17);
  static const darkPaper = Color(0xff1c2822);
  static const darkInk = Color(0xffedf2eb);
  static const darkQuietInk = Color(0xffb5c4b8);
  static const darkEvergreen = Color(0xffa8d3b7);
  static const darkClay = Color(0xfff0a58c);
}

ThemeData buildHomeAtlasTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final canvas = dark
      ? HomeAtlasColors.darkCanvas
      : HomeAtlasColors.lightCanvas;
  final paper = dark ? HomeAtlasColors.darkPaper : HomeAtlasColors.lightPaper;
  final ink = dark ? HomeAtlasColors.darkInk : HomeAtlasColors.lightInk;
  final quietInk = dark
      ? HomeAtlasColors.darkQuietInk
      : HomeAtlasColors.lightQuietInk;
  final evergreen = dark
      ? HomeAtlasColors.darkEvergreen
      : HomeAtlasColors.lightEvergreen;
  final clay = dark ? HomeAtlasColors.darkClay : HomeAtlasColors.lightClay;

  final scheme =
      ColorScheme.fromSeed(
        seedColor: evergreen,
        brightness: brightness,
      ).copyWith(
        primary: evergreen,
        onPrimary: dark
            ? HomeAtlasColors.darkCanvas
            : HomeAtlasColors.lightPaper,
        surface: paper,
        onSurface: ink,
        surfaceContainerLow: canvas,
        surfaceContainerHighest: dark
            ? const Color(0xff293830)
            : const Color(0xffeae6db),
        onSurfaceVariant: quietInk,
        error: clay,
        outline: dark ? const Color(0xff688071) : const Color(0xff8a998d),
        outlineVariant: dark
            ? const Color(0xff39483d)
            : const Color(0xffd6ddd2),
      );

  final baseText = ThemeData(
    brightness: brightness,
    useMaterial3: true,
  ).textTheme.apply(fontFamily: 'Onest', bodyColor: ink, displayColor: ink);
  final textTheme = baseText.copyWith(
    displaySmall: baseText.displaySmall?.copyWith(
      fontFamily: 'Literata',
      fontWeight: FontWeight.w600,
      letterSpacing: -1.1,
      height: 1.08,
    ),
    headlineMedium: baseText.headlineMedium?.copyWith(
      fontFamily: 'Literata',
      fontWeight: FontWeight.w600,
      letterSpacing: -0.7,
      height: 1.1,
    ),
    headlineSmall: baseText.headlineSmall?.copyWith(
      fontFamily: 'Literata',
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
    ),
    titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w700),
  );

  return ThemeData(
    brightness: brightness,
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Onest',
    textTheme: textTheme,
    scaffoldBackgroundColor: canvas,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      scrolledUnderElevation: 0,
      backgroundColor: canvas,
      foregroundColor: ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: paper,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 0,
    ),
  );
}
