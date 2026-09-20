import 'dart:io';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../core/branding/brand_mark.dart';
import '../../core/settings/app_preferences.dart';
import '../../core/storage/transfer_activity_store.dart';
import '../../link/mobile_models.dart';
import '../../core/sharing/share_service.dart';
import '../connection/connection_controller.dart';
import 'home_controller.dart';

const _violet = Color(0xff829eff);
const _coral = Color(0xffff746c);
const _mint = Color(0xff70e1b4);
const _ink = Color(0xff11111b);

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.connection,
    this.homeController,
    this.preferences,
    super.key,
  });
  final ConnectionController connection;
  final HomeController? homeController;
  final AppPreferences? preferences;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late final HomeController home =
      widget.homeController ??
      HomeController(sessionProvider: widget.connection.authenticatedSession);
  late final bool ownsHome = widget.homeController == null;
  late final PageController pages = PageController();
  var tab = 0;

  @override
  void initState() {
    super.initState();
    home.bindClipboardReader(widget.connection.readClipboardTextForAutoRelay);
    if (ownsHome) home.initialize();
  }

  @override
  void dispose() {
    pages.dispose();
    if (ownsHome) home.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([home, widget.connection]),
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      if (home.loading && home.overview == null) {
        return _Loading(label: l10n.loadingHome);
      }
      if (home.overview == null) {
        return _LoadError(
          message: home.error?.contains('permission') == true
              ? l10n.permissionsRequired
              : home.error ?? l10n.noDiagnostics,
          retry: () => home.refresh(initial: true),
          disconnect: widget.connection.disconnect,
        );
      }
      final overview = home.overview!;
      return Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            const Positioned(
              right: -90,
              top: -130,
              child: _Aura(size: 310, color: _violet),
            ),
            const Positioned(
              left: -130,
              bottom: 80,
              child: _Aura(size: 260, color: _coral),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _TopBar(
                    serverName:
                        widget.connection.profile?.serverName ?? l10n.appName,
                    refreshing: home.refreshing,
                    onRefresh: home.refresh,
                    onSettings: () => _showSettings(context, l10n),
                  ),
                  if (home.error case final message?)
                    _MessageBanner(
                      message: message == 'clipboard_empty'
                          ? l10n.clipboardEmpty
                          : message == 'clipboard_no_devices'
                          ? l10n.clipboardNoDevices
                          : message,
                      error: true,
                      onClose: home.clearMessage,
                    )
                  else if (home.notice case final notice?)
                    _MessageBanner(
                      message: notice == 'telegram'
                          ? l10n.telegramSent
                          : notice.startsWith('clipboard:')
                          ? l10n.clipboardSent(
                              int.tryParse(notice.substring(10)) ?? 0,
                            )
                          : notice.startsWith('clipboard_auto:')
                          ? l10n.automaticClipboardSent(
                              int.tryParse(notice.substring(15)) ?? 0,
                            )
                          : notice.startsWith('share:')
                          ? l10n.shareSent(notice.substring(6))
                          : notice.startsWith('file:')
                          ? l10n.fileSaved(notice.substring(5))
                          : l10n.requestSent(notice),
                      error: false,
                      onClose: home.clearMessage,
                    ),
                  if (widget.connection.pendingOutgoingShare
                      case final content?)
                    _OutgoingShareBanner(
                      content: content,
                      onCancel: widget.connection.clearOutgoingShare,
                      onChoose: () =>
                          _showShareTargets(context, overview, content),
                    ),
                  Expanded(
                    child: PageView(
                      controller: pages,
                      onPageChanged: (value) => setState(() => tab = value),
                      children: [
                        _OverviewPage(
                          overview: overview,
                          home: home,
                          connection: widget.connection,
                        ),
                        _PlanPage(overview: overview, home: home),
                        _RequestsPage(overview: overview, home: home),
                        _MonitorPage(overview: overview, home: home),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _PillNavigation(
          index: tab,
          onChanged: (value) {
            setState(() => tab = value);
            pages.jumpToPage(value);
          },
        ),
      );
    },
  );

  Future<void> _showSettings(
    BuildContext context,
    AppLocalizations l10n,
  ) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
        child: ListenableBuilder(
          listenable: Listenable.merge([
            home,
            if (widget.preferences != null) widget.preferences!,
          ]),
          builder: (context, _) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.settings,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              if (widget.preferences case final preferences?) ...[
                DropdownButtonFormField<AppLanguage>(
                  initialValue: preferences.language,
                  decoration: InputDecoration(
                    labelText: l10n.language,
                    prefixIcon: const Icon(Icons.language_rounded),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: AppLanguage.system,
                      child: Text(l10n.languageSystem),
                    ),
                    DropdownMenuItem(
                      value: AppLanguage.english,
                      child: Text(l10n.languageEnglish),
                    ),
                    DropdownMenuItem(
                      value: AppLanguage.russian,
                      child: Text(l10n.languageRussian),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) preferences.setLanguage(value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ThemeMode>(
                  initialValue: preferences.themeMode,
                  decoration: InputDecoration(
                    labelText: l10n.appearance,
                    prefixIcon: const Icon(Icons.palette_outlined),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text(l10n.themeSystem),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text(l10n.themeLight),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text(l10n.themeDark),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) preferences.setThemeMode(value);
                  },
                ),
                const SizedBox(height: 8),
              ],
              if (Platform.isAndroid)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: home.autoClipboardEnabled,
                  onChanged: home.setAutoClipboardEnabled,
                  title: Text(l10n.automaticClipboard),
                  subtitle: Text(l10n.automaticClipboardBody),
                  secondary: const Icon(Icons.content_paste_go_rounded),
                ),
              const Divider(height: 28),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  widget.connection.profile?.secure == true
                      ? Icons.verified_user_rounded
                      : Icons.warning_amber_rounded,
                ),
                title: Text(l10n.connectionSecurity),
                subtitle: Text(
                  widget.connection.profile?.secure == true
                      ? l10n.secureConnection
                      : l10n.localUnencryptedConnection,
                ),
              ),
              SelectableText(widget.connection.profile?.preferredUrl ?? ''),
              const SizedBox(height: 6),
              SelectableText(
                '${l10n.serverIdentity}: ${widget.connection.profile?.serverId ?? ''}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              FilledButton.tonalIcon(
                onPressed: () async {
                  Navigator.pop(context);
                  await widget.connection.disconnect();
                },
                icon: const Icon(Icons.link_off_rounded),
                label: Text(l10n.disconnect),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Future<void> _showShareTargets(
    BuildContext context,
    MobileOverview overview,
    SharedContent content,
  ) async {
    final l10n = AppLocalizations.of(context);
    final targets =
        overview.shareTargets
            .where(
              (target) => switch (content.kind) {
                SharedContentKind.text => target.supportsText,
                SharedContentKind.url => target.supportsUrl,
                SharedContentKind.file => target.supportsFile,
              },
            )
            .toList(growable: false)
          ..sort((a, b) {
            final ownership = (b.ownedByCurrentUser ? 1 : 0).compareTo(
              a.ownedByCurrentUser ? 1 : 0,
            );
            if (ownership != 0) return ownership;
            final presence = (b.online ? 1 : 0).compareTo(a.online ? 1 : 0);
            if (presence != 0) return presence;
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.chooseDevice,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(l10n.onlyYourDevices),
              const SizedBox(height: 16),
              if (targets.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(l10n.noShareDevices, textAlign: TextAlign.center),
                )
              else
                ...targets.map(
                  (target) => ListTile(
                    leading: Icon(
                      target.platform == 'android'
                          ? Icons.android_rounded
                          : Icons.phone_iphone_rounded,
                    ),
                    title: Text(target.name),
                    subtitle: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: target.ownedByCurrentUser
                                ? l10n.yourDevice
                                : l10n.householdDevice(
                                    target.ownerName ?? l10n.appName,
                                  ),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: ' · '),
                          TextSpan(
                            text: target.online
                                ? l10n.deviceOnline
                                : l10n.deviceOffline,
                          ),
                        ],
                      ),
                    ),
                    trailing: Icon(
                      target.ownedByCurrentUser
                          ? Icons.chevron_right_rounded
                          : Icons.group_rounded,
                    ),
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: sheetContext,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(l10n.confirmShareTitle),
                          content: Text(
                            target.ownedByCurrentUser
                                ? l10n.confirmShareBody(target.name)
                                : l10n.confirmHouseholdShareBody(
                                    target.ownerName ?? l10n.appName,
                                    target.name,
                                  ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: Text(l10n.cancel),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: Text(l10n.send),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true || !mounted) return;
                      final sent = await home.sendSharedContent(
                        target,
                        content,
                      );
                      if (sent) widget.connection.clearOutgoingShare();
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OutgoingShareBanner extends StatelessWidget {
  const _OutgoingShareBanner({
    required this.content,
    required this.onCancel,
    required this.onChoose,
  });
  final SharedContent content;
  final VoidCallback onCancel;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (content.kind) {
      SharedContentKind.text => content.value ?? '',
      SharedContentKind.url => content.value ?? '',
      SharedContentKind.file =>
        '${content.filename} · ${_formatBytes(content.size ?? 0)}',
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _violet.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.ios_share_rounded, color: _violet),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.readyToShare,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded),
          ),
          FilledButton(onPressed: onChoose, child: Text(l10n.choose)),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.serverName,
    required this.refreshing,
    required this.onRefresh,
    required this.onSettings,
  });
  final String serverName;
  final bool refreshing;
  final VoidCallback onRefresh;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 14, 8),
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.inverseSurface,
            borderRadius: BorderRadius.circular(15),
          ),
          child: HomePlaceMark(
            size: 28,
            lightOnDark: Theme.of(context).brightness == Brightness.light,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HOMEPLACE',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(letterSpacing: 2.4, fontWeight: FontWeight.w900),
              ),
              Text(
                serverName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context).refresh,
          onPressed: refreshing ? null : onRefresh,
          icon: refreshing
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh_rounded),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context).settings,
          onPressed: onSettings,
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    ),
  );
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage({
    required this.overview,
    required this.home,
    required this.connection,
  });
  final MobileOverview overview;
  final HomeController home;
  final ConnectionController connection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final next = _nextItem(overview);
    final missingPermissions = !overview.permissions.contains('dashboard.read');
    return _ScrollPage(
      onRefresh: home.refresh,
      children: [
        Text(
          l10n.everythingInPlace,
          style: Theme.of(context).textTheme.displaySmall
              ?.copyWith(fontWeight: FontWeight.w900, height: .95),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.homeOverviewBody,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        if (missingPermissions) ...[
          const SizedBox(height: 16),
          _Surface(
            color: _coral.withValues(alpha: .15),
            child: Text(l10n.permissionsRequired),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.wifi_tethering_rounded,
                color: _mint,
                value: '${overview.monitoring.online}',
                label: l10n.onlineNow,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.bolt_rounded,
                color: overview.monitoring.offline > 0 ? _coral : _violet,
                value: '${overview.monitoring.offline}',
                label: l10n.needsAttention,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Surface(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DateGlyph(date: next?.$2 ?? DateTime.now()),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.nextUp,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      next?.$1 ?? l10n.nothingPlanned,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    if (next != null)
                      Text(
                        _formatWhen(context, next.$2, allDay: next.$3),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _Surface(
          color: overview.telegram.enabled
              ? _violet.withValues(alpha: .12)
              : null,
          child: Row(
            children: [
              const _RoundIcon(icon: Icons.send_rounded, color: _violet),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.telegramTitle,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      overview.telegram.enabled
                          ? l10n.telegramConnected
                          : l10n.telegramDisconnected,
                    ),
                  ],
                ),
              ),
              if (overview.telegram.enabled &&
                  overview.permissions.contains('telegram.send'))
                IconButton.filledTonal(
                  tooltip: l10n.telegramTest,
                  onPressed: home.busyId == 'telegram'
                      ? null
                      : home.testTelegram,
                  icon: home.busyId == 'telegram'
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_outward_rounded),
                ),
            ],
          ),
        ),
        if (Platform.isAndroid &&
            overview.permissions.contains('clipboard.relay')) ...[
          const SizedBox(height: 12),
          _ClipboardCard(
            pending: connection.pendingClipboard,
            sending: home.busyId == 'clipboard',
            autoEnabled: home.autoClipboardEnabled,
            onAutoChanged: home.setAutoClipboardEnabled,
            onSend: () => home.sendClipboard(connection.readClipboardText),
            onAccept: connection.acceptPendingClipboard,
            onDismiss: connection.dismissPendingClipboard,
          ),
        ],
        if (connection.pendingIncomingShare case final offer?) ...[
          const SizedBox(height: 12),
          _IncomingShareCard(
            offer: offer,
            receiving: home.busyId == 'receive-file',
            onDismiss: connection.dismissIncomingShare,
            onAccept: offer.kind == SharedContentKind.file
                ? () => home.acceptSharedFile(offer, connection)
                : () => home.acceptIncomingTextOrUrl(offer, connection),
          ),
        ],
        if (home.transferActivity.isNotEmpty) ...[
          const SizedBox(height: 12),
          _TransferActivityCard(home: home),
        ],
        const SizedBox(height: 110),
      ],
    );
  }
}

