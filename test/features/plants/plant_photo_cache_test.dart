import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/features/plants/plant_photo_cache.dart';

void main() {
  test(
    'private photo cache isolates accounts and replaces old versions',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'homeplace-photo-cache-',
      );
      addTearDown(() => root.delete(recursive: true));
      final cache = PlantPhotoCache(rootProvider: () async => root);
      const id = 'e54f9bfa-2543-4be2-bc07-c1eb3d0947ee';
      final first = Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);
      const firstVersion = '01234567-89ab-4cde-8f12-0123456789ab.jpg';
      const secondVersion = '11234567-89ab-4cde-8f12-0123456789ab.jpg';
      await cache.write('account-a', id, firstVersion, first);
      expect(
        await (await cache.read('account-a', id, firstVersion))!.readAsBytes(),
        first,
      );
      expect(await cache.read('account-b', id, firstVersion), isNull);
      await cache.write('account-a', id, secondVersion, first);
      expect(await cache.read('account-a', id, firstVersion), isNull);
      expect(await cache.read('account-a', id, secondVersion), isNotNull);
      await cache.remove('account-a', id);
      expect(await cache.read('account-a', id, secondVersion), isNull);
    },
  );
}
