import 'dart:io';

import 'package:flutter/services.dart';

import '../../link/link_client.dart';

enum SharedContentKind { text, url, file }

final class SavedSharedFile {
  const SavedSharedFile({
    required this.location,
    required this.filename,
    required this.mimeType,
  });

  final String location;
  final String filename;
  final String mimeType;
}

final class SharedContent {
  const SharedContent({
    required this.kind,
    this.value,
    this.path,
    this.filename,
    this.mimeType,
    this.size,
  });

  final SharedContentKind kind;
  final String? value;
  final String? path;
  final String? filename;
  final String? mimeType;
  final int? size;

  static SharedContent? fromPlatform(Object? raw) {
    if (raw is! Map) return null;
    final map = Map<String, Object?>.from(raw);
    switch (map['type']) {
      case 'text':
        final value = map['value'];
        return value is String &&
                value.trim().isNotEmpty &&
                value.length <= 8000
            ? SharedContent(kind: SharedContentKind.text, value: value.trim())
            : null;
      case 'url':
        final rawValue = map['value'];
        if (rawValue is! String) return null;
        final uri = Uri.tryParse(rawValue);
        return uri != null &&
                (uri.scheme == 'http' || uri.scheme == 'https') &&
                uri.userInfo.isEmpty &&
                rawValue.length <= 4096
            ? SharedContent(kind: SharedContentKind.url, value: rawValue)
            : null;
      case 'file':
        final path = map['path'];
        final filename = map['filename'];
        final size = map['size'];
        if (path is! String ||
            filename is! String ||
            size is! int ||
            size < 1 ||
            size > maxShareFileBytes) {
          return null;
        }
        return SharedContent(
          kind: SharedContentKind.file,
          path: path,
          filename: filename,
          mimeType: map['mimeType'] as String? ?? 'application/octet-stream',
          size: size,
        );
      default:
        return null;
    }
  }

  static List<SharedContent> listFromPlatform(Object? raw) {
    final values = raw is List ? raw : [raw];
    final seen = <String>{};
    return values
        .expand((value) {
          final content = fromPlatform(value);
          if (content == null) return const <SharedContent>[];
          final identity = switch (content.kind) {
            SharedContentKind.file =>
              'file:${content.path}:${content.filename}:${content.size}',
            SharedContentKind.url => 'url:${content.value}',
            SharedContentKind.text => 'text:${content.value}',
          };
          return seen.add(identity) ? [content] : const <SharedContent>[];
        })
        .toList(growable: false);
  }
}

abstract interface class ShareService {
  bool get isSupported;
  Future<void> initialize(void Function(SharedContent content) onShare);
  Future<void> openUrl(String url);
  Future<String> createTemporaryFilePath();
  Future<SavedSharedFile> saveFilePath(
    String path,
    String filename,
    String mimeType,
  );
  Future<void> openSavedFile(SavedSharedFile file);
}

final class PlatformShareService implements ShareService {
  const PlatformShareService();
  static const _channel = MethodChannel('com.homeplace.mobile/share');

  @override
  bool get isSupported => Platform.isAndroid;

  @override
  Future<void> initialize(void Function(SharedContent content) onShare) async {
    if (!isSupported) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'shareReceived') {
        for (final content in SharedContent.listFromPlatform(call.arguments)) {
          onShare(content);
        }
      }
    });
    final pending = await _channel.invokeMethod<Object?>('takePending');
    for (final content in SharedContent.listFromPlatform(pending)) {
      onShare(content);
    }
  }

  @override
  Future<void> openUrl(String url) =>
      _channel.invokeMethod<void>('openUrl', {'url': url});

  @override
  Future<String> createTemporaryFilePath() async {
    final path = await _channel.invokeMethod<String>('createTemporaryFile');
    if (path == null || path.isEmpty) {
      throw PlatformException(
        code: 'temporary_file_unavailable',
        message: 'A protected temporary file could not be created.',
      );
    }
    return path;
  }

  @override
  Future<SavedSharedFile> saveFilePath(
    String path,
    String filename,
    String mimeType,
  ) async {
    final location = await _channel.invokeMethod<String>('saveFilePath', {
      'path': path,
      'filename': filename,
      'mimeType': mimeType,
    });
    if (location == null || location.isEmpty) {
      throw PlatformException(
        code: 'save_failed',
        message: 'The saved file location is unavailable.',
      );
    }
    return SavedSharedFile(
      location: location,
      filename: filename,
      mimeType: mimeType,
    );
  }

  @override
  Future<void> openSavedFile(SavedSharedFile file) =>
      _channel.invokeMethod<void>('openSavedFile', {
        'location': file.location,
        'mimeType': file.mimeType,
      });
}