class _TransferActivityCard extends StatelessWidget {
  const _TransferActivityCard({required this.home});
  final HomeController home;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.recentTransfers,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              TextButton(
                onPressed: home.clearTransferActivity,
                child: Text(l10n.clearHistory),
              ),
            ],
          ),
          Text(
            l10n.transferHistoryPrivacy,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...home.transferActivity.take(5).map((activity) {
            final sent = activity.direction == TransferDirection.sent;
            final icon = switch (activity.kind) {
              SharedContentKind.text => Icons.notes_rounded,
              SharedContentKind.url => Icons.link_rounded,
              SharedContentKind.file => Icons.insert_drive_file_rounded,
            };
            return ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: Icon(icon, color: sent ? _violet : _mint),
              title: Text(
                sent
                    ? l10n.transferSentTo(activity.peerName)
                    : l10n.transferReceivedFrom(activity.peerName),
              ),
              subtitle: Text(_formatWhen(context, activity.at)),
              trailing: Icon(
                sent ? Icons.north_east_rounded : Icons.south_west_rounded,
                size: 18,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _IncomingShareCard extends StatelessWidget {
  const _IncomingShareCard({
    required this.offer,
    required this.receiving,
    required this.onDismiss,
    required this.onAccept,
  });
  final PendingShareOffer offer;
  final bool receiving;
  final VoidCallback onDismiss;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = offer.kind == SharedContentKind.file
        ? '${offer.filename} · ${_formatBytes(offer.size ?? 0)}'
        : offer.value ?? '';
    return _Surface(
      color: _violet.withValues(alpha: .11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _RoundIcon(
                icon: Icons.move_to_inbox_rounded,
                color: _violet,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.incomingShare(offer.sourceName),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(detail, maxLines: 3, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: receiving ? null : onDismiss,
                  child: Text(l10n.decline),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: receiving ? null : onAccept,
                  child: receiving
                      ? const SizedBox.square(
                          dimension: 17,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          offer.kind == SharedContentKind.file
                              ? l10n.acceptAndSave
                              : offer.kind == SharedContentKind.url
                              ? l10n.open
                              : l10n.clipboardCopy,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClipboardCard extends StatelessWidget {
  const _ClipboardCard({
    required this.pending,
    required this.sending,
    required this.autoEnabled,
    required this.onAutoChanged,
    required this.onSend,
    required this.onAccept,
    required this.onDismiss,
  });
  final PendingClipboard? pending;
  final bool sending;
  final bool autoEnabled;
  final ValueChanged<bool> onAutoChanged;
  final VoidCallback onSend;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final offer = pending;
    return _Surface(
      color: _mint.withValues(alpha: .1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const _RoundIcon(
                icon: Icons.content_paste_go_rounded,
                color: _mint,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      offer == null
                          ? l10n.clipboardTitle
                          : l10n.clipboardIncoming(offer.sourceName),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      offer == null ? l10n.clipboardBody : offer.text,
                      maxLines: offer == null ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (offer == null) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: autoEnabled,
              onChanged: onAutoChanged,
              title: Text(l10n.automaticClipboard),
              subtitle: Text(l10n.automaticClipboardBody),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: sending ? null : onSend,
              icon: sending
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(l10n.clipboardSend),
            ),
          ] else
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onDismiss,
                    child: Text(l10n.clipboardDismiss),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    child: Text(l10n.clipboardCopy),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _PlanPage extends StatefulWidget {
  const _PlanPage({required this.overview, required this.home});
  final MobileOverview overview;
  final HomeController home;

  @override
  State<_PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<_PlanPage> {
  late DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime selected = _day(DateTime.now());

  MobileOverview get overview => widget.overview;
  HomeController get home => widget.home;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMonth());
  }

  void _loadMonth() {
    if (!overview.permissions.contains('calendar.read')) return;
    home.loadCalendar(_rangeStart(month), _rangeEnd(month));
  }

  Future<void> _refresh() async {
    await home.refresh();
    if (!overview.permissions.contains('calendar.read')) return;
    await home.loadCalendar(_rangeStart(month), _rangeEnd(month));
  }

  void _changeMonth(int delta) {
    setState(() {
      month = DateTime(month.year, month.month + delta);
      selected = DateTime(month.year, month.month, 1);
    });
    _loadMonth();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final upcoming =
        overview.reminders
            .where((item) => !item.done && !item.at.isBefore(now))
            .toList()
          ..sort((a, b) => a.at.compareTo(b.at));
    final overdue =
        overview.reminders
            .where((item) => !item.done && item.at.isBefore(now))
            .toList()
          ..sort((a, b) => b.at.compareTo(a.at));
    final completed = overview.reminders.where((item) => item.done).toList()
      ..sort(
        (a, b) => (b.completedAt ?? b.createdAt).compareTo(
          a.completedAt ?? a.createdAt,
        ),
      );
    return _ScrollPage(
      onRefresh: _refresh,
      children: [
        _PageHeading(
          title: l10n.calendarTitle,
          subtitle: overview.calendar.email,
        ),
        const SizedBox(height: 18),
        if (!overview.calendar.connected)
          _EmptyCard(
            icon: Icons.event_busy_rounded,
            text: l10n.calendarNotConnected,
          )
        else
          _MonthCalendar(
            month: month,
            selected: selected,
            events: home.calendarEvents ?? overview.calendar.events,
            loading: home.calendarLoading,
            canManage: overview.permissions.contains('calendar.manage'),
            onSelected: (value) => setState(() => selected = value),
            onPrevious: () => _changeMonth(-1),
            onNext: () => _changeMonth(1),
            onSwipe: _changeMonth,
            onAdd: () => _showCalendarEditor(
              context,
              home,
              null,
              selected,
              _rangeStart(month),
              _rangeEnd(month),
            ),
            onEdit: (event) => _showCalendarEditor(
              context,
              home,
              event,
              selected,
              _rangeStart(month),
              _rangeEnd(month),
            ),
          ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.remindersTitle,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            FilledButton.icon(
              onPressed: overview.permissions.contains('reminder.manage')
                  ? () => _addReminder(context, home)
                  : null,
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.addReminder),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (overview.reminders.isEmpty)
          _EmptyCard(
            icon: Icons.notifications_none_rounded,
            text: l10n.nothingPlanned,
          ),
        if (upcoming.isNotEmpty) ...[
          _ReminderSectionTitle(
            title: l10n.upcomingReminders,
            count: upcoming.length,
          ),
          ...upcoming.map((item) => _ReminderCard(reminder: item, home: home)),
        ],
        if (overdue.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ReminderSectionTitle(
            title: l10n.overdueReminders,
            count: overdue.length,
            color: _coral,
          ),
          ...overdue.map(
            (item) => _ReminderCard(reminder: item, home: home, overdue: true),
          ),
        ],
        if (completed.isNotEmpty) ...[
          const SizedBox(height: 12),
          _ReminderSectionTitle(
            title: l10n.completedReminders,
            count: completed.length,
            trailing: TextButton(
              onPressed: home.busyId == 'completed-reminders'
                  ? null
                  : () => _confirmClearCompleted(context, home),
              child: Text(l10n.clearCompleted),
            ),
          ),
          ...completed.map((item) => _ReminderCard(reminder: item, home: home)),
        ],
        const SizedBox(height: 110),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.month,
    required this.selected,
    required this.events,
    required this.loading,
    required this.canManage,
    required this.onSelected,
    required this.onPrevious,
    required this.onNext,
    required this.onSwipe,
    required this.onAdd,
    required this.onEdit,
  });
  final DateTime month;
  final DateTime selected;
  final List<MobileCalendarEvent> events;
  final bool loading;
  final bool canManage;
  final ValueChanged<DateTime> onSelected;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onSwipe;
  final VoidCallback onAdd;
  final ValueChanged<MobileCalendarEvent> onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final first = DateTime(month.year, month.month, 1);
    final lead = (first.weekday - DateTime.monday) % 7;
    final start = first.subtract(Duration(days: lead));
    final days = List.generate(42, (index) => start.add(Duration(days: index)));
    final weekdays = [
      ...material.narrowWeekdays.skip(1),
      material.narrowWeekdays.first,
    ];
    final selectedEvents = events.where((event) {
      final local = event.start.toLocal();
      return _sameDay(local, selected);
    }).toList()..sort((a, b) => a.start.compareTo(b.start));
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() > 250) onSwipe(velocity < 0 ? 1 : -1);
      },
      child: _Surface(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: material.previousMonthTooltip,
                  onPressed: onPrevious,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 240),
                    child: Text(
                      material.formatMonthYear(month),
                      key: ValueKey('${month.year}-${month.month}'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: material.nextMonthTooltip,
                  onPressed: onNext,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            if (loading) const LinearProgressIndicator(minHeight: 2),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                ...weekdays.map(
                  (value) => Center(
                    child: Text(
                      value.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                ...days.map((date) {
                  final active = _sameDay(date, selected);
                  final today = _sameDay(date, DateTime.now());
                  final count = events
                      .where((event) => _sameDay(event.start.toLocal(), date))
                      .length;
                  return Semantics(
                    selected: active,
                    button: true,
                    label: material.formatFullDate(date),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => onSelected(date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: active
                              ? _violet
                              : today
                              ? _violet.withValues(alpha: .12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                color: active
                                    ? Colors.white
                                    : date.month == month.month
                                    ? null
                                    : Theme.of(context).disabledColor,
                                fontWeight: today || active
                                    ? FontWeight.w900
                                    : FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 3),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: count == 0 ? 0 : 5,
                              height: 5,
                              decoration: BoxDecoration(
                                color: active ? Colors.white : _coral,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const Divider(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    material.formatMediumDate(selected),
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                if (canManage)
                  IconButton.filledTonal(
                    tooltip: l10n.addCalendarEvent,
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded),
                  ),
              ],
            ),
            if (selectedEvents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  l10n.noEventsOnDay,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...selectedEvents.map(
                (event) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_rounded, color: _violet),
                  title: Text(event.summary),
                  subtitle: Text(
                    event.allDay
                        ? l10n.allDay
                        : TimeOfDay.fromDateTime(event.start.toLocal())
                              .format(context),
                  ),
                  trailing: canManage
                      ? const Icon(Icons.chevron_right_rounded)
                      : null,
                  onTap: canManage ? () => onEdit(event) : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReminderSectionTitle extends StatelessWidget {
  const _ReminderSectionTitle({
    required this.title,
    required this.count,
    this.color,
    this.trailing,
  });
  final String title;
  final int count;
  final Color? color;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(
            '$title · $count',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w900, color: color),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.home,
    this.overdue = false,
  });
  final MobileReminder reminder;
  final HomeController home;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final busy = home.busyId == reminder.id;
    final color = reminder.done
        ? _mint
        : overdue
        ? _coral
        : _violet;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Surface(
        color: color.withValues(alpha: .08),
        child: Row(
          children: [
            IconButton.filledTonal(
              tooltip: reminder.done ? l10n.restore : l10n.complete,
              onPressed: busy
                  ? null
                  : reminder.done
                  ? () => home.reopenReminder(reminder.id)
                  : () => home.completeReminder(reminder.id),
              icon: busy
                  ? const SizedBox.square(
                      dimension: 17,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      reminder.done
                          ? Icons.settings_backup_restore_rounded
                          : Icons.check_rounded,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: busy
                    ? null
                    : () => _editReminder(context, home, reminder),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          decoration: reminder.done
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (overdue) l10n.overdue,
                          _formatWhen(context, reminder.at),
                          if (reminder.repeat != 'none')
                            _repeatLabel(l10n, reminder.repeat),
                        ].join(' · '),
                        style: TextStyle(
                          color: overdue
                              ? _coral
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: overdue
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              enabled: !busy,
              onSelected: (action) async {
                if (action == 'edit') {
                  await _editReminder(context, home, reminder);
                }
                if (action == 'delete' &&
                    context.mounted &&
                    await _confirmDeleteReminder(context, reminder)) {
                  await home.deleteReminder(reminder.id);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: Text(l10n.editReminder),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: Text(l10n.delete),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RequestsPage extends StatefulWidget {
  const _RequestsPage({required this.overview, required this.home});
  final MobileOverview overview;
  final HomeController home;

  @override
  State<_RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<_RequestsPage> {
  final field = TextEditingController();

  @override
  void dispose() {
    field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final overview = widget.overview;
    return _ScrollPage(
      onRefresh: widget.home.refresh,
      children: [
        _PageHeading(title: l10n.requestsTitle, subtitle: l10n.requestsBody),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: field,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: l10n.searchMedia,
                ),
                onSubmitted: widget.home.search,
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              tooltip: l10n.search,
              onPressed: widget.home.searching
                  ? null
                  : () => widget.home.search(field.text),
              icon: widget.home.searching
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (overview.requests.instances.isEmpty)
          _EmptyCard(
            icon: Icons.movie_filter_outlined,
            text: l10n.noMediaServices,
          )
        else ...[
          if (overview.requests.qbittorrent case final qbit?)
            _Surface(
              child: Row(
                children: [
                  const _RoundIcon(
                    icon: Icons.downloading_rounded,
                    color: _mint,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.downloads,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(l10n.activeDownloads(qbit.active)),
                      ],
                    ),
                  ),
                  Text(
                    _bytesPerSecond(qbit.downloadSpeed),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          ...widget.home.searchResults.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _Surface(
                child: Row(
                  children: [
                    _RoundIcon(
                      icon: item.kind.toLowerCase().contains('sonarr')
                          ? Icons.tv_rounded
                          : Icons.movie_rounded,
                      color: item.kind.toLowerCase().contains('sonarr')
                          ? _violet
                          : _coral,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            [
                              if (item.year != null) '${item.year}',
                              item.instanceLabel,
                            ].join(' · '),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed:
                          item.inLibrary ||
                              widget.home.busyId ==
                                  '${item.instanceLabel}:${item.externalId}'
                          ? null
                          : () => widget.home.addRequest(item),
                      child:
                          widget.home.busyId ==
                              '${item.instanceLabel}:${item.externalId}'
                          ? const SizedBox.square(
                              dimension: 17,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              item.inLibrary ? l10n.inLibrary : l10n.request,
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.home.searchResults.isEmpty)
            ...overview.requests.instances.map(
              (instance) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              instance.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _TinyBadge(
                            text:
                                '${instance.queueCount} ${l10n.queue.toLowerCase()}',
                            color: instance.warnings > 0 ? _coral : _mint,
                          ),
                        ],
                      ),
                      if (instance.upcoming.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          l10n.upcomingMedia,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        ...instance.upcoming
                            .take(3)
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  '• ${item.title}${item.sub == null ? '' : ' · ${item.sub}'}',
                                ),
                              ),
                            ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
        const SizedBox(height: 110),
      ],
    );
  }
}

class _MonitorPage extends StatelessWidget {
  const _MonitorPage({required this.overview, required this.home});
  final MobileOverview overview;
  final HomeController home;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final monitor = overview.monitoring;
    return _ScrollPage(
      onRefresh: home.refresh,
      children: [
        _PageHeading(
          title: l10n.monitoringTitle,
          subtitle: l10n.monitoringBody,
        ),
        const SizedBox(height: 20),
        _Surface(
          color: monitor.offline == 0
              ? _mint.withValues(alpha: .12)
              : _coral.withValues(alpha: .14),
          child: Row(
            children: [
              _StatusRing(
                online: monitor.online,
                total: monitor.total,
                healthy: monitor.offline == 0,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monitor.offline == 0
                          ? l10n.allQuiet
                          : l10n.needsAttention,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(l10n.onlineCount(monitor.online, monitor.total)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (monitor.services.isEmpty)
          _EmptyCard(icon: Icons.monitor_heart_outlined, text: l10n.noMonitors)
        else
          _Surface(
            padding: EdgeInsets.zero,
            child: Column(
              children: monitor.services
                  .take(30)
                  .map(
                    (service) => ListTile(
                      leading: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: service.status == 'online'
                              ? _mint
                              : service.status == 'offline'
                              ? _coral
                              : Colors.grey,
                        ),
                      ),
                      title: Text(
                        service.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        service.latencyMs == null
                            ? '—'
                            : '${service.latencyMs} ms',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        if (monitor.recent.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            l10n.recentEvents,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...monitor.recent.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: _AgendaRow(
                color: event.severity == 'error' ? _coral : _violet,
                title: event.title,
                when: _formatWhen(context, event.at),
                detail: event.detail,
              ),
            ),
          ),
        ],
        const SizedBox(height: 110),
      ],
    );
  }
}

class _PillNavigation extends StatelessWidget {
  const _PillNavigation({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (Icons.space_dashboard_rounded, l10n.homeTab),
      (Icons.event_note_rounded, l10n.calendarTab),
      (Icons.add_to_queue_rounded, l10n.requestsTab),
      (Icons.monitor_heart_rounded, l10n.monitorTab),
    ];
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: 68,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xff151824).withValues(alpha: .97)
              : const Color(0xff161a27).withValues(alpha: .97),
          borderRadius: BorderRadius.circular(34),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = i == index;
            return Expanded(
              child: Semantics(
                selected: selected,
                button: true,
                label: items[i].$2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(27),
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xffa9bcff)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(27),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          items[i].$1,
                          size: 22,
                          color: selected
                              ? const Color(0xff111521)
                              : Colors.white.withValues(alpha: .62),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].$2,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: selected
                                ? const Color(0xff111521)
                                : Colors.white.withValues(alpha: .62),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _ScrollPage extends StatelessWidget {
  const _ScrollPage({required this.children, required this.onRefresh});
  final List<Widget> children;
  final RefreshCallback onRefresh;
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    edgeOffset: 8,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      children: children,
    ),
  );
}

class _Surface extends StatelessWidget {
  const _Surface({
    required this.child,
    this.color,
    this.padding = const EdgeInsets.all(18),
  });
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color:
          color ??
          Theme.of(context).colorScheme.surfaceContainerLow
              .withValues(alpha: .92),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Theme.of(context).colorScheme.outlineVariant
            .withValues(alpha: .45),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(
            alpha: Theme.of(context).brightness == Brightness.dark ? .18 : .04,
          ),
          blurRadius: 22,
          offset: const Offset(0, 9),
        ),
      ],
    ),
    child: child,
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => _Surface(
    color: color.withValues(alpha: .14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 18),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineLarge
              ?.copyWith(fontWeight: FontWeight.w900),
        ),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .18),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: color),
  );
}

class _DateGlyph extends StatelessWidget {
  const _DateGlyph({required this.date});
  final DateTime date;
  @override
  Widget build(BuildContext context) => Container(
    width: 58,
    height: 66,
    decoration: BoxDecoration(
      color: _coral,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${date.day}',
          style: const TextStyle(
            color: _ink,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        Text(
          MaterialLocalizations.of(context)
              .formatShortMonthDay(date)
              .split(' ')
              .first
              .toUpperCase(),
          style: const TextStyle(
            color: _ink,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    ),
  );
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    required this.color,
    required this.title,
    required this.when,
    this.detail,
  });
  final Color color;
  final String title;
  final String when;
  final String? detail;
  @override
  Widget build(BuildContext context) => _Surface(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 52,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 3),
              Text(
                when,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (detail?.isNotEmpty == true)
                Text(
                  detail!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _PageHeading extends StatelessWidget {
  const _PageHeading({required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.displaySmall
            ?.copyWith(fontWeight: FontWeight.w900, height: .98),
      ),
      if (subtitle?.isNotEmpty == true) ...[
        const SizedBox(height: 8),
        Text(
          subtitle!,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    ],
  );
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => _Surface(
    child: Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 14),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _TinyBadge extends StatelessWidget {
  const _TinyBadge({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
    ),
  );
}

class _StatusRing extends StatelessWidget {
  const _StatusRing({
    required this.online,
    required this.total,
    required this.healthy,
  });
  final int online;
  final int total;
  final bool healthy;
  @override
  Widget build(BuildContext context) => Container(
    width: 76,
    height: 76,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: healthy ? _mint : _coral, width: 8),
    ),
    alignment: Alignment.center,
    child: Text(
      '$online',
      style: Theme.of(context).textTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w900),
    ),
  );
}

class _Aura extends StatelessWidget {
  const _Aura({required this.size, required this.color});
  final double size;
  final Color color;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: .25), color.withValues(alpha: 0)],
        ),
      ),
    ),
  );
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.message,
    required this.error,
    required this.onClose,
  });
  final String message;
  final bool error;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 4, 20, 4),
    padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
    decoration: BoxDecoration(
      color: (error ? _coral : _mint).withValues(alpha: .18),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        IconButton(
          onPressed: onClose,
          icon: const Icon(Icons.close_rounded),
          visualDensity: VisualDensity.compact,
        ),
      ],
    ),
  );
}

class _Loading extends StatelessWidget {
  const _Loading({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _Aura(size: 180, color: _violet),
          const SizedBox(height: 18),
          const CircularProgressIndicator(),
          const SizedBox(height: 18),
          Text(label),
        ],
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.message,
    required this.retry,
    required this.disconnect,
  });
  final String message;
  final VoidCallback retry;
  final VoidCallback disconnect;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 60),
              const SizedBox(height: 18),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: retry,
                child: Text(AppLocalizations.of(context).tryAgain),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: disconnect,
                child: Text(AppLocalizations.of(context).disconnect),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<void> _addReminder(BuildContext context, HomeController home) async {
  await _showReminderEditor(context, home, null);
}

Future<void> _showCalendarEditor(
  BuildContext context,
  HomeController home,
  MobileCalendarEvent? event,
  DateTime selected,
  DateTime rangeFrom,
  DateTime rangeTo,
) async {
  final l10n = AppLocalizations.of(context);
  final summary = TextEditingController(text: event?.summary ?? '');
  final location = TextEditingController(text: event?.location ?? '');
  var allDay = event?.allDay ?? false;
  var start =
      event?.start.toLocal() ??
      DateTime(selected.year, selected.month, selected.day, 9);
  var end = event?.end.toLocal() ?? start.add(const Duration(hours: 1));

  Future<DateTime?> choose(DateTime value) async {
    final date = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !context.mounted) return null;
    if (allDay) return DateTime(date.year, date.month, date.day);
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setModalState) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          4,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              event == null ? l10n.addCalendarEvent : l10n.editCalendarEvent,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: summary,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.eventTitle),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: location,
              decoration: InputDecoration(
                labelText: l10n.eventLocation,
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.allDay),
              value: allDay,
              onChanged: (value) => setModalState(() {
                allDay = value;
                if (allDay) {
                  start = _day(start);
                  end = _day(start).add(const Duration(days: 1));
                }
              }),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final chosen = await choose(start);
                if (chosen != null) setModalState(() => start = chosen);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(
                '${l10n.eventStarts}: ${_formatWhen(context, start, allDay: allDay)}',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final chosen = await choose(end);
                if (chosen != null) setModalState(() => end = chosen);
              },
              icon: const Icon(Icons.stop_rounded),
              label: Text(
                '${l10n.eventEnds}: ${_formatWhen(context, end, allDay: allDay)}',
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                if (event != null)
                  IconButton.filledTonal(
                    tooltip: l10n.delete,
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: sheetContext,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.deleteCalendarEventTitle),
                          content: Text(
                            l10n.deleteCalendarEventBody(event.summary),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l10n.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(l10n.delete),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true || !sheetContext.mounted) return;
                      Navigator.pop(sheetContext);
                      await home.deleteCalendarEvent(event, rangeFrom, rangeTo);
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                if (event != null) const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      if (summary.text.trim().isEmpty || !end.isAfter(start)) {
                        return;
                      }
                      Navigator.pop(sheetContext);
                      await home.saveCalendarEvent(
                        existing: event,
                        summary: summary.text,
                        location: location.text,
                        start: start,
                        end: end,
                        allDay: allDay,
                        rangeFrom: rangeFrom,
                        rangeTo: rangeTo,
                      );
                    },
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 300));
  summary.dispose();
  location.dispose();
}

Future<void> _editReminder(
  BuildContext context,
  HomeController home,
  MobileReminder reminder,
) async {
  await _showReminderEditor(context, home, reminder);
}

Future<void> _showReminderEditor(
  BuildContext context,
  HomeController home,
  MobileReminder? reminder,
) async {
  final l10n = AppLocalizations.of(context);
  final title = TextEditingController(text: reminder?.title ?? '');
  var at =
      reminder?.at.toLocal() ?? DateTime.now().add(const Duration(hours: 1));
  var repeat = reminder?.repeat ?? 'none';
  const standardRepeats = {
    'none',
    'hourly',
    'daily',
    'weekly',
    'monthly',
    'yearly',
  };
  final custom = RegExp(r'^every:(\d+):(hour|day|week|month|year)$')
      .firstMatch(repeat);
  var repeatMode = standardRepeats.contains(repeat) ? repeat : 'custom';
  var repeatCount = int.tryParse(custom?.group(1) ?? '') ?? 2;
  var repeatUnit = custom?.group(2) ?? 'day';
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setModalState) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          4,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              reminder == null ? l10n.addReminder : l10n.editReminder,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(hintText: l10n.reminderTitleHint),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final day = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                  initialDate: at,
                );
                if (day == null || !context.mounted) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(at),
                );
                if (time == null) return;
                setModalState(
                  () => at = DateTime(
                    day.year,
                    day.month,
                    day.day,
                    time.hour,
                    time.minute,
                  ),
                );
              },
              icon: const Icon(Icons.schedule_rounded),
              label: Text('${l10n.dateAndTime}: ${_formatWhen(context, at)}'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: repeatMode,
              decoration: InputDecoration(labelText: l10n.repeat),
              items:
                  [
                        ('none', l10n.repeatNone),
                        ('hourly', l10n.repeatHourly),
                        ('daily', l10n.repeatDaily),
                        ('weekly', l10n.repeatWeekly),
                        ('monthly', l10n.repeatMonthly),
                        ('yearly', l10n.repeatYearly),
                        ('custom', l10n.repeatFlexible),
                      ]
                      .map(
                        (item) => DropdownMenuItem(
                          value: item.$1,
                          child: Text(item.$2),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setModalState(() {
                repeatMode = value ?? 'none';
                if (repeatMode != 'custom') repeat = repeatMode;
              }),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              child: repeatMode != 'custom'
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Expanded(child: Text(l10n.repeatEvery)),
                          SizedBox(
                            width: 76,
                            child: TextFormField(
                              initialValue: '$repeatCount',
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(isDense: true),
                              onChanged: (value) => repeatCount =
                                  (int.tryParse(value) ?? 2).clamp(1, 365),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: repeatUnit,
                              isExpanded: true,
                              items:
                                  [
                                        ('hour', l10n.repeatUnitHour),
                                        ('day', l10n.repeatUnitDay),
                                        ('week', l10n.repeatUnitWeek),
                                        ('month', l10n.repeatUnitMonth),
                                        ('year', l10n.repeatUnitYear),
                                      ]
                                      .map(
                                        (item) => DropdownMenuItem(
                                          value: item.$1,
                                          child: Text(item.$2),
                                        ),
                                      )
                                      .toList(),
                              onChanged: (value) => repeatUnit = value ?? 'day',
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                if (title.text.trim().isEmpty) return;
                if (repeatMode == 'custom') {
                  repeat = 'every:${repeatCount.clamp(1, 365)}:$repeatUnit';
                }
                Navigator.pop(context);
                if (reminder == null) {
                  await home.createReminder(title.text, at, repeat);
                } else {
                  await home.updateReminder(reminder, title.text, at, repeat);
                }
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    ),
  );
  await Future<void>.delayed(const Duration(milliseconds: 300));
  title.dispose();
}

Future<bool> _confirmDeleteReminder(
  BuildContext context,
  MobileReminder reminder,
) async {
  final l10n = AppLocalizations.of(context);
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.deleteReminderTitle),
          content: Text(l10n.deleteReminderBody(reminder.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.delete),
            ),
          ],
        ),
      ) ??
      false;
}

Future<void> _confirmClearCompleted(
  BuildContext context,
  HomeController home,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.clearCompletedTitle),
      content: Text(l10n.clearCompletedBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.clearCompleted),
        ),
      ],
    ),
  );
  if (confirmed == true) await home.deleteCompletedReminders();
}

String _repeatLabel(AppLocalizations l10n, String repeat) => switch (repeat) {
  'hourly' => l10n.repeatHourly,
  'daily' => l10n.repeatDaily,
  'weekly' => l10n.repeatWeekly,
  'monthly' => l10n.repeatMonthly,
  'yearly' => l10n.repeatYearly,
  'none' => l10n.repeatNone,
  _ => _customRepeatLabel(l10n, repeat),
};

String _customRepeatLabel(AppLocalizations l10n, String repeat) {
  final match = RegExp(r'^every:(\d+):(hour|day|week|month|year)$')
      .firstMatch(repeat);
  if (match == null) return l10n.customRepeat(repeat);
  final unit = switch (match.group(2)) {
    'hour' => l10n.repeatUnitHour,
    'day' => l10n.repeatUnitDay,
    'week' => l10n.repeatUnitWeek,
    'month' => l10n.repeatUnitMonth,
    _ => l10n.repeatUnitYear,
  };
  return l10n.repeatInterval(int.parse(match.group(1)!), unit);
}

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

bool _sameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

DateTime _rangeStart(DateTime month) =>
    DateTime(month.year, month.month, 1).subtract(const Duration(days: 7));

DateTime _rangeEnd(DateTime month) =>
    DateTime(month.year, month.month + 2, 1).add(const Duration(days: 7));

(String, DateTime, bool)? _nextItem(MobileOverview overview) {
  final candidates = <(String, DateTime, bool)>[
    ...overview.reminders
        .where((item) => !item.done && !item.at.isBefore(DateTime.now()))
        .map((item) => (item.title, item.at, false)),
    ...overview.calendar.events.map(
      (item) => (item.summary, item.start, item.allDay),
    ),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
  return candidates.firstOrNull;
}

String _formatWhen(BuildContext context, DateTime raw, {bool allDay = false}) {
  final date = raw.toLocal();
  final now = DateTime.now();
  final day = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  final l10n = AppLocalizations.of(context);
  final label = day == today
      ? l10n.today
      : day == today.add(const Duration(days: 1))
      ? l10n.tomorrow
      : MaterialLocalizations.of(context).formatMediumDate(date);
  return allDay
      ? '$label · ${l10n.allDay}'
      : '$label · ${TimeOfDay.fromDateTime(date).format(context)}';
}

String _bytesPerSecond(int value) {
  if (value >= 1024 * 1024) {
    return '${(value / 1024 / 1024).toStringAsFixed(1)} MB/s';
  }
  if (value >= 1024) return '${(value / 1024).toStringAsFixed(0)} KB/s';
  return '$value B/s';
}

String _formatBytes(int value) {
  if (value >= 1024 * 1024) {
    return '${(value / 1024 / 1024).toStringAsFixed(1)} MB';
  }
  if (value >= 1024) return '${(value / 1024).toStringAsFixed(0)} KB';
  return '$value B';
}
