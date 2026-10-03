import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

final class PlantPhotoCache {
  PlantPhotoCache({Future<Directory> Function()? rootProvider})
    : rootProvider = rootProvider ?? getApplicationDocumentsDirectory;

  final Future<Directory> Function() rootProvider;

  static final _id = RegExp(r'^[0-9a-fA-F-]{36}$');
  static final _version = RegExp(r'^[0-9a-fA-F-]{36}\.(jpg|png|webp)$');
  static final _scope = RegExp(r'^[a-zA-Z0-9_-]{1,80}$');

  Future<Directory> _directory(String scope) async {
    if (!_scope.hasMatch(scope)) {
      throw const FormatException('Invalid plant photo scope.');
    }
    final root = await rootProvider();
    return Directory('${root.path}/plants/remote/$scope');
  }

  Future<File?> read(String scope, String clientId, String version) async {
    if (!_id.hasMatch(clientId) || !_version.hasMatch(version)) return null;
    final file = File('${(await _directory(scope)).path}/$clientId-$version');
    return await file.exists() ? file : null;
  }

  Future<File> write(
    String scope,
    String clientId,
    String version,
    Uint8List bytes,
  ) async {
    if (!_id.hasMatch(clientId) ||
        !_version.hasMatch(version) ||
        bytes.isEmpty ||
        bytes.length > 12 * 1024 * 1024 ||
        !version.endsWith('.${_extension(bytes)}')) {
      throw const FormatException('Invalid plant photo.');
    }
    final directory = await _directory(scope);
    await directory.create(recursive: true);
    final target = File('${directory.path}/$clientId-$version');
    final temporary = File(
      '${target.path}.${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(target.path);
    } finally {
      if (await temporary.exists()) await temporary.delete();
    }
    await _removeOtherVersions(directory, clientId, keep: target.path);
    return target;
  }

  Future<void> remove(String scope, String clientId) async {
    if (!_id.hasMatch(clientId)) return;
    final directory = await _directory(scope);
    if (!await directory.exists()) return;
    await _removeOtherVersions(directory, clientId);
  }

  Future<void> _removeOtherVersions(
    Directory directory,
    String clientId, {
    String? keep,
  }) async {
    final pattern = RegExp(
      '^${RegExp.escape(clientId)}-[0-9a-fA-F-]{36}\\.(jpg|png|webp)\$',
    );
    await for (final entry in directory.list(followLinks: false)) {
      if (entry is File &&
          entry.path != keep &&
          pattern.hasMatch(entry.uri.pathSegments.last)) {
        await entry.delete();
      }
    }
  }

  String _extension(Uint8List bytes) {
    if (bytes.length >= 4 && bytes[0] == 0xff && bytes[1] == 0xd8) {
      return 'jpg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) {
      return 'webp';
    }
    throw const FormatException('Unsupported plant photo format.');
  }
}
