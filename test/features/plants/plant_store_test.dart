import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/storage/connection_profile.dart';
import 'package:homeplace/features/plants/plant_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const firstProfile = ConnectionProfile(
    serverId: 'server-1',
    serverName: 'Home',
    preferredUrl: 'https://home.example.test',
    deviceId: 'device-1',
    secure: true,
  );

  test('calculates due dates for flexible day intervals', () {
    final plant = HomePlant(
      id: '1',
      name: 'Fern',
      species: 'Boston fern',
      location: 'Kitchen',
      intervalDays: 3,
      lastWateredAt: DateTime(2026, 9, 21, 18),
      createdAt: DateTime(2026, 9, 20),
    );
    expect(plant.nextWateringAt, DateTime(2026, 9, 24));
    expect(plant.daysUntilWatering(DateTime(2026, 9, 23, 23)), 1);
    expect(plant.daysUntilWatering(DateTime(2026, 9, 24)), 0);
    expect(plant.daysUntilWatering(DateTime(2026, 9, 26)), -2);
  });

  test('keeps plant cards separate for each device connection', () async {
    SharedPreferences.setMockInitialValues({});
    final first = PlantStore(firstProfile);
    final second = PlantStore(
      const ConnectionProfile(
        serverId: 'server-1',
        serverName: 'Another account',
        preferredUrl: 'https://home.example.test',
        deviceId: 'device-2',
        secure: true,
      ),
    );
    final plant = HomePlant(
      id: '1',
      name: 'Orchid',
      species: '',
      location: '',
      intervalDays: 14,
      lastWateredAt: DateTime(2026, 9, 20),
      createdAt: DateTime(2026, 9, 20),
    );
    await first.save(plant);
    expect((await first.readAll()).single.name, 'Orchid');
    expect(await second.readAll(), isEmpty);
  });
}
