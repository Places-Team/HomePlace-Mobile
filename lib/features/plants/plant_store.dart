import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/storage/connection_profile.dart';

final class HomePlant {
  const HomePlant({
    required this.id,
    required this.name,
    required this.species,
    required this.location,
    required this.intervalDays,
    required this.lastWateredAt,
    required this.createdAt,
    this.photoName,
    this.notes = '',
  });

  final String id;
  final String name;
  final String species;
  final String location;
  final int intervalDays;
  final DateTime lastWateredAt;
  final DateTime createdAt;
  final String? photoName;
  final String notes;

  DateTime get nextWateringAt => DateTime(
    lastWateredAt.year,
    lastWateredAt.month,
    lastWateredAt.day + intervalDays,
  );

  int daysUntilWatering(DateTime now) {
    final due = nextWateringAt;
    return DateTime.utc(
      due.year,
      due.month,
      due.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
  }

  HomePlant copyWith({
    String? name,
    String? species,
    String? location,
    int? intervalDays,
    DateTime? lastWateredAt,
    String? photoName,
    bool clearPhoto = false,
    String? notes,
  }) => HomePlant(
    id: id,
    name: name ?? this.name,
    species: species ?? this.species,
    location: location ?? this.location,
    intervalDays: intervalDays ?? this.intervalDays,
    lastWateredAt: lastWateredAt ?? this.lastWateredAt,
    createdAt: createdAt,
    photoName: clearPhoto ? null : photoName ?? this.photoName,
    notes: notes ?? this.notes,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'species': species,
    'location': location,
    'intervalDays': intervalDays,
    'lastWateredAt': lastWateredAt.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'photoName': photoName,
    'notes': notes,
  };

  static HomePlant? fromJson(Object? value) {
    if (value is! Map<String, dynamic>) return null;
    final id = value['id'];
    final name = value['name'];
    final interval = value['intervalDays'];
    final last = DateTime.tryParse(value['lastWateredAt']?.toString() ?? '');
    final created = DateTime.tryParse(value['createdAt']?.toString() ?? '');
    if (id is! String ||
        id.isEmpty ||
        name is! String ||
        name.isEmpty ||
        interval is! int ||
        interval < 1 ||
        interval > 90 ||
        last == null ||
        created == null) {
      return null;
    }
    return HomePlant(
      id: id,
      name: name,
      species: value['species'] is String ? value['species'] as String : '',
      location: value['location'] is String ? value['location'] as String : '',
      intervalDays: interval,
      lastWateredAt: last,
      createdAt: created,
      photoName: value['photoName'] is String
          ? value['photoName'] as String
          : null,
      notes: value['notes'] is String ? value['notes'] as String : '',
    );
  }
}

final class PlantStore {
  PlantStore(ConnectionProfile profile)
    : scope = sha256
          .convert(utf8.encode('${profile.serverId}:${profile.deviceId}'))
          .toString();

  final String scope;

  String get _key => 'homeplace.plants.v1.$scope';

  Future<List<HomePlant>> readAll() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_key);
    if (raw == null) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .map(HomePlant.fromJson)
          .whereType<HomePlant>()
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  Future<void> save(HomePlant plant) async {
    final plants = [...await readAll()]
      ..removeWhere((item) => item.id == plant.id)
      ..add(plant);
    await _write(plants);
  }

  Future<void> delete(HomePlant plant) async {
    final plants = [...await readAll()]
      ..removeWhere((item) => item.id == plant.id);
    await removePhoto(plant.photoName);
    await _write(plants);
  }

  Future<void> _write(List<HomePlant> plants) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _key,
      jsonEncode(plants.map((item) => item.toJson()).toList()),
    );
  }

  Future<Directory> _photoDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    return Directory('${root.path}/plants/$scope')..createSync(recursive: true);
  }

  Future<String> savePhoto(XFile picked) async {
    if (await picked.length() > 12 * 1024 * 1024) {
      throw const FileSystemException('Plant photo exceeds the size limit.');
    }
    final extension = picked.path.split('.').last.toLowerCase();
    final safeExtension = switch (extension) {
      'png' || 'webp' || 'heic' || 'heif' => extension,
      _ => 'jpg',
    };
    final name = '${DateTime.now().microsecondsSinceEpoch}.$safeExtension';
    final directory = await _photoDirectory();
    await picked.saveTo('${directory.path}/$name');
    return name;
  }

  Future<File?> photoFile(String? name) async {
    if (name == null ||
        !RegExp(r'^\d+\.(jpg|png|webp|heic|heif)$').hasMatch(name)) {
      return null;
    }
    final directory = await _photoDirectory();
    final file = File('${directory.path}/$name');
    return await file.exists() ? file : null;
  }

  Future<void> removePhoto(String? name) async {
    final file = await photoFile(name);
    if (file != null) await file.delete();
  }
}
