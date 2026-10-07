import 'dart:async';
import 'dart:io';

import 'device_platform_icon.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../core/background/background_delivery.dart';
import '../../core/branding/brand_mark.dart';
import '../../core/settings/app_preferences.dart';
import '../../core/platform/android_system_actions.dart';
import '../../core/storage/transfer_activity_store.dart';
import '../../link/mobile_models.dart';
import '../../core/sharing/share_service.dart';
import '../connection/connection_controller.dart';
import '../exchange/text_exchange_card.dart';
import '../exchange/file_exchange_card.dart';
import '../exchange/device_file_selection.dart';
import '../exchange/transfer_compose_bar.dart';
import '../media/media_catalog_view.dart';
import '../ideas/idea_controller.dart';
import '../ideas/idea_store.dart';
import '../ideas/server_idea_store.dart';
import '../ideas/ideas_view.dart';
import 'home_controller.dart';
import 'home_modules.dart';
import '../plants/plant_controller.dart';
import '../plants/plant_store.dart';
import '../plants/synced_plant_repository.dart';
import '../plants/plants_view.dart';

const _violet = Color(0xff829eff);
const _coral = Color(0xffff746c);
const _mint = Color(0xff70e1b4);
const _ink = Color(0xff11111b);

class HomeShell extends StatefulWidget {
  const HomeShell({
    required this.connection,
    this.homeController,
    this.ideaController,
    this.preferences,
    super.key,
  });
  final ConnectionController connection;
  final HomeController? homeController;
  final IdeaController? ideaController;
  final AppPreferences? preferences;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  late final HomeController home =
      widget.homeController ??
      HomeController(sessionProvider: widget.connection.authenticatedSession);
  late final bool ownsHome = widget.homeController == null;
  late final PlantController? plants = widget.connection.profile == null
      ? null
      : PlantController(
          PlantStore(widget.connection.profile!),
          repository: SyncedPlantRepository(
            profile: widget.connection.profile!,
            local: PlantStore(widget.connection.profile!),
            sessionProvider: widget.connection.authenticatedSession,
            canUseServer: () =>
                home.overview?.permissions.contains('plants.manage') ?? false,
          ),
        );
  late final IdeaController? ideas =
      widget.ideaController ??
      (widget.connection.profile == null
          ? null
          : IdeaController(
              ProfileIdeaStore(
                local: SecureIdeaStore(widget.connection.profile!),
                server: ServerIdeaStore(
                  profile: widget.connection.profile!,
                  sessionProvider: widget.connection.authenticatedSession,
                  localStore: SecureIdeaStore(widget.connection.profile!),
                ),
                canUseServer: () =>
                    home.overview?.permissions.contains('ideas.manage') ??
                    false,
              ),
            ));
  late final bool ownsIdeas = widget.ideaController == null;
  int _seenIdeaOverviewRevision = 0;
  int _seenPlantOverviewRevision = 0;
  final ValueNotifier<_PlanSection> planSection = ValueNotifier(
    _PlanSection.calendar,
  );
  static const _shortcutChannel = MethodChannel(
    'com.homeplace.mobile/navigation',
  );
  String? _pendingShortcut;
  late final PageController pages;
  final Set<String> _automaticIncoming = {};
  bool _sendingShareBatch = false;
  bool _shareTargetSheetOpen = false;
  bool _preparingDirectFiles = false;
  String? _directFileError;
  String? _presentedOutgoingBatch;
  late int tab;
  late final ValueNotifier<int> selectedTab;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    tab = widget.connection.pendingOutgoingShares.isEmpty ? 0 : 3;
    selectedTab = ValueNotifier(tab);
    pages = PageController(initialPage: tab);
    home.addListener(_refreshIdeasAccess);
    home.bindClipboardReader(widget.connection.readClipboardTextForAutoRelay);
    if (ownsHome) {
      unawaited(home.initialize().then((_) => ideas?.load()));
    } else {
      ideas?.load();
    }
    plants?.load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openPendingPlantNotification());
    });
    if (Platform.isAndroid) {
      _shortcutChannel.setMethodCallHandler((call) async {
        if (call.method == 'shortcutOpened') await _takeShortcut();
      });
      unawaited(_takeShortcut());
    }
  }

  void _refreshIdeasAccess() {
    final plantController = plants;
    if (plantController != null &&
        home.overviewRevision != _seenPlantOverviewRevision) {
      _seenPlantOverviewRevision = home.overviewRevision;
      unawaited(plantController.sync());
    }
    final controller = ideas;
    if (controller == null || controller.loading || controller.busy) return;
    final allowed =
        home.overview?.permissions.contains('ideas.manage') ?? false;
    if (controller.serverSynced != allowed ||
        (allowed && home.overviewRevision != _seenIdeaOverviewRevision)) {
      _seenIdeaOverviewRevision = home.overviewRevision;
      unawaited(controller.load());
    }
  }

  Future<void> _takeShortcut() async {
    try {
      final destination = await _shortcutChannel.invokeMethod<String>(
        'takePendingDestination',
      );
      if (mounted && destination != null) {
        setState(() => _pendingShortcut = destination);
      }
    } on PlatformException {
      // A launcher shortcut must never block the regular connection flow.
    }
  }

  void _routeShortcut() {
    if (_pendingShortcut == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !pages.hasClients) return;
      final destination = _pendingShortcut;
      _pendingShortcut = null;
      if (destination == 'ideas' && ideas != null) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        planSection.value = _PlanSection.ideas;
        _selectTab(1);
        pages.jumpToPage(1);
      } else if (destination == 'transfers') {
        Navigator.of(context).popUntil((route) => route.isFirst);
        _selectTab(3);
        pages.jumpToPage(3);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    home.removeListener(_refreshIdeasAccess);
    if (Platform.isAndroid) {
      _shortcutChannel.setMethodCallHandler(null);
    }
    pages.dispose();
    if (ownsHome) home.dispose();
    plants?.dispose();
    if (ownsIdeas) ideas?.dispose();
    planSection.dispose();
    selectedTab.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    home.setForeground(state == AppLifecycleState.resumed);
    if (state == AppLifecycleState.resumed) {
      unawaited(_openPendingPlantNotification());
      unawaited(widget.connection.refreshEvents());
      if (plants != null) unawaited(plants!.load());
    }
  }

  Future<void> _openPendingPlantNotification() async {
    final plantController = plants;
    if (plantController == null) return;
    final id = await widget.connection.takePlantNavigation();
    if (id == null || !mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PlantsPage(
          controller: plantController,
          initialPlantId: id.isEmpty ? null : id,
        ),
      ),
    );
  }

  void _selectTab(int value) {
    if (tab == value) return;
    tab = value;
    selectedTab.value = value;
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([home, widget.connection]),
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      final outgoing = widget.connection.pendingOutgoingShares;
      final requested = widget.connection.pendingIncomingShares
          .where((offer) => offer.acceptRequested)
          .where((offer) => !_automaticIncoming.contains(offer.eventId))
          .firstOrNull;
      if (requested != null) {
        _automaticIncoming.add(requested.eventId);
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          if (requested.kind == SharedContentKind.file) {
            await home.acceptSharedFile(requested, widget.connection);
          } else {
            await home.acceptIncomingTextOrUrl(requested, widget.connection);
          }
        });
      }
      if (home.loading && home.overview == null) {
        return _Loading(label: outgoing.isEmpty ? null : l10n.preparingShare);
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
      _routeShortcut();
      _routeOutgoingShare(overview, outgoing);
      return Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            Positioned.fill(
              child: ValueListenableBuilder<int>(
                valueListenable: selectedTab,
                builder: (context, currentTab, _) => AnimatedContainer(
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xff0b0d14)
                      : switch (currentTab) {
                          1 => const Color(0xfff8f1e9),
                          2 => const Color(0xfff1f3ee),
                          3 => const Color(0xfff8f3e5),
                          4 => const Color(0xffeff4f1),
                          _ => const Color(0xfff7f3e9),
                        },
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: selectedTab,
                    builder: (context, currentTab, _) => _TopBar(
                      serverName:
                          widget.connection.profile?.serverName ?? l10n.appName,
                      planTitle: currentTab == 1 ? l10n.calendarTab : null,
                      planDescription: currentTab == 1
                          ? l10n.calendarModuleBody
                          : null,
                      refreshing: home.refreshing,
                      hasError: home.error != null,
                      onRefresh: home.refresh,
                      onError: home.error == null
                          ? null
                          : () => _showCurrentError(context, l10n),
                    ),
                  ),
                  if (home.notice case final notice?)
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
                      actionLabel:
                          notice.startsWith('file:') &&
                              home.lastSavedFile != null
                          ? l10n.open
                          : null,
                      onAction:
                          notice.startsWith('file:') &&
                              home.lastSavedFile != null
                          ? () => home.openLastSavedFile(widget.connection)
                          : null,
                      onClose: home.clearMessage,
                    ),
                  if (widget.connection.pendingOutgoingShares.isNotEmpty)
                    _OutgoingShareBanner(
                      contents: widget.connection.pendingOutgoingShares,
                      onCancel: widget.connection.clearAllOutgoingShares,
                      onChoose: () => _showShareTargets(
                        context,
                        overview,
                        List.of(widget.connection.pendingOutgoingShares),
                      ),
                    ),
                  Expanded(
                    child: PageView(
                      controller: pages,
                      onPageChanged: _selectTab,
                      children: [
                        _OverviewPage(
                          overview: overview,
                          home: home,
                          connection: widget.connection,
                          plants: plants,
                          onOpenPlan: () {
                            _selectTab(1);
                            pages.animateToPage(
                              1,
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                            );
                          },
                        ),
                        _PlanPage(
                          overview: overview,
                          home: home,
                          plants: plants,
                          ideas: ideas,
                          selection: planSection,
                        ),
                        _RequestsPage(overview: overview, home: home),
                        _TransfersPage(
                          home: home,
                          connection: widget.connection,
                          preparingFiles: _preparingDirectFiles,
                          fileError: _directFileError,
                          onPickPhotos: () =>
                              _pickDirectFiles(context, photosOnly: true),
                          onPickFiles: () =>
                              _pickDirectFiles(context, photosOnly: false),
                          onOpenFolder: _openDownloadsFolder,
                          onChooseOutgoing: () => _showShareTargets(
                            context,
                            overview,
                            List.of(widget.connection.pendingOutgoingShares),
                          ),
                        ),
                        _MonitorPage(overview: overview, home: home),
                      ].map((page) => _RetainedPage(child: page)).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: ValueListenableBuilder<int>(
          valueListenable: selectedTab,
          builder: (context, currentTab, _) => _PillNavigation(
            index: currentTab,
            transferCount:
                widget.connection.pendingOutgoingShares.length +
                widget.connection.pendingIncomingShares.length,
            onChanged: (value) {
              _selectTab(value);
              pages.jumpToPage(value);
            },
            onMore: () => _showModules(context, overview),
          ),
        ),
      );
    },
  );

  Future<void> _showCurrentError(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final raw = home.error;
    if (raw == null) return;
    final message = raw == 'clipboard_empty'
        ? l10n.clipboardEmpty
        : raw == 'clipboard_no_devices'
        ? l10n.clipboardNoDevices
        : raw;
    final dismiss = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline_rounded, color: _coral),
        title: Text(l10n.errorDetails),
        content: SelectableText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.close),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.dismissError),
          ),
        ],
      ),
    );
    if (dismiss == true) home.clearMessage();
  }

  Future<void> _showModules(BuildContext context, MobileOverview overview) =>
      Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (routeContext) => HomeModulesPage(
            overview: overview,
            connection: widget.connection,
            home: home,
            onOpenSettings: () {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _showSettings(
                    this.context,
                    AppLocalizations.of(this.context),
                  );
                }
              });
            },
          ),
        ),
      );

  void _routeOutgoingShare(
    MobileOverview overview,
    List<SharedContent> outgoing,
  ) {
    if (outgoing.isEmpty) {
      _presentedOutgoingBatch = null;
      return;
    }
    final signature = outgoing
        .map(
          (item) => switch (item.kind) {
            SharedContentKind.file =>
              'file:${item.path}:${item.filename}:${item.size}',
            SharedContentKind.url => 'url:${item.value}',
            SharedContentKind.text => 'text:${item.value}',
          },
        )
        .join('|');
    final shouldPresent =
        !_shareTargetSheetOpen && _presentedOutgoingBatch != signature;
    if (shouldPresent) _presentedOutgoingBatch = signature;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (tab != 3) {
        _selectTab(3);
        if (pages.hasClients) {
          await pages.animateToPage(
            3,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
          );
        }
      }
      if (!mounted || _shareTargetSheetOpen || !shouldPresent) {
        return;
      }
      _shareTargetSheetOpen = true;
      try {
        await _showShareTargets(context, overview, List.of(outgoing));
      } finally {
        _shareTargetSheetOpen = false;
      }
    });
  }

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
            widget.connection,
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
              if (Platform.isAndroid && widget.preferences != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: widget.preferences!.seamlessOwnAccountTransfersEnabled,
                  onChanged:
                      widget.preferences!.setSeamlessOwnAccountTransfersEnabled,
                  title: Text(l10n.seamlessOwnAccountTransfers),
                  subtitle: Text(l10n.seamlessOwnAccountTransfersBody),
                  secondary: const Icon(Icons.devices_rounded),
                ),
              if (Platform.isAndroid)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: widget.preferences?.backgroundDeliveryEnabled ?? false,
                  onChanged: widget.preferences == null
                      ? null
                      : (enabled) async {
                          if (enabled &&
                              !await widget.connection
                                  .requestNotificationPermission()) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.notificationPermissionRequired,
                                  ),
                                ),
                              );
                            }
                            return;
                          }
                          await widget.preferences!
                              .setBackgroundDeliveryEnabled(enabled);
                        },
                  title: Text(l10n.backgroundDelivery),
                  subtitle: Text(l10n.backgroundDeliveryBody),
                  secondary: const Icon(Icons.notifications_active_outlined),
                ),
              if (Platform.isAndroid &&
                  widget.preferences?.backgroundDeliveryEnabled == true)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value:
                      widget.preferences?.backgroundIncomingOffersEnabled ??
                      false,
                  onChanged:
                      widget.preferences?.setBackgroundIncomingOffersEnabled,
                  title: Text(l10n.backgroundIncomingOffers),
                  subtitle: Text(l10n.backgroundIncomingOffersBody),
                  secondary: const Icon(Icons.move_to_inbox_outlined),
                ),
              if (Platform.isAndroid) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.dashboard_customize_outlined),
                  title: Text(l10n.quickTransferTile),
                  subtitle: Text(l10n.quickTransferTileBody),
                  onTap: () async {
                    final result = await const AndroidSystemActions()
                        .requestTransferTile();
                    if (!context.mounted) return;
                    final message = switch (result) {
                      TransferTileResult.added => l10n.quickTransferTileAdded,
                      TransferTileResult.alreadyAdded =>
                        l10n.quickTransferTileAlreadyAdded,
                      TransferTileResult.notAdded =>
                        l10n.quickTransferTileNotAdded,
                      TransferTileResult.unavailable =>
                        l10n.quickTransferTileUnavailable,
                    };
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(message)));
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(l10n.androidNotificationSettings),
                  subtitle: Text(l10n.androidNotificationSettingsBody),
                  onTap: () =>
                      const AndroidSystemActions().openNotificationSettings(),
                ),
              ],
              if (Platform.isAndroid &&
                  widget.preferences?.backgroundDeliveryEnabled == true)
                FutureBuilder<BackgroundDeliveryStatus?>(
                  future: const BackgroundDeliveryStatusStore().read(),
                  builder: (context, snapshot) {
                    final status = snapshot.data;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.schedule_rounded),
                      title: Text(l10n.lastBackgroundCheck),
                      subtitle: Text(
                        status == null
                            ? l10n.backgroundNeverRun
                            : status.successfulProfiles < 0
                            ? l10n.backgroundCheckFailed(
                                _formatWhen(context, status.lastRunAt),
                              )
                            : l10n.backgroundCheckedProfiles(
                                _formatWhen(context, status.lastRunAt),
                                status.successfulProfiles,
                              ),
                      ),
                    );
                  },
                ),
              FutureBuilder<PackageInfo>(
                future: PackageInfo.fromPlatform(),
                builder: (context, snapshot) {
                  final package = snapshot.data;
                  if (package == null) return const SizedBox.shrink();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.system_update_alt_rounded),
                    title: Text(l10n.appVersion),
                    subtitle: Text(
                      '${package.version} (${package.buildNumber})',
                    ),
                  );
                },
              ),
              const Divider(height: 28),
              Text(
                l10n.homePlaceProfiles,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...widget.connection.profiles.map((profile) {
                final selected =
                    profile.serverId == widget.connection.profile?.serverId;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.dns_outlined,
                    ),
                    title: Text(profile.serverName),
                    subtitle: Text(
                      profile.preferredUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: selected
                        ? Text(l10n.activeProfile)
                        : const Icon(Icons.chevron_right_rounded),
                    onTap: selected
                        ? null
                        : () async {
                            Navigator.pop(context);
                            await widget.connection.switchProfile(profile);
                          },
                  ),
                );
              }),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  widget.connection.useAnotherAddress();
                },
                icon: const Icon(Icons.add_link_rounded),
                label: Text(l10n.connectAnotherHomePlace),
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

  Future<void> _openDownloadsFolder() async {
    final opened = await const AndroidSystemActions().openDownloadsFolder();
    if (!opened && mounted) {
      setState(
        () =>
            _directFileError = AppLocalizations.of(context)
                .downloadsFolderUnavailable,
      );
    }
  }

  Future<void> _pickDirectFiles(
    BuildContext context, {
    required bool photosOnly,
  }) async {
    if (_preparingDirectFiles) return;
    final serverId = widget.connection.profile?.serverId;
    setState(() {
      _preparingDirectFiles = true;
      _directFileError = null;
    });
    try {
      final files = await pickDeviceFiles(photosOnly: photosOnly);
      if (!mounted || files.isEmpty) return;
      if (widget.connection.profile?.serverId != serverId) {
        for (final content in files) {
          final path = content.path;
          if (path != null) await File(path).delete();
        }
        return;
      }
      widget.connection.queueOutgoingShares(files);
    } on Object {
      if (mounted) {
        setState(() {
          _directFileError = AppLocalizations.of(context).fileExchangePickError;
        });
      }
    } finally {
      if (mounted) setState(() => _preparingDirectFiles = false);
    }
  }

  Future<void> _showShareTargets(
    BuildContext context,
    MobileOverview overview,
    List<SharedContent> contents,
  ) async {
    if (contents.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final targets =
        overview.shareTargets
            .where(
              (target) => contents.every(
                (content) => switch (content.kind) {
                  SharedContentKind.text => target.supportsText,
                  SharedContentKind.url => target.supportsUrl,
                  SharedContentKind.file => target.supportsFile,
                },
              ),
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
                    leading: DevicePlatformIcon(platform: target.platform),
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
                      if (_sendingShareBatch) return;
                      final confirmed = await showDialog<bool>(
                        context: sheetContext,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(l10n.confirmShareTitle),
                          content: Text(
                            contents.length > 1 && !target.ownedByCurrentUser
                                ? l10n.confirmMultipleHouseholdShareBody(
                                    contents.length,
                                    target.ownerName ?? l10n.appName,
                                    target.name,
                                  )
                                : contents.length > 1
                                ? l10n.confirmMultipleShareBody(
                                    contents.length,
                                    target.name,
                                  )
                                : target.ownedByCurrentUser
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
                      if (confirmed != true || !mounted || _sendingShareBatch) {
                        return;
                      }
                      _sendingShareBatch = true;
                      var allSent = true;
                      try {
                        for (final content in contents) {
                          final sent = await home.sendSharedContent(
                            target,
                            content,
                          );
                          if (!sent) {
                            allSent = false;
                            break;
                          }
                          widget.connection.clearOutgoingShare(content);
                        }
                      } finally {
                        _sendingShareBatch = false;
                      }
                      if (allSent && sheetContext.mounted) {
                        Navigator.pop(sheetContext);
                      }
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
    required this.contents,
    required this.onCancel,
    required this.onChoose,
  });
  final List<SharedContent> contents;
  final VoidCallback onCancel;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content = contents.first;
    final label = contents.length > 1
        ? l10n.itemsReadyToShare(contents.length)
        : switch (content.kind) {
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
    required this.planTitle,
    required this.planDescription,
    required this.refreshing,
    required this.hasError,
    required this.onRefresh,
    required this.onError,
  });
  final String serverName;
  final String? planTitle;
  final String? planDescription;
  final bool refreshing;
  final bool hasError;
  final VoidCallback onRefresh;
  final VoidCallback? onError;

  Widget _logo(BuildContext context) => Container(
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
  );

  List<Widget> _actions(BuildContext context) => [
    if (hasError)
      IconButton.filledTonal(
        tooltip: AppLocalizations.of(context).errorDetails,
        onPressed: onError,
        style: IconButton.styleFrom(
          foregroundColor: _coral,
          backgroundColor: _coral.withValues(alpha: .14),
        ),
        icon: const Icon(Icons.error_outline_rounded),
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
  ];

  @override
  Widget build(BuildContext context) {
    final title = planTitle;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 14, 8),
      child: title == null
          ? Row(
              children: [
                _logo(context),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    serverName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                ..._actions(context),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 82,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _logo(context),
                      const SizedBox(height: 8),
                      Tooltip(
                        message: serverName,
                        child: Text(
                          serverName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                          ),
                          ..._actions(context),
                        ],
                      ),
                      if (planDescription case final description?)
                        Text(
                          description,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                                height: 1.25,
                              ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _OverviewPage extends StatelessWidget {
  const _OverviewPage({
    required this.overview,
    required this.home,
    required this.connection,
    required this.plants,
    required this.onOpenPlan,
  });
  final MobileOverview overview;
  final HomeController home;
  final ConnectionController connection;
  final PlantController? plants;
  final VoidCallback onOpenPlan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final next = _nextItem(overview);
    final missingPermissions = !overview.permissions.contains('dashboard.read');
    return _ScrollPage(
      onRefresh: home.refresh,
      children: [
        _PageHeading(
          title: l10n.everythingInPlace,
          subtitle: l10n.homeOverviewBody,
        ),
        const SizedBox(height: 22),
        if (plants != null) PlantsHomeSection(controller: plants!),
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
              child: Text(
                l10n.nextUp,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton.icon(
              onPressed: onOpenPlan,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(l10n.calendarTab),
            ),
          ],
        ),
        const SizedBox(height: 10),
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
        const SizedBox(height: 110),
      ],
    );
  }
}

class _TransfersPage extends StatelessWidget {
  const _TransfersPage({
    required this.home,
    required this.connection,
    required this.preparingFiles,
    required this.fileError,
    required this.onPickPhotos,
    required this.onPickFiles,
    required this.onOpenFolder,
    required this.onChooseOutgoing,
  });

  final HomeController home;
  final ConnectionController connection;
  final bool preparingFiles;
  final String? fileError;
  final VoidCallback onPickPhotos;
  final VoidCallback onPickFiles;
  final VoidCallback onOpenFolder;
  final VoidCallback onChooseOutgoing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final outgoing = connection.pendingOutgoingShares;
    final incoming = connection.pendingIncomingShares;
    final empty =
        outgoing.isEmpty &&
        incoming.isEmpty &&
        connection.pendingClipboard == null;
    return _ScrollPage(
      onRefresh: () async {
        await Future.wait([home.refresh(), connection.refreshEvents()]);
      },
      children: [
        _PageHeading(
          title: l10n.transfersTitle,
          subtitle: l10n.transfersSubtitle,
          accentColor: const Color(0xffaf843b),
        ),
        const SizedBox(height: 22),
        if (Platform.isAndroid) ...[
          TransferComposeBar(
            preparing: preparingFiles,
            onPhotos: onPickPhotos,
            onFiles: onPickFiles,
          ),
          if (fileError != null) ...[
            const SizedBox(height: 8),
            Text(
              fileError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 22),
        ],
        if (home.lastSavedFile case final saved?) ...[
          _SavedFileCard(
            file: saved,
            onOpen: () => home.openLastSavedFile(connection),
            onOpenFolder: onOpenFolder,
          ),
          const SizedBox(height: 18),
        ],
        if (empty)
          _EmptyCard(
            icon: Icons.swap_vert_circle_outlined,
            text: l10n.noPendingTransfers,
          ),
        if (incoming.isNotEmpty) ...[
          Text(
            l10n.incomingOffers(incoming.length),
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          ...incoming.map(
            (offer) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _IncomingShareCard(
                offer: offer,
                receiving: home.activeFileTransferId == offer.eventId,
                progress: home.activeFileTransferId == offer.eventId
                    ? home.fileTransferProgress
                    : null,
                onDismiss: home.activeFileTransferId == offer.eventId
                    ? home.cancelFileTransfer
                    : () => connection.dismissIncomingShare(offer),
                onAccept: offer.kind == SharedContentKind.file
                    ? () => home.acceptSharedFile(offer, connection)
                    : () => home.acceptIncomingTextOrUrl(offer, connection),
              ),
            ),
          ),
        ],
        if (outgoing.isNotEmpty) ...[
          if (incoming.isNotEmpty) const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.outgoingItems(outgoing.length),
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: home.busyId == 'share' ? null : onChooseOutgoing,
                icon: const Icon(Icons.send_rounded),
                label: Text(l10n.chooseDevice),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (home.activeFileTransferId == 'outgoing') ...[
            LinearProgressIndicator(value: home.fileTransferProgress),
            const SizedBox(height: 10),
          ],
          ...outgoing.map(
            (content) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OutgoingQueueCard(
                content: content,
                onRemove: () => connection.clearOutgoingShare(content),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        FileExchangeCard(
          key: ValueKey(
            'file-exchange-${connection.profile?.serverId}-${connection.profile?.deviceId}',
          ),
          sessionProvider: connection.authenticatedSession,
          available: home.overview?.permissions.contains('share.relay') == true,
          clipboardRelayEnabled: home.autoClipboardEnabled,
        ),
        if (Platform.isAndroid &&
            home.overview?.permissions.contains('clipboard.relay') == true) ...[
          const SizedBox(height: 18),
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
        if (home.transferActivity.isNotEmpty) ...[
          const SizedBox(height: 12),
          _TransferActivityCard(home: home, limit: 20),
        ],
        if (connection.notificationHistory.isNotEmpty) ...[
          const SizedBox(height: 12),
          _NotificationHistoryCard(connection: connection),
        ],
        const SizedBox(height: 12),
        TextExchangeCard(
          key: ValueKey(
            'exchange-${connection.profile?.serverId}-${connection.profile?.deviceId}',
          ),
          sessionProvider: connection.authenticatedSession,
          available: home.overview?.permissions.contains('share.relay') == true,
          clipboardRelayEnabled: home.autoClipboardEnabled,
        ),
        const SizedBox(height: 110),
      ],
    );
  }
}

class _SavedFileCard extends StatelessWidget {
  const _SavedFileCard({
    required this.file,
    required this.onOpen,
    required this.onOpenFolder,
  });

  final SavedSharedFile file;
  final VoidCallback onOpen;
  final VoidCallback onOpenFolder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      label: l10n.savedFileActions(file.filename),
      child: Material(
        color: theme.colorScheme.secondaryContainer.withValues(alpha: .55),
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onOpen,
          onLongPress: onOpenFolder,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.download_done_rounded),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.savedFileReady,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            file.filename,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: Text(l10n.open),
                    ),
                    TextButton.icon(
                      onPressed: onOpenFolder,
                      icon: const Icon(Icons.folder_open_rounded),
                      label: Text(l10n.openDownloadsFolder),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutgoingQueueCard extends StatelessWidget {
  const _OutgoingQueueCard({required this.content, required this.onRemove});

  final SharedContent content;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final detail = switch (content.kind) {
      SharedContentKind.file =>
        '${content.filename} · ${_formatBytes(content.size ?? 0)}',
      SharedContentKind.url => content.value ?? '',
      SharedContentKind.text => content.value ?? '',
    };
    final icon = switch (content.kind) {
      SharedContentKind.file => Icons.insert_drive_file_rounded,
      SharedContentKind.url => Icons.link_rounded,
      SharedContentKind.text => Icons.notes_rounded,
    };
    return _Surface(
      color: _coral.withValues(alpha: .08),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          _RoundIcon(icon: icon, color: _coral),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.waitingToSend,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.remove,
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _NotificationHistoryCard extends StatelessWidget {
  const _NotificationHistoryCard({required this.connection});
  final ConnectionController connection;

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
                  l10n.notificationHistory,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              if (connection.notificationHistory.length > 5)
                TextButton(
                  onPressed: () => _showAll(context),
                  child: Text(l10n.viewAll),
                ),
              TextButton(
                onPressed: connection.clearNotificationHistory,
                child: Text(l10n.clearHistory),
              ),
            ],
          ),
          Text(
            l10n.notificationHistoryPrivacy,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...connection.notificationHistory
              .take(5)
              .map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: const Icon(
                    Icons.notifications_none_rounded,
                    color: _violet,
                  ),
                  title: Text(item.title),
                  subtitle: Text(
                    '${item.body}\n${_formatWhen(context, item.receivedAt)}',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> _showAll(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .7,
        maxChildSize: .92,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              AppLocalizations.of(context).notificationHistory,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            ...connection.notificationHistory.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_none_rounded),
                title: Text(item.title),
                subtitle: Text(
                  '${item.body}\n${_formatWhen(context, item.receivedAt)}',
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TransferActivityCard extends StatelessWidget {
  const _TransferActivityCard({required this.home, this.limit = 5});
  final HomeController home;
  final int limit;

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
          ...home.transferActivity.take(limit).map((activity) {
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
    required this.progress,
    required this.onDismiss,
    required this.onAccept,
  });
  final PendingShareOffer offer;
  final bool receiving;
  final double? progress;
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
          if (receiving) ...[
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              progress == null
                  ? l10n.preparingFiles
                  : '${(progress! * 100).round()}%',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onDismiss,
                  child: Text(receiving ? l10n.cancel : l10n.decline),
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

enum _PlanSection { calendar, reminders, plants, ideas }

class _PlanPage extends StatefulWidget {
  const _PlanPage({
    required this.overview,
    required this.home,
    required this.plants,
    required this.ideas,
    required this.selection,
  });
  final MobileOverview overview;
  final HomeController home;
  final PlantController? plants;
  final IdeaController? ideas;
  final ValueNotifier<_PlanSection> selection;

  @override
  State<_PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<_PlanPage> {
  late DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  late DateTime selected = _day(DateTime.now());
  late _PlanSection section = widget.selection.value;

  MobileOverview get overview => widget.overview;
  HomeController get home => widget.home;

  @override
  void initState() {
    super.initState();
    widget.selection.addListener(_onSelectionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMonth());
  }

  void _onSelectionChanged() {
    if (!mounted) return;
    setState(() => section = widget.selection.value);
  }

  @override
  void dispose() {
    widget.selection.removeListener(_onSelectionChanged);
    super.dispose();
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
    final sections = <(_PlanSection, String, IconData)>[
      (_PlanSection.calendar, l10n.calendarTitle, Icons.calendar_month_rounded),
      (
        _PlanSection.reminders,
        l10n.remindersTitle,
        Icons.notifications_outlined,
      ),
      if (widget.plants != null)
        (_PlanSection.plants, l10n.plantsTitle, Icons.spa_outlined),
      if (widget.ideas != null)
        (_PlanSection.ideas, l10n.ideasTitle, Icons.lightbulb_outline_rounded),
    ];
    return _ScrollPage(
      onRefresh: _refresh,
      children: [
        Row(
          children: [
            for (var index = 0; index < sections.length; index++) ...[
              if (index > 0) const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  label: sections[index].$2,
                  selected: section == sections[index].$1,
                  button: true,
                  child: Tooltip(
                    message: sections[index].$2,
                    excludeFromSemantics: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        widget.selection.value = sections[index].$1;
                      },
                      child: AnimatedContainer(
                        key: ValueKey('plan-mode-${sections[index].$1.name}'),
                        height: 56,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        decoration: BoxDecoration(
                          color: section == sections[index].$1
                              ? Theme.of(context).colorScheme.primary
                                    .withValues(alpha: .19)
                              : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerLow
                                    .withValues(alpha: .72),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: section == sections[index].$1
                                ? Theme.of(context).colorScheme.primary
                                      .withValues(alpha: .38)
                                : Theme.of(context).colorScheme.outlineVariant
                                      .withValues(alpha: .28),
                          ),
                        ),
                        child: Icon(sections[index].$3, size: 25),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        if (section == _PlanSection.calendar) ...[
          if (overview.calendar.email case final email?) ...[
            Text(
              email,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
          ],
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
        ],
        if (section == _PlanSection.plants && widget.plants != null)
          PlantsPlanSection(controller: widget.plants!),
        if (section == _PlanSection.ideas && widget.ideas != null)
          IdeasWorkspace(
            controller: widget.ideas!,
            canMakeReminder: overview.permissions.contains('reminder.manage'),
            clipboardRelayEnabled: home.autoClipboardEnabled,
            onMakeReminder: (text) =>
                _showReminderEditor(context, home, null, draftTitle: text),
          ),
        if (section == _PlanSection.reminders) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.remindersTitle,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              IconButton.filledTonal(
                onPressed: overview.permissions.contains('reminder.manage')
                    ? () => _addReminder(context, home)
                    : null,
                icon: const Icon(Icons.add_rounded),
                tooltip: l10n.addReminder,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (overview.reminders.isEmpty)
            _EmptyCard(
              icon: Icons.notifications_none_rounded,
              text: l10n.nothingPlanned,
            ),
          if (overdue.isNotEmpty) ...[
            _ReminderSectionTitle(
              title: l10n.overdueReminders,
              count: overdue.length,
              color: _coral,
            ),
            ...overdue.map(
              (item) =>
                  _ReminderCard(reminder: item, home: home, overdue: true),
            ),
          ],
          if (upcoming.isNotEmpty) ...[
            if (overdue.isNotEmpty) const SizedBox(height: 12),
            _ReminderSectionTitle(
              title: l10n.upcomingReminders,
              count: upcoming.length,
            ),
            ...upcoming.map(
              (item) => _ReminderCard(reminder: item, home: home),
            ),
          ],
          if (completed.isNotEmpty) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              key: const ValueKey('completed-reminders'),
              tilePadding: EdgeInsets.zero,
              title: Text(
                '${l10n.completedReminders} · ${completed.length}',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: home.busyId == 'completed-reminders'
                        ? null
                        : () => _confirmClearCompleted(context, home),
                    child: Text(l10n.clearCompleted),
                  ),
                ),
                ...completed.map(
                  (item) => _ReminderCard(reminder: item, home: home),
                ),
              ],
            ),
          ],
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
  });
  final String title;
  final int count;
  final Color? color;

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
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
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
        _PageHeading(
          title: l10n.requestsTitle,
          subtitle: l10n.requestsBody,
          accentColor: const Color(0xff647d92),
        ),
        const SizedBox(height: 18),
        MediaCatalogView(
          sessionProvider: widget.home.sessionProvider,
          available: overview.permissions.contains('media.request'),
        ),
        const SizedBox(height: 18),
        ExpansionTile(
          title: Text(l10n.mediaAutomation),
          children: [
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
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
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  item.inLibrary
                                      ? l10n.inLibrary
                                      : l10n.request,
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
          ],
        ),
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
    final containers = monitor.containers;
    final latencies = monitor.services
        .map((service) => service.latencyMs)
        .whereType<int>()
        .toList(growable: false);
    final averageLatency = latencies.isEmpty
        ? null
        : latencies.reduce((a, b) => a + b) ~/ latencies.length;
    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: _PageHeading(
              title: l10n.monitoringTitle,
              subtitle: l10n.monitoringBody,
              accentColor: const Color(0xff4f8c7b),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: _violet.withValues(alpha: .22),
                  borderRadius: BorderRadius.circular(16),
                ),
                tabs: [
                  Tab(text: l10n.monitorOverviewTab),
                  Tab(text: l10n.monitorContainersTab),
                  Tab(text: l10n.monitorServicesTab),
                  Tab(text: l10n.monitorEventsTab),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ScrollPage(
                  onRefresh: home.refresh,
                  children: [
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
                                Text(
                                  l10n.onlineCount(
                                    monitor.online,
                                    monitor.total,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  l10n.monitoredChecksExplanation,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.cloud_done_rounded,
                            color: _mint,
                            value: '${monitor.online}',
                            label: l10n.onlineNow,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.cloud_off_rounded,
                            color: _coral,
                            value: '${monitor.offline}',
                            label: l10n.needsAttention,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.help_outline_rounded,
                            color: Colors.blueGrey,
                            value: '${monitor.unknown}',
                            label: l10n.unknownState,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.speed_rounded,
                            color: _violet,
                            value: averageLatency == null
                                ? '—'
                                : '$averageLatency ms',
                            label: l10n.averageLatency,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _Surface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            l10n.containerSummary,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _CompactMetric(
                                value: '${containers.total}',
                                label: l10n.totalContainers,
                                color: _violet,
                              ),
                              _CompactMetric(
                                value: '${containers.running}',
                                label: l10n.runningContainers,
                                color: _mint,
                              ),
                              _CompactMetric(
                                value: '${containers.problems}',
                                label: l10n.containerProblems,
                                color: containers.problems > 0 ? _coral : _mint,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 110),
                  ],
                ),
                _ScrollPage(
                  onRefresh: home.refresh,
                  children: [
                    if (containers.items.isEmpty)
                      _EmptyCard(
                        icon: Icons.developer_board_outlined,
                        text: l10n.noContainers,
                      )
                    else ...[
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              icon: Icons.play_circle_outline_rounded,
                              color: _mint,
                              value: '${containers.running}',
                              label: l10n.runningContainers,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              icon: Icons.stop_circle_outlined,
                              color: containers.stopped > 0
                                  ? _coral
                                  : Colors.blueGrey,
                              value: '${containers.stopped}',
                              label: l10n.stoppedContainers,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _Surface(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: containers.items
                              .map((container) {
                                final problem =
                                    container.state == 'restarting' ||
                                    container.state == 'dead' ||
                                    container.health == 'unhealthy';
                                final running = container.state == 'running';
                                return ListTile(
                                  leading: Container(
                                    width: 11,
                                    height: 11,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: problem
                                          ? _coral
                                          : running
                                          ? _mint
                                          : Colors.grey,
                                    ),
                                  ),
                                  title: Text(
                                    container.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${container.hostLabel} · ${container.image}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _containerState(l10n, container.state),
                                        style: TextStyle(
                                          color: problem
                                              ? _coral
                                              : running
                                              ? _mint
                                              : null,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (container.health != null)
                                        Text(
                                          container.health!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall,
                                        ),
                                    ],
                                  ),
                                );
                              })
                              .toList(growable: false),
                        ),
                      ),
                    ],
                    const SizedBox(height: 110),
                  ],
                ),
                _ScrollPage(
                  onRefresh: home.refresh,
                  children: [
                    if (monitor.services.isEmpty)
                      _EmptyCard(
                        icon: Icons.monitor_heart_outlined,
                        text: l10n.noMonitors,
                      )
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
                                  subtitle: service.checkedAt == null
                                      ? null
                                      : Text(
                                          l10n.lastChecked(
                                            _formatWhen(
                                              context,
                                              service.checkedAt!,
                                            ),
                                          ),
                                        ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _serviceState(l10n, service.status),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      Text(
                                        service.latencyMs == null
                                            ? '—'
                                            : '${service.latencyMs} ms',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    const SizedBox(height: 110),
                  ],
                ),
                _ScrollPage(
                  onRefresh: home.refresh,
                  children: [
                    if (monitor.recent.isEmpty)
                      _EmptyCard(
                        icon: Icons.history_rounded,
                        text: l10n.noRecentEvents,
                      )
                    else
                      ...monitor.recent.map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _AgendaRow(
                            color: event.severity == 'error' ? _coral : _violet,
                            title: event.count > 1
                                ? '${event.title} ×${event.count}'
                                : event.title,
                            when: _formatWhen(context, event.at),
                            detail: event.detail,
                          ),
                        ),
                      ),
                    const SizedBox(height: 110),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillNavigation extends StatelessWidget {
  const _PillNavigation({
    required this.index,
    required this.transferCount,
    required this.onChanged,
    required this.onMore,
  });
  final int index;
  final int transferCount;
  final ValueChanged<int> onChanged;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final navigationInk = dark ? Colors.white : const Color(0xff25352b);
    final items = [
      (Icons.space_dashboard_rounded, l10n.homeTab),
      (Icons.event_note_rounded, l10n.calendarTab),
      (Icons.add_to_queue_rounded, l10n.requestsTab),
      (Icons.swap_horiz_rounded, l10n.transfersTab),
      (Icons.monitor_heart_rounded, l10n.monitorTab),
    ];
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
      child: Container(
        height: 68,
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: dark
              ? const Color(0xff151824).withValues(alpha: .97)
              : const Color(0xfffffcf5),
          borderRadius: BorderRadius.circular(34),
          border: dark ? null : Border.all(color: const Color(0xffded9c9)),
          boxShadow: [
            BoxShadow(
              color: dark ? const Color(0x33000000) : const Color(0x142c3627),
              blurRadius: dark ? 24 : 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 330;
            return Row(
              children: [
                ...List.generate(items.length, (i) {
                  final selected = i == index;
                  return Expanded(
                    flex: selected && !compact ? 2 : 1,
                    child: Tooltip(
                      message: items[i].$2,
                      excludeFromSemantics: true,
                      child: Semantics(
                        selected: selected,
                        button: true,
                        label: items[i].$2,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(27),
                          onTap: () {
                            if (index != i) HapticFeedback.selectionClick();
                            onChanged(i);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            decoration: BoxDecoration(
                              color: selected
                                  ? (dark
                                        ? const Color(0xffa9bcff)
                                        : const Color(0xffdce9d7))
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(27),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      items[i].$1,
                                      size: 22,
                                      color: selected
                                          ? (dark
                                                ? const Color(0xff111521)
                                                : navigationInk)
                                          : navigationInk.withValues(
                                              alpha: .58,
                                            ),
                                    ),
                                    if (i == 3 && transferCount > 0)
                                      Positioned(
                                        right: -9,
                                        top: -7,
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            minWidth: 16,
                                            minHeight: 16,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _coral,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            transferCount > 9
                                                ? '9+'
                                                : '$transferCount',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                if (selected && !compact) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    items[i].$2,
                                    maxLines: 1,
                                    overflow: TextOverflow.fade,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: dark
                                          ? const Color(0xff111521)
                                          : navigationInk,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(width: 4),
                Container(
                  width: 48,
                  height: 54,
                  decoration: BoxDecoration(
                    color: dark
                        ? Colors.white.withValues(alpha: .10)
                        : const Color(0xffeee9dc),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: IconButton(
                    tooltip: l10n.allSections,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      onMore();
                    },
                    icon: Icon(Icons.grid_view_rounded, color: navigationInk),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RetainedPage extends StatefulWidget {
  const _RetainedPage({required this.child});

  final Widget child;

  @override
  State<_RetainedPage> createState() => _RetainedPageState();
}

class _RetainedPageState extends State<_RetainedPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
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
          (Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.surfaceContainerLow
                    .withValues(alpha: .92)
              : const Color(0xfffffcf5)),
      borderRadius: BorderRadius.circular(
        Theme.of(context).brightness == Brightness.dark ? 24 : 18,
      ),
      border: Border.all(
        color: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.outlineVariant
                  .withValues(alpha: .45)
            : const Color(0xffe9e3d5),
      ),
      boxShadow: Theme.of(context).brightness == Brightness.dark
          ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: .18),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ]
          : null,
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

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.value,
    required this.label,
    required this.color,
  });
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: color, fontWeight: FontWeight.w900),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall,
        ),
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
              .replaceAll(RegExp(r'\d+'), '')
              .replaceAll(RegExp(r'[,\.]'), '')
              .trim()
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
  const _PageHeading({required this.title, this.subtitle, this.accentColor});
  final String title;
  final String? subtitle;
  final Color? accentColor;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: accentColor ?? Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(height: 13),
      Text(
        title,
        style: Theme.of(context).textTheme.displaySmall
            ?.copyWith(fontWeight: FontWeight.w800),
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

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.message,
    required this.error,
    required this.onClose,
    this.actionLabel,
    this.onAction,
  });
  final String message;
  final bool error;
  final VoidCallback onClose;
  final String? actionLabel;
  final VoidCallback? onAction;
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
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
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
  final String? label;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HomePlaceMark(size: 54),
          const SizedBox(height: 18),
          const CircularProgressIndicator(),
          const SizedBox(height: 18),
          if (label != null) Text(label!),
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
  MobileReminder? reminder, {
  String? draftTitle,
}) async {
  final l10n = AppLocalizations.of(context);
  final title = TextEditingController(
    text:
        reminder?.title ??
        (draftTitle == null
            ? ''
            : draftTitle.length > 200
            ? draftTitle.substring(0, 200)
            : draftTitle),
  );
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

String _containerState(AppLocalizations l10n, String state) => switch (state) {
  'running' => l10n.containerRunning,
  'exited' => l10n.containerExited,
  'paused' => l10n.containerPaused,
  'restarting' => l10n.containerRestarting,
  'dead' => l10n.containerDead,
  'created' => l10n.containerCreated,
  _ => state,
};

String _serviceState(AppLocalizations l10n, String state) => switch (state) {
  'online' => l10n.serviceOnline,
  'offline' => l10n.serviceOffline,
  _ => l10n.unknownState,
};

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
