import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/link/models.dart';
import 'package:homeplace/link/plant_api.dart';
import 'package:homeplace/features/plants/synced_plant_repository.dart';

void main() {
  test('discovery advertises plant photos and reminders only when present', () {
    final info = ServerInfo.fromJson({
      'product': 'HomePlace',
      'server': {'id': 'e54f9bfa-2543-4be2-bc07-c1eb3d0947ee', 'name': 'Test'},
      'protocol': {'min': 1, 'max': 1},
      'serverTime': '2026-10-03T00:00:00Z',
      'features': {
        'pairing': true,
        'realtime': false,
        'plants': true,
        'plantPhotos': true,
        'plantReminders': true,
      },
      'limits': {'maxPlantPhotoBytes': 12582912},
    });
    expect(info.features.plantPhotos, isTrue);
    expect(info.features.plantReminders, isTrue);
    expect(info.maxPlantPhotoBytes, 12582912);
  });

  test('plant snapshot retains reminder choice and private photo version', () {
    final remote = RemotePlant.fromJson({
      'clientId': 'e54f9bfa-2543-4be2-bc07-c1eb3d0947ee',
      'name': 'Fern',
      'species': '',
      'location': '',
      'notes': '',
      'intervalDays': 7,
      'lastWateredAt': '2026-10-01T00:00:00Z',
      'createdAt': '2026-10-01T00:00:00Z',
      'revision': 3,
      'deletedAt': null,
      'remindersEnabled': false,
      'photo': {
        'url': '/api/link/plants/e54f9bfa-2543-4be2-bc07-c1eb3d0947ee/photo',
        'version': '01234567-89ab-4cde-8f12-0123456789ab.jpg',
        'maxBytes': 12582912,
      },
    });
    expect(remote.plant.remindersEnabled, isFalse);
    expect(remote.photo!.version, '01234567-89ab-4cde-8f12-0123456789ab.jpg');
    expect(
      RemotePlant.fromJson(remote.toJson()).photo!.version,
      remote.photo!.version,
    );
  });

  test('notification settings reject invalid times and repeat ranges', () {
    expect(
      () => PlantNotificationSettings.fromJson({
        'enabled': true,
        'app': true,
        'telegram': false,
        'time': '25:00',
        'timeZone': 'Europe/Moscow',
        'repeatDays': 1,
      }),
      throwsFormatException,
    );
    expect(
      () => PlantNotificationSettings.fromJson({
        'enabled': true,
        'app': true,
        'telegram': false,
        'time': '09:00',
        'timeZone': 'Europe/Moscow',
        'repeatDays': 31,
      }),
      throwsFormatException,
    );
  });

  test(
    'photo queue survives secure snapshot restoration without leaking paths',
    () {
      final snapshot = PlantSyncSnapshot(
        pendingPhotos: [
          PendingPlantPhoto(
            clientId: 'e54f9bfa-2543-4be2-bc07-c1eb3d0947ee',
            sourceName: '123.jpg',
            baseVersion: null,
          ),
        ],
      );
      final restored = PlantSyncSnapshot.fromJson(
        jsonDecode(jsonEncode(snapshot.toJson())),
      );
      expect(restored.pendingPhotos.single.sourceName, '123.jpg');
      expect(restored.toJson().toString(), isNot(contains('/Users/')));
      expect(
        PlantSyncSnapshot.fromJson(
          jsonDecode(
            jsonEncode({
              'version': 1,
              'remote': [],
              'pending': [],
              'migrated': {},
            }),
          ),
        ).pendingPhotos,
        isEmpty,
      );
    },
  );

  test('offline watering stays a dedicated revisioned operation', () {
    final plant = RemotePlant.fromJson({
      'clientId': 'e54f9bfa-2543-4be2-bc07-c1eb3d0947ee',
      'name': 'Fern',
      'species': '',
      'location': '',
      'notes': '',
      'intervalDays': 7,
      'lastWateredAt': '2026-10-01T00:00:00Z',
      'createdAt': '2026-10-01T00:00:00Z',
      'revision': 4,
      'deletedAt': null,
    }).plant;
    final change = PendingPlantChange(
      action: 'water',
      plant: plant,
      revision: 4,
    );
    expect(
      PendingPlantChange.fromJson(jsonDecode(jsonEncode(change.toJson())))
          .action,
      'water',
    );
  });

  test('account notification settings remain in the protected snapshot', () {
    const settings = PlantNotificationSettings(
      enabled: true,
      app: true,
      telegram: false,
      time: '08:30',
      timeZone: 'Europe/Moscow',
      repeatDays: 2,
    );
    final snapshot = PlantSyncSnapshot(settings: settings);
    final restored = PlantSyncSnapshot.fromJson(
      jsonDecode(jsonEncode(snapshot.toJson())),
    );
    expect(restored.settings!.time, '08:30');
    expect(restored.settings!.telegram, isFalse);
  });
}
