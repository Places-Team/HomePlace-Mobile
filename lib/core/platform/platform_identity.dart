import 'package:flutter/services.dart';

abstract interface class DeviceIdentity {
  Future<String> publicKey(String serverId);
}

final class PlatformDeviceIdentity implements DeviceIdentity {
  const PlatformDeviceIdentity();
  static const _channel = MethodChannel('com.homeplace.mobile/identity');

  @override
  Future<String> publicKey(String serverId) async {
    final key = await _channel.invokeMethod<String>('publicKey', {
      'serverId': serverId,
    });
    if (key == null || key.isEmpty) {
      throw StateError('Platform identity key is unavailable');
    }
    return key;
  }
}
