import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/sharing/share_service.dart';
import 'package:homeplace/features/exchange/device_file_selection.dart';

void main() {
  test('selected file is staged without changing the original', () async {
    final directory = await Directory.systemTemp.createTemp(
      'homeplace-pick-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final source = File('${directory.path}/original.jpg');
    await source.writeAsBytes([1, 2, 3, 4]);
    final stage = Directory('${directory.path}/stage');

    final selected = await stageDeviceFiles([
      PlatformFile(name: 'flower.jpg', size: 4, path: source.path),
    ], stage);

    expect(selected, hasLength(1));
    expect(selected.single.kind, SharedContentKind.file);
    expect(selected.single.filename, 'flower.jpg');
    expect(selected.single.mimeType, 'image/jpeg');
    expect(selected.single.path, isNot(source.path));
    expect(await File(selected.single.path!).readAsBytes(), [1, 2, 3, 4]);
    expect(await source.readAsBytes(), [1, 2, 3, 4]);
  });

  test('empty and oversized selections leave no staged files', () async {
    final directory = await Directory.systemTemp.createTemp(
      'homeplace-pick-test-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final source = File('${directory.path}/empty.bin');
    await source.create();
    final stage = Directory('${directory.path}/stage');

    await expectLater(
      stageDeviceFiles([
        PlatformFile(name: 'empty.bin', size: 0, path: source.path),
      ], stage),
      throwsA(isA<DeviceFileSelectionException>()),
    );
    expect(stage.existsSync(), isFalse);
  });

  test('batch size limit removes copies but preserves originals', () async {
    final directory = await Directory.systemTemp.createTemp('homeplace-batch-');
    addTearDown(() => directory.delete(recursive: true));
    final first = File('${directory.path}/first.bin')
      ..writeAsBytesSync([1, 2, 3, 4]);
    final second = File('${directory.path}/second.bin')
      ..writeAsBytesSync([5, 6, 7, 8]);
    final stage = Directory('${directory.path}/stage');
    await expectLater(
      stageDeviceFiles(
        [
          PlatformFile(name: 'first.bin', size: 4, path: first.path),
          PlatformFile(name: 'second.bin', size: 4, path: second.path),
        ],
        stage,
        maxTotalBytes: 7,
      ),
      throwsA(isA<DeviceFileSelectionException>()),
    );
    expect(await stage.list().toList(), isEmpty);
    expect(await first.readAsBytes(), [1, 2, 3, 4]);
    expect(await second.readAsBytes(), [5, 6, 7, 8]);
  });
}
