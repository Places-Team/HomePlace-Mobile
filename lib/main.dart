import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'core/network/server_address.dart';
import 'core/branding/brand_mark.dart';
import 'core/settings/app_preferences.dart';
import 'features/connection/connection_controller.dart';
import 'features/home/home_shell.dart';
import 'l10n/generated/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = ConnectionController();
  final preferences = AppPreferences();
  runApp(HomePlaceApp(controller: controller, preferences: preferences));
  await preferences.initialize();
  await controller.initialize();
}

class HomePlaceApp extends StatelessWidget {
  const HomePlaceApp({
    required this.controller,
    required this.preferences,
    super.key,
  });
  final ConnectionController controller;
  final AppPreferences preferences;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: preferences,
    builder: (context, _) => MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: preferences.locale,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: preferences.themeMode,
      home: ConnectionShell(controller: controller, preferences: preferences),
    ),
  );
}

class ConnectionShell extends StatelessWidget {
  const ConnectionShell({
    required this.controller,
    required this.preferences,
    super.key,
  });
  final ConnectionController controller;
  final AppPreferences preferences;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      if (controller.stage == ConnectionStage.connected) {
        return HomeShell(
          key: ValueKey(controller.profile?.serverId),
          connection: controller,
          preferences: preferences,
        );
      }
      return Scaffold(
        appBar: controller.stage == ConnectionStage.welcome
            ? null
            : AppBar(
                title: Text(l10n.appName),
                actions: [
                  if (controller.diagnostics != null)
                    IconButton(
                      tooltip: l10n.diagnostics,
                      icon: const Icon(Icons.troubleshoot),
                      onPressed: () =>
                          _showDiagnostics(context, controller, l10n),
                    ),
                ],
              ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _screen(context, controller, l10n),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _screen(
    BuildContext context,
    ConnectionController controller,
    AppLocalizations l10n,
  ) => switch (controller.stage) {
    ConnectionStage.welcome => _Welcome(controller: controller, l10n: l10n),
    ConnectionStage.address ||
    ConnectionStage.validating => _Address(controller: controller, l10n: l10n),
    ConnectionStage.preview => _Preview(controller: controller, l10n: l10n),
    ConnectionStage.pairing => _Pairing(controller: controller, l10n: l10n),
    ConnectionStage.connected => const SizedBox.shrink(),
  };

  Future<void> _showDiagnostics(
    BuildContext context,
    ConnectionController controller,
    AppLocalizations l10n,
  ) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.diagnostics),
      content: SelectableText(controller.diagnostics ?? l10n.noDiagnostics),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    ),
  );
}

ThemeData _theme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xff829eff),
    brightness: brightness,
    surface: dark ? const Color(0xff0b0d14) : const Color(0xfff5f6fb),
  );
  return ThemeData(
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark
        ? const Color(0xff0b0d14)
        : const Color(0xfff5f6fb),
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: .5),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      elevation: 0,
    ),
  );
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.controller, required this.l10n});
  final ConnectionController controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey('welcome'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Center(
        child: Container(
          width: 112,
          height: 112,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(34),
          ),
          child: const HomePlaceMark(size: 78),
        ),
      ),
      const SizedBox(height: 24),
      Text(
        l10n.welcomeTitle,
        style: Theme.of(context).textTheme.headlineLarge,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      Text(
        l10n.welcomeBody,
        style: Theme.of(context).textTheme.bodyLarge,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 32),
      FilledButton(
        onPressed: controller.continueFromWelcome,
        child: Text(l10n.getStarted),
      ),
    ],
  );
}

class _Address extends StatefulWidget {
  const _Address({required this.controller, required this.l10n});
  final ConnectionController controller;
  final AppLocalizations l10n;

  @override
  State<_Address> createState() => _AddressState();
}

