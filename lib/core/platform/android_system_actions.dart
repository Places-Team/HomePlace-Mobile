import 'package:flutter/services.dart';

enum TransferTileResult { added, alreadyAdded, notAdded, unavailable }

final class AndroidSystemActions {
  const AndroidSystemActions({
    this.channel = const MethodChannel('com.homeplace.mobile/system'),
  });

  final MethodChannel channel;

  Future<TransferTileResult> requestTransferTile() async {
    try {
      final result = await channel.invokeMethod<String>('requestTransferTile');
      return switch (result) {
        'added' => TransferTileResult.added,
        'already_added' => TransferTileResult.alreadyAdded,
        'not_added' => TransferTileResult.notAdded,
        _ => TransferTileResult.unavailable,
      };
    } on PlatformException {
      return TransferTileResult.unavailable;
    } on MissingPluginException {
      return TransferTileResult.unavailable;
    }
  }

  Future<bool> openNotificationSettings() async {
    try {
      return await channel.invokeMethod<bool>('openNotificationSettings') ??
          false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
