import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/features/plants/plant_photo_preparer.dart';

void main() {
  test('HEIC is converted without changing the source file', () async {
    final root = await Directory.systemTemp.createTemp('homeplace-prepare-');
    addTearDown(() => root.delete(recursive: true));
    final source = File('${root.path}/photo.heic');
    await source.writeAsBytes([1, 2, 3]);
    var conversions = 0;
    final preparer = PlantPhotoPreparer(
      convertToJpeg: (_) async {
        conversions++;
        return Uint8List.fromList([0xff, 0xd8, 0xff, 0xd9]);
      },
    );
    final result = await preparer.prepare(source, maxBytes: 12 * 1024 * 1024);
    expect(result.mimeType, 'image/jpeg');
    expect(result.bytes, [0xff, 0xd8, 0xff, 0xd9]);
    expect(await source.readAsBytes(), [1, 2, 3]);
    expect(conversions, 1);
  });

  test('invalid converter output is rejected before upload', () async {
    final root = await Directory.systemTemp.createTemp('homeplace-prepare-');
    addTearDown(() => root.delete(recursive: true));
    final source = File('${root.path}/photo.heif');
    await source.writeAsBytes([1, 2, 3]);
    final preparer = PlantPhotoPreparer(
      convertToJpeg: (_) async => Uint8List.fromList([1, 2]),
    );
    await expectLater(
      preparer.prepare(source, maxBytes: 12 * 1024 * 1024),
      throwsFormatException,
    );
  });
}
