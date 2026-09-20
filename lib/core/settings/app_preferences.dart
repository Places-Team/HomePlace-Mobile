import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { system, english, russian }

final class AppPreferences extends ChangeNotifier {
  AppLanguage language = AppLanguage.system;
  ThemeMode themeMode = ThemeMode.system;

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
}
