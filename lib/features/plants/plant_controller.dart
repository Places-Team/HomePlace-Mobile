import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'plant_store.dart';

final class PlantController extends ChangeNotifier {
  PlantController(this.store);

  final PlantStore store;
  List<HomePlant> plants = const [];
  bool loading = true;
  String? error;
  bool _disposed = false;

  Future<void> load() async {
    try {
      plants = await store.readAll();
      error = null;
    } on Object {
      error = 'load';
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> save(HomePlant plant) async {
    await store.save(plant);
    await load();
  }

  Future<void> water(HomePlant plant, DateTime at) async {
    await save(plant.copyWith(lastWateredAt: at));
  }

  Future<void> delete(HomePlant plant) async {
    await store.delete(plant);
    await load();
  }

  Future<String> savePhoto(XFile picked) => store.savePhoto(picked);

  Future<void> removePhoto(String? name) => store.removePhoto(name);
}
