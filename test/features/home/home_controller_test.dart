import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/features/home/home_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('legacy global clipboard consent does not start polling', () async {
    SharedPreferences.setMockInitialValues({'clipboard.autoSend': true});
    var reads = 0;
    final controller = HomeController(sessionProvider: () async => null);
    controller.setForeground(false);
    controller.bindClipboardReader(() async {
      reads += 1;
      return null;
    });
    await controller.initialize();
    expect(reads, 0);
    controller.setForeground(true);
    await pumpEventQueue();
    expect(reads, 0);
    controller.setForeground(false);
    controller.dispose();
  });

  test('clipboard consent does not follow another paired account', () async {
    SharedPreferences.setMockInitialValues({});
    final first = AuthenticatedLinkSession(
      address: ServerAddress(
        uri: Uri.parse('http://127.0.0.1:1'),
        isLocal: true,
        security: ConnectionSecurity.localHttp,
      ),
      credential: 'account-a-credential',
      serverId: 'server-a',
      serverName: 'A',
    );
    final second = AuthenticatedLinkSession(
      address: first.address,
      credential: 'account-b-credential',
      serverId: 'server-b',
      serverName: 'B',
    );
    final accountA = HomeController(sessionProvider: () async => first);
    accountA.setForeground(false);
    await accountA.setAutoClipboardEnabled(true);
    accountA.dispose();

    final accountB = HomeController(sessionProvider: () async => second);
    accountB.setForeground(false);
    await accountB.initialize();
    expect(accountB.autoClipboardEnabled, isFalse);
    accountB.dispose();
  });

  test(
    'consent toggle cannot authorize an account switched mid-operation',
    () async {
      SharedPreferences.setMockInitialValues({});
      final address = ServerAddress(
        uri: Uri.parse('http://127.0.0.1:1'),
        isLocal: true,
        security: ConnectionSecurity.localHttp,
      );
      final first = AuthenticatedLinkSession(
        address: address,
        credential: 'first-credential',
        serverId: 'first-server',
        serverName: 'First',
      );
      final second = AuthenticatedLinkSession(
        address: address,
        credential: 'second-credential',
        serverId: 'second-server',
        serverName: 'Second',
      );
      var calls = 0;
      final controller = HomeController(
        sessionProvider: () async {
          calls++;
          return calls == 1 ? first : second;
        },
      );
      controller.setForeground(false);
      await controller.setAutoClipboardEnabled(true);
      expect(controller.autoClipboardEnabled, isFalse);
      controller.dispose();
      final reopened = HomeController(sessionProvider: () async => second);
      reopened.setForeground(false);
      await reopened.initialize();
      expect(reopened.autoClipboardEnabled, isFalse);
      reopened.dispose();
    },
  );

  test('in-flight clipboard read cannot send after account changes', () async {
    SharedPreferences.setMockInitialValues({});
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(server.close);
    var relays = 0;
    server.listen((request) async {
      if (request.uri.path == '/api/link/mobile/clipboard') relays++;
      request.response.headers.contentType = ContentType.json;
      request.response.write('{"delivered":1}');
      await request.response.close();
    });
    final address = ServerAddress(
      uri: Uri.parse('http://127.0.0.1:${server.port}'),
      isLocal: true,
      security: ConnectionSecurity.localHttp,
    );
    var current = AuthenticatedLinkSession(
      address: address,
      credential: 'account-a-credential',
      serverId: 'server-a',
      serverName: 'A',
    );
    final controller = HomeController(sessionProvider: () async => current);
    final clipboard = Completer<String?>();
    controller.bindClipboardReader(() => clipboard.future);
    await controller.setAutoClipboardEnabled(true);

    current = AuthenticatedLinkSession(
      address: address,
      credential: 'account-b-credential',
      serverId: 'server-b',
      serverName: 'B',
    );
    clipboard.complete('private text from A');
    await pumpEventQueue();
    expect(relays, 0);
    controller.dispose();
  });

  test(
    'refresh always leaves loading state when secure storage fails',
    () async {
      final controller = HomeController(
        sessionProvider: () => Future.error(const FormatException('corrupt')),
      );
      await controller.refresh(initial: true);
      expect(controller.loading, isFalse);
      expect(controller.refreshing, isFalse);
      expect(
        controller.error,
        'HomePlace could not refresh securely. Pull down to try again.',
      );
    },
  );
}