class _AddressState extends State<_Address> {
  late final TextEditingController field = TextEditingController(
    text: widget.controller.addressInput,
  );

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final busy = widget.controller.stage == ConnectionStage.validating;
    return Column(
      key: const ValueKey('address'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.l10n.connectTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(widget.l10n.connectBody),
        const SizedBox(height: 24),
        TextField(
          controller: field,
          enabled: !busy,
          keyboardType: TextInputType.url,
          autocorrect: false,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: widget.l10n.serverAddress,
            hintText: widget.l10n.serverHint,
            errorText: widget.controller.error,
          ),
          onChanged: widget.controller.setAddress,
          onSubmitted: (_) => widget.controller.validateAddress(),
        ),
        if (widget.controller.pendingCertificateFingerprint
            case final fingerprint?) ...[
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.l10n.selfSignedWarning),
                  const SizedBox(height: 8),
                  SelectableText(
                    fingerprint,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: busy
                        ? null
                        : widget.controller.confirmCertificate,
                    child: Text(widget.l10n.trustCertificate),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: busy || field.text.trim().isEmpty
              ? null
              : widget.controller.validateAddress,
          child: busy
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.l10n.continueAction),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: busy ? null : () => _explainAndScan(context),
          icon: const Icon(Icons.qr_code_scanner),
          label: Text(widget.l10n.scanQr),
        ),
        if (widget.controller.profile != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: busy ? null : widget.controller.returnToConnectedProfile,
            child: Text(widget.l10n.cancelAddingConnection),
          ),
        ],
      ],
    );
  }

  Future<void> _explainAndScan(BuildContext context) async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.l10n.scanQr),
        content: Text(widget.l10n.cameraExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.l10n.allowCamera),
          ),
        ],
      ),
    );
    if (proceed != true || !context.mounted) return;
    final value = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => _QrScanner(title: widget.l10n.scanQr)),
    );
    if (value == null || !mounted) return;
    widget.controller.applyQrPayload(value);
    field.text = widget.controller.addressInput;
  }
}

class _QrScanner extends StatefulWidget {
  const _QrScanner({required this.title});
  final String title;

  @override
  State<_QrScanner> createState() => _QrScannerState();
}

class _QrScannerState extends State<_QrScanner> {
  bool returned = false;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: MobileScanner(
      onDetect: (capture) {
        if (returned) return;
        final value = capture.barcodes.firstOrNull?.rawValue;
        if (value == null) return;
        returned = true;
        Navigator.pop(context, value);
      },
    ),
  );
}

class _Preview extends StatelessWidget {
  const _Preview({required this.controller, required this.l10n});
  final ConnectionController controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final info = controller.serverInfo!;
    final address = controller.serverAddress!;
    return Column(
      key: const ValueKey('preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          info.features.pairing ? l10n.readyToPair : l10n.serverVerified,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Text(
          info.server.name,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _Detail(label: l10n.serverUrl, value: address.uri.toString()),
                _Detail(label: l10n.serverId, value: info.server.id),
                _Detail(
                  label: l10n.security,
                  value: address.security == ConnectionSecurity.localHttp
                      ? l10n.localHttpWarning
                      : l10n.secureConnection,
                ),
                _Detail(
                  label: l10n.protocol,
                  value: '${info.protocol.min}–${info.protocol.max}',
                ),
              ],
            ),
          ),
        ),
        if (address.security == ConnectionSecurity.localHttp) ...[
          const SizedBox(height: 12),
          Text(
            l10n.localHttpWarning,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        if (controller.error case final message?) ...[
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 20),
        if (info.features.pairing)
          FilledButton(
            onPressed: () => _notificationChoice(context),
            child: Text(l10n.pair),
          )
        else
          Text(l10n.pairingUnavailable),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: controller.useAnotherAddress,
          child: Text(l10n.useAnotherAddress),
        ),
      ],
    );
  }

  Future<void> _notificationChoice(BuildContext context) async {
    final allow = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.enableNotifications),
        content: Text(l10n.notificationExplanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.enableNotifications),
          ),
        ],
      ),
    );
    if (allow != null) {
      await controller.startPairing(requestNotifications: allow);
    }
  }
}

class _Pairing extends StatelessWidget {
  const _Pairing({required this.controller, required this.l10n});
  final ConnectionController controller;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final session = controller.pairingSession;
    return Column(
      key: const ValueKey('pairing'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.pairingTitle,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(l10n.pairingBody),
        const SizedBox(height: 28),
        if (session == null)
          const Center(child: CircularProgressIndicator())
        else ...[
          Text(l10n.pairingCode, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          SelectableText(
            session.code,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium
                ?.copyWith(letterSpacing: 8, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.expiresAt(
              TimeOfDay.fromDateTime(session.expiresAt.toLocal())
                  .format(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 28),
        OutlinedButton(
          onPressed: controller.cancelPairing,
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Flexible(child: SelectableText(value, textAlign: TextAlign.end)),
      ],
    ),
  );
}
