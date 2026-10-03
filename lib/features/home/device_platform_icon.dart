import 'package:flutter/material.dart';

IconData devicePlatformIconData(String platform) {
  final value = platform.toLowerCase();
  if (value.contains('android')) return Icons.android_rounded;
  if (value.contains('mac') || value.contains('ios')) return Icons.apple;
  if (value.contains('win')) return Icons.desktop_windows_rounded;
  if (value.contains('linux')) return Icons.terminal_rounded;
  return Icons.devices_rounded;
}

final class DevicePlatformIcon extends StatelessWidget {
  const DevicePlatformIcon({required this.platform, super.key});

  final String platform;

  @override
  Widget build(BuildContext context) => Icon(devicePlatformIconData(platform));
}
