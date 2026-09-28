import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/core/network/server_address.dart';
import 'package:homeplace/core/sharing/share_service.dart';
import 'package:homeplace/features/connection/connection_controller.dart';
import 'package:homeplace/features/exchange/file_exchange_card.dart';
import 'package:homeplace/link/exchange_api.dart';
import 'package:homeplace/link/link_client.dart';
import 'package:homeplace/l10n/generated/app_localizations.dart';

final class _Gateway implements FileExchangeGateway {
  final files = <FileExchange>[];
  String? uploadedAccess;
  bool uploadedQuick = false;
  String? inspectedToken;
  String? resolvedCode;
  bool downloaded = false;

  @override
  Future<LinkResult<int>> fileLimit(AuthenticatedLinkSession session) async =>
      const LinkSuccess(1024 * 1024 * 1024);

  FileExchange exchange(String access, {String? shortCode}) => FileExchange(
    token: 'abcdefghijklmnopqrstuv',
    shortCode: shortCode,
    filename: 'family.zip',
    mimeType: 'application/zip',
    size: 4,
    access: access,
    expiresAt: DateTime.utc(2026, 9, 28),
    deleteAfterOpen: false,
  );

  @override
  Future<LinkResult<List<FileExchange>>> listFiles(
    AuthenticatedLinkSession session,
  ) async => LinkSuccess(List.of(files));

  @override
  Future<LinkResult<FileExchange>> createFile(
    AuthenticatedLinkSession session,
    File file, {
    required String filename,
    required String mimeType,
    required int expiresInSeconds,
    required String access,
    required bool deleteAfterOpen,
    bool quick = false,
    void Function(int transferred, int total)? onProgress,
    LinkTransferCancellation? cancellation,
  }) async {
    uploadedAccess = access;
    uploadedQuick = quick;
    expect(filename, 'family.zip');
    expect(file.path, '/private/tmp/family.zip');
    onProgress?.call(4, 4);
    final item = exchange(
      quick ? 'link' : access,
      shortCode: quick ? 'Ab3Xy' : null,
    );
    files.add(item);
    return LinkSuccess(item);
  }

  @override
  Future<LinkResult<FileExchange>> inspectFile(
    AuthenticatedLinkSession session,
    String token,
  ) async {
    inspectedToken = token;
    return LinkSuccess(exchange('account'));
  }

  @override
  Future<LinkResult<String>> resolveShortCode(
    AuthenticatedLinkSession session,
    String code,
  ) async {
    resolvedCode = code;
    return const LinkSuccess('abcdefghijklmnopqrstuv');
  }

  @override
  Future<LinkResult<DownloadedLinkFile>> downloadFile(
    AuthenticatedLinkSession session,
    FileExchange exchange, {
    required File destination,
    void Function(int transferred, int total)? onProgress,
    LinkTransferCancellation? cancellation,
  }) async {
    downloaded = true;
    await destination.writeAsBytes([1, 2, 3, 4]);
    onProgress?.call(4, 4);
    return LinkSuccess(DownloadedLinkFile(file: destination, size: 4));
  }

  @override
  Future<LinkResult<void>> revoke(
    AuthenticatedLinkSession session,
    String token,
  ) async {
    files.removeWhere((item) => item.token == token);
    return const LinkSuccess(null);
  }
}

final class _Sharing implements ShareService {
  _Sharing(this.tempPath);
  final String tempPath;
  bool saved = false;

  @override
  bool get isSupported => true;
  @override
  Future<void> initialize(void Function(SharedContent content) onShare) async {}
  @override
  Future<void> openUrl(String url) async {}
  @override
  Future<String> createTemporaryFilePath() async => tempPath;
  @override
  Future<SavedSharedFile> saveFilePath(
    String path,
    String filename,
    String mimeType,
  ) async {
    saved = true;
    return SavedSharedFile(
      location: 'content://test/file',
      filename: filename,
      mimeType: mimeType,
    );
  }

  @override
  Future<void> openSavedFile(SavedSharedFile file) async {}
}

