import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/features/exchange/transfer_compose_bar.dart';
import 'package:homeplace/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('direct photo and file actions stay separate', (tester) async {
    var photos = 0;
    var files = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TransferComposeBar(
            onPhotos: () => photos++,
            onFiles: () => files++,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('transfer-send-photos')));
    await tester.tap(find.byKey(const ValueKey('transfer-send-files')));
    expect(photos, 1);
    expect(files, 1);
  });

  testWidgets('file preparation disables repeat selection', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: TransferComposeBar(
            preparing: true,
            onPhotos: () => calls++,
            onFiles: () => calls++,
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('transfer-send-files')));
    expect(calls, 0);
  });
}
