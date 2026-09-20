import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { system, english, russian }

final class AppPreferences extends ChangeNotifier {
  AppPreferences({this.onBackgroundDeliveryChanged});

  final Future<void> Function(bool enabled)? onBackgroundDeliveryChanged;
  AppLanguage language = AppLanguage.system;
  ThemeMode themeMode = ThemeMode.system;
  bool backgroundDeliveryEnabled = false;

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    language = AppLanguage.values.firstWhere(
      (item) => item.name == preferences.getString('app.language'),
      orElse: () => AppLanguage.system,
    );
    themeMode = ThemeMode.values.firstWhere(
      (item) => item.name == preferences.getString('app.theme'),
      orElse: () => ThemeMode.system,
    );
    backgroundDeliveryEnabled =
        preferences.getBool('app.backgroundDelivery') ?? false;
    if (backgroundDeliveryEnabled) {
      await onBackgroundDeliveryChanged?.call(true);
    }
    notifyListeners();
  }

  Locale? get locale => switch (language) {
    AppLanguage.system => null,
    AppLanguage.english => const Locale('en'),
    AppLanguage.russian => const Locale('ru'),
  };

  Future<void> setLanguage(AppLanguage value) async {
    if (language == value) return;
    language = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('app.language', value.name);
  }

  Future<void> setThemeMode(ThemeMode value) async {
    if (themeMode == value) return;
    themeMode = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('app.theme', value.name);
  }

  Future<void> setBackgroundDeliveryEnabled(bool value) async {
    if (backgroundDeliveryEnabled == value) return;
    backgroundDeliveryEnabled = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('app.backgroundDelivery', value);
    await onBackgroundDeliveryChanged?.call(value);
  }
}