void main() {
  testWidgets(
    'uploads only after selection and downloads only after confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final source = File('/private/tmp/family.zip');
      final gateway = _Gateway();
      final sharing = _Sharing('/private/tmp/download.tmp');
      final session = AuthenticatedLinkSession(
        address: ServerAddress(
          uri: Uri.parse('https://home.example.test'),
          isLocal: false,
          security: ConnectionSecurity.trustedHttps,
        ),
        credential: 'secret',
        serverId: 'server-1',
        serverName: 'Test',
      );
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: FileExchangeCard(
                sessionProvider: () async => session,
                available: true,
                gateway: gateway,
                sharing: sharing,
                picker: () async => SelectedExchangeFile(
                  file: source,
                  filename: 'family.zip',
                  mimeType: 'application/zip',
                  size: 4,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Open file exchange'));
      await tester.pumpAndSettle();
      expect(gateway.uploadedAccess, isNull);
      await tester.tap(find.text('Choose any file'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Upload and create link'));
      await tester.tap(find.text('Upload and create link'));
      await tester.pumpAndSettle();
      expect(gateway.uploadedAccess, 'account');
      expect(find.text('family.zip', skipOffstage: false), findsWidgets);

      await tester.ensureVisible(find.text('Choose any file'));
      await tester.tap(find.text('Choose any file'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anyone with the link').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Upload and create link'));
      await tester.tap(find.text('Upload and create link'));
      await tester.pumpAndSettle();
      expect(gateway.uploadedAccess, 'account');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(gateway.uploadedAccess, 'account');
      await tester.tap(find.text('Upload and create link'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create external link'));
      await tester.pumpAndSettle();
      expect(gateway.uploadedAccess, 'link');

      await tester.ensureVisible(find.text('Quick one-time code'));
      await tester.tap(find.text('Quick one-time code'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Choose any file'));
      await tester.tap(find.text('Choose any file'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Upload and create link'));
      await tester.tap(find.text('Upload and create link'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create external link'));
      await tester.pumpAndSettle();
      expect(gateway.uploadedQuick, isTrue);
      expect(find.textContaining('Ab3Xy'), findsWidgets);

      await tester.ensureVisible(
        find.byKey(const ValueKey('file-exchange-link')),
      );
      await tester.enterText(
        find.byKey(const ValueKey('file-exchange-link')),
        'https://another.example.test/x/abcdefghijklmnopqrstuv',
      );
      await tester.pump();
      await tester.ensureVisible(find.text('Check file'));
      await tester.tap(find.text('Check file'));
      await tester.pumpAndSettle();
      expect(gateway.inspectedToken, isNull);
      await tester.enterText(
        find.byKey(const ValueKey('file-exchange-link')),
        'https://home.example.test/x/abcdefghijklmnopqrstuv',
      );
      await tester.pump();
      await tester.tap(find.text('Check file'));
      await tester.pumpAndSettle();
      expect(gateway.inspectedToken, 'abcdefghijklmnopqrstuv');
      await tester.enterText(
        find.byKey(const ValueKey('file-exchange-link')),
        'Ab3Xy',
      );
      await tester.pump();
      await tester.tap(find.text('Check file'));
      await tester.pumpAndSettle();
      expect(gateway.resolvedCode, 'Ab3Xy');
      expect(gateway.inspectedToken, 'abcdefghijklmnopqrstuv');
      await tester.enterText(
        find.byKey(const ValueKey('file-exchange-link')),
        'https://home.example.test/f/Ab3Xy',
      );
      await tester.pump();
      await tester.tap(find.text('Check file'));
      await tester.pumpAndSettle();
      expect(gateway.resolvedCode, 'Ab3Xy');
      await tester.ensureVisible(find.text('Download to Downloads'));
      await tester.tap(find.text('Download to Downloads'));
      await tester.pumpAndSettle();
      expect(gateway.downloaded, false);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(gateway.downloaded, false);
      expect(sharing.saved, false);
      expect(tester.takeException(), isNull);
    },
  );
}
