import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/link/models.dart';

void main() {
  test('parses the canonical Link info fixture', () {
    final json = jsonDecode(
      File('docs/fixtures/link-info-v1.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    final info = ServerInfo.fromJson(json);

    expect(info.product, 'HomePlace');
    expect(info.server.name, 'Test Home');
    expect(info.supportsClient, isTrue);
  });

  test('rejects unsupported protocol versions', () {
    final info = ServerInfo.fromJson({
      'product': 'HomePlace',
      'server': {
        'id': '9d55059f-5a47-4f23-a778-5714c6744907',
        'name': 'Test Home',
      },
      'protocol': {'min': 2, 'max': 3},
      'serverTime': '2026-09-13T12:00:00Z',
      'features': {'pairing': true, 'realtime': true},
    });

    expect(info.supportsClient, isFalse);
  });

  test('detects a server identity change', () {
    final info = ServerInfo.fromJson({
      'product': 'HomePlace',
      'server': {
        'id': '9d55059f-5a47-4f23-a778-5714c6744907',
        'name': 'Test Home',
      },
      'protocol': {'min': 1, 'max': 1},
      'serverTime': '2026-09-13T12:00:00Z',
      'features': {'pairing': true, 'realtime': true},
    });

    expect(
      verifyServerIdentity('067ee4ce-60d1-44f6-b7bc-c1d6528e47aa', info),
      isA<IdentityMismatch>(),
    );
  });

  test('advertises only available capabilities', () {
    final capabilities = CapabilityNegotiator.available(
      const PlatformFeatures(
        notificationReceive: true,
        foregroundPresence: true,
      ),
    );

    expect(capabilities.map((capability) => capability.name), [
      'notification.receive',
      'device.presence',
    ]);
    expect(capabilities.last.constraints, {'mode': 'foreground'});
  });
}
