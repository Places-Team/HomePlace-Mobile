import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

final class PreparedPlantPhoto {
  const PreparedPlantPhoto(this.bytes, this.mimeType);
  final Uint8List bytes;
  final String mimeType;
}

final class PlantPhotoPreparer {
  PlantPhotoPreparer({Future<Uint8List?> Function(String path)? convertToJpeg})
    : convertToJpeg = convertToJpeg ?? _convertToJpeg;

  final Future<Uint8List?> Function(String path) convertToJpeg;

  Future<PreparedPlantPhoto> prepare(
    File source, {
    required int maxBytes,
  }) async {
    if (maxBytes < 1 || maxBytes > 12 * 1024 * 1024) {
      throw const FormatException('Invalid plant photo limit.');
    }
    final extension = source.path.split('.').last.toLowerCase();
    final length = await source.length();
    if (length <= maxBytes &&
        ['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
      final bytes = await source.readAsBytes();
      final mime = switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        _ => 'image/webp',
      };
      if (!_matches(bytes, mime)) {
        throw const FormatException('Invalid plant photo.');
      }
      return PreparedPlantPhoto(bytes, mime);
    }
    final converted = await convertToJpeg(source.path);
    if (converted == null ||
        converted.length > maxBytes ||
        !_matches(converted, 'image/jpeg')) {
      throw const FormatException(
        'Plant photo could not be converted within the server limit.',
      );
    }
    return PreparedPlantPhoto(converted, 'image/jpeg');
  }

  static Future<Uint8List?> _convertToJpeg(String path) async {
    for (final quality in [82, 65, 45]) {
      final result = await FlutterImageCompress.compressWithFile(
        path,
        minWidth: 1600,
        minHeight: 1600,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      if (result != null && result.length <= 12 * 1024 * 1024) return result;
    }
    return null;
  }

  static bool _matches(Uint8List bytes, String mime) => switch (mime) {
    'image/jpeg' =>
      bytes.length >= 4 &&
          bytes[0] == 0xff &&
          bytes[1] == 0xd8 &&
          bytes[bytes.length - 2] == 0xff &&
          bytes.last == 0xd9,
    'image/png' =>
      bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4e &&
          bytes[3] == 0x47 &&
          bytes[4] == 0x0d &&
          bytes[5] == 0x0a &&
          bytes[6] == 0x1a &&
          bytes[7] == 0x0a,
    'image/webp' =>
      bytes.length >= 12 &&
          bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50,
    _ => false,
  };
}
