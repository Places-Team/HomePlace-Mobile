import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/notifications/notification_service.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android saves a received JPEG through MediaStore', (
    tester,
  ) async {
    if (!Platform.isAndroid) return;
    const channel = MethodChannel('com.homeplace.mobile/share');
    final path = await channel.invokeMethod<String>('createTemporaryFile');
    expect(path, isNotNull);
    final temporary = File(path!);
    await temporary.writeAsBytes(
      base64Decode(
        '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAP//////////////////////////////////////////////////////////////////////////////////////2wBDAf//////////////////////////////////////////////////////////////////////////////////////wAARCAABAAEDASIAAhEBAxEB/8QAFQABAQAAAAAAAAAAAAAAAAAAAAf/xAAUEAEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIQAxAAAAF//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABBQJ//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAwEBPwF//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAgEBPwF//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQAGPwJ//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPyF//9oADAMBAAIAAwAAABAf/8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAwEBPxB//8QAFBEBAAAAAAAAAAAAAAAAAAAAAP/aAAgBAgEBPxB//8QAFBABAAAAAAAAAAAAAAAAAAAAAP/aAAgBAQABPxB//9k=',
      ),
      flush: true,
    );

    final location = await channel.invokeMethod<String>('saveFilePath', {
      'path': temporary.path,
      'filename': 'homeplace-integration-test.jpg',
      'mimeType': 'image/jpeg',
    });

    expect(location, startsWith('content://'));
    expect(await temporary.length(), greaterThan(0));
    await temporary.delete();
  });

  testWidgets('Android posts private Accept and Decline actions', (
    tester,
  ) async {
    if (!Platform.isAndroid) return;
    final notifications = LocalNotificationService();
    await notifications.initialize();
    await notifications.showIncomingOffer(
      'integration-action-offer',
      '9d55059f-5a47-4f23-a778-5714c6744907',
      'New in HomePlace',
      'A file is waiting for your decision.',
      'Accept',
      'Decline',
    );
  });

  testWidgets('Android saves an arbitrary ZIP archive through MediaStore', (
    tester,
  ) async {
    if (!Platform.isAndroid) return;
    const channel = MethodChannel('com.homeplace.mobile/share');
    final path = await channel.invokeMethod<String>('createTemporaryFile');
    expect(path, isNotNull);
    final temporary = File(path!);
    await temporary.writeAsBytes(const [
      0x50,
      0x4b,
      0x05,
      0x06,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    ], flush: true);

    final location = await channel.invokeMethod<String>('saveFilePath', {
      'path': temporary.path,
      'filename': 'homeplace-integration-test.zip',
      'mimeType': 'application/zip',
    });

    expect(location, startsWith('content://'));
    expect(await temporary.length(), greaterThan(0));
    await temporary.delete();
  });
}
