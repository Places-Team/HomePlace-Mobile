import 'dart:io';

import 'package:flutter/services.dart';

abstract interface class ClipboardService {
  bool get isSupported;
  Future<String?> readText();
  Future<void> writeText(String text);
}

final class PlatformClipboardService implements ClipboardService {
  const PlatformClipboardService();
  static const _channel = MethodChannel('com.homeplace.mobile/clipboard');

  @override
  bool get isSupported => Platform.isAndroid;

  @override
  Future<String?> readText() => _channel.invokeMethod<String>('readText');

  @override
  Future<void> writeText(String text) =>
      _channel.invokeMethod<void>('writeText', {'text': text});
}
