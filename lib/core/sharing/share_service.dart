import 'dart:io';

import 'package:flutter/services.dart';

import '../../link/link_client.dart';

enum SharedContentKind { text, url, file }

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
}

abstract interface class ShareService {
  bool get isSupported;
  Future<void> initialize(void Function(SharedContent content) onShare);
  Future<void> openUrl(String url);
  Future<String> createTemporaryFilePath();
  Future<void> saveFilePath(String path, String filename, String mimeType);
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
        final content = SharedContent.fromPlatform(call.arguments);
        if (content != null) onShare(content);
      }
    });
    final content = SharedContent.fromPlatform(
      await _channel.invokeMethod<Object?>('takePending'),
    );
    if (content != null) onShare(content);
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
  Future<void> saveFilePath(String path, String filename, String mimeType) =>
      _channel.invokeMethod<void>('saveFilePath', {
        'path': path,
        'filename': filename,
        'mimeType': mimeType,
      });
}
