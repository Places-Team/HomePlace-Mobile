import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/sharing/share_service.dart';
import '../../link/link_client.dart';

final class DeviceFileSelectionException implements Exception {
  const DeviceFileSelectionException();
}

Future<List<SharedContent>> pickDeviceFiles({bool photosOnly = false}) async {
  final selection = await FilePicker.platform.pickFiles(
    type: photosOnly ? FileType.image : FileType.any,
    allowMultiple: true,
    withData: false,
  );
  if (selection == null) return const [];
  final cache = await getTemporaryDirectory();
  return stageDeviceFiles(
    selection.files,
    Directory('${cache.path}/homeplace-outgoing'),
  );
}

Future<List<SharedContent>> stageDeviceFiles(
  List<PlatformFile> files,
  Directory stagingDirectory, {
  int maxTotalBytes = maxShareFileBytes,
}) async {
  if (files.isEmpty) return const [];
  if (files.length > 10) throw const DeviceFileSelectionException();

  final copied = <File>[];
  final staged = <SharedContent>[];
  var totalBytes = 0;
  try {
    for (final picked in files) {
      final sourcePath = picked.path;
      final name = picked.name
          .replaceAll(RegExp(r'[\\/\x00-\x1f\x7f]'), '_')
          .trim();
      if (sourcePath == null || sourcePath.isEmpty || name.isEmpty) {
        throw const DeviceFileSelectionException();
      }
      final source = File(sourcePath);
      final size = await source.length();
      if (size < 1 || size > maxShareFileBytes) {
        throw const DeviceFileSelectionException();
      }
      totalBytes += size;
      if (totalBytes > maxTotalBytes) {
        throw const DeviceFileSelectionException();
      }
      if (!await stagingDirectory.exists()) {
        await stagingDirectory.create(recursive: true);
      }
      final random = Random.secure();
      final suffix = List.generate(
        16,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      final target = await File('${stagingDirectory.path}/outgoing-$suffix')
          .create(exclusive: true);
      copied.add(target);
      await source.openRead().pipe(target.openWrite());
      if (await target.length() != size) {
        throw const DeviceFileSelectionException();
      }
      staged.add(
        SharedContent(
          kind: SharedContentKind.file,
          path: target.path,
          filename: name.length > 180 ? name.substring(0, 180) : name,
          mimeType: lookupMimeType(name) ?? 'application/octet-stream',
          size: size,
        ),
      );
    }
    return staged;
  } on Object {
    for (final file in copied) {
      if (await file.exists()) await file.delete();
    }
    rethrow;
  }
}
