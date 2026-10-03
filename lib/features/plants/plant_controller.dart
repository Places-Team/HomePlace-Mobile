import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'plant_store.dart';
import 'synced_plant_repository.dart';
import '../../link/plant_api.dart';

final class PlantController extends ChangeNotifier {
  PlantController(this.store, {this.repository});

  final PlantStore store;
  final SyncedPlantRepository? repository;
  List<HomePlant> plants = const [];
  bool loading = true;
  String? error;
  bool _disposed = false;

  bool get serverSynced => repository?.serverEnabled ?? false;
  int get pendingSyncCount => repository?.pendingCount ?? 0;
  int get localOnlyCount => repository?.localOnlyCount ?? 0;
  String? get syncError => repository?.syncError;
  bool get plantPhotosAvailable => repository?.plantPhotosAvailable ?? false;
  bool get plantRemindersAvailable =>
      repository?.plantRemindersAvailable ?? false;
  PlantNotificationSettings? get notificationSettings =>
      repository?.notificationSettings;
  Set<String> get conflicts => repository?.conflicts ?? const {};
  bool isSharedPlant(HomePlant plant) =>
      repository?.isSharedPlant(plant) ?? false;

  Future<void> load() async {
    try {
      if (repository case final synced?) {
        await synced.load();
        plants = synced.plants;
      } else {
        plants = await store.readAll();
      }
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
    if (repository case final synced?) {
      await synced.save(plant);
      plants = synced.plants;
    } else {
      await store.save(plant);
      plants = await store.readAll();
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> water(HomePlant plant, DateTime at) async {
    if (repository case final synced?) {
      await synced.water(plant, at);
      plants = synced.plants;
      if (!_disposed) notifyListeners();
    } else {
      await save(plant.copyWith(lastWateredAt: at));
    }
  }

  Future<void> delete(HomePlant plant) async {
    if (repository case final synced?) {
      await synced.delete(plant);
      plants = synced.plants;
    } else {
      await store.delete(plant);
      plants = await store.readAll();
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> sync() async {
    final synced = repository;
    if (synced == null) return;
    try {
      await synced.load();
      plants = synced.plants;
      error = null;
    } on Object {
      error = 'load';
    } finally {
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> importLocal({bool uploadPhotos = false}) async {
    final synced = repository;
    if (synced == null) return;
    await synced.importLocal(uploadPhotos: uploadPhotos);
    plants = synced.plants;
    if (!_disposed) notifyListeners();
  }

  Future<void> resolveConflict(String id, {required bool useServer}) async {
    final synced = repository;
    if (synced == null) return;
    await synced.resolveConflict(id, useServer: useServer);
    plants = synced.plants;
    if (!_disposed) notifyListeners();
  }

  Future<String> savePhoto(XFile picked) => store.savePhoto(picked);

  Future<void> removePhoto(String? name) => store.removePhoto(name);

  Future<File?> photoFile(HomePlant plant) =>
      repository?.photoFile(plant) ?? store.photoFile(plant.photoName);

  Future<void> updateNotificationSettings(
    PlantNotificationSettings settings,
  ) async {
    final synced = repository;
    if (synced == null) return;
    await synced.updateNotificationSettings(settings);
    if (!_disposed) notifyListeners();
  }
}
