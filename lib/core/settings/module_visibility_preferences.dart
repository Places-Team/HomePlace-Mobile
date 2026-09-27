import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final class ModuleVisibilityPreferences extends ChangeNotifier {
  ModuleVisibilityPreferences(this.moduleIds);

  static const storageKey = 'home.modules.hidden.v1';

  final List<String> moduleIds;
  final Set<String> _hidden = {};
  bool _disposed = false;

  bool isVisible(String id) => !_hidden.contains(id);

  Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    if (_disposed) return;
    _hidden
      ..clear()
      ..addAll(
        (preferences.getStringList(storageKey) ?? const <String>[]).where(
          moduleIds.contains,
        ),
      );
    notifyListeners();
  }

  Future<void> setVisible(String id, bool visible) async {
    if (!moduleIds.contains(id)) return;
    final changed = visible ? _hidden.remove(id) : _hidden.add(id);
    if (!changed) return;
    notifyListeners();
    await _save();
  }

  Future<void> reset() async {
    if (_hidden.isEmpty) return;
    _hidden.clear();
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(storageKey, _hidden.toList()..sort());
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
