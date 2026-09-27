import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../core/settings/module_visibility_preferences.dart';
import '../../link/mobile_models.dart';
import '../connection/connection_controller.dart';
import 'home_controller.dart';

const _moduleViolet = Color(0xff68789f);
const _moduleCoral = Color(0xffbd765b);
const _moduleMint = Color(0xff4f9b77);
const _moduleGold = Color(0xffbd9547);

enum _ModuleKind {
  notifications,
  devices,
  telegram,
  smartHome,
  automations,
  security,
  settings,
}

final class HomeModulesPage extends StatefulWidget {
  const HomeModulesPage({
    required this.overview,
    required this.connection,
    required this.home,
    required this.onOpenSettings,
    super.key,
  });

  final MobileOverview overview;
  final ConnectionController connection;
  final HomeController home;
  final VoidCallback onOpenSettings;

  @override
  State<HomeModulesPage> createState() => _HomeModulesPageState();
}

class _HomeModulesPageState extends State<HomeModulesPage> {
  static const modules = [
    _ModuleKind.notifications,
    _ModuleKind.devices,
    _ModuleKind.telegram,
    _ModuleKind.smartHome,
    _ModuleKind.automations,
    _ModuleKind.security,
    _ModuleKind.settings,
  ];

  late final ModuleVisibilityPreferences visibility =
      ModuleVisibilityPreferences(modules.map((kind) => kind.name).toList());

  @override
  void initState() {
    super.initState();
    visibility.addListener(_onVisibilityChanged);
    visibility.initialize();
  }

  void _onVisibilityChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    visibility.removeListener(_onVisibilityChanged);
    visibility.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = <(String, List<_ModuleKind>)>[
      (l10n.everydaySection, const [_ModuleKind.notifications]),
      (l10n.sharingSection, const [_ModuleKind.devices]),
      (
        l10n.servicesSection,
        const [_ModuleKind.telegram, _ModuleKind.smartHome],
      ),
      (
        l10n.systemSection,
        const [
          _ModuleKind.automations,
          _ModuleKind.security,
          _ModuleKind.settings,
        ],
      ),
    ];
    final visibleSections = sections
        .map(
          (section) => (
            section.$1,
            section.$2
                .where((kind) => visibility.isVisible(kind.name))
                .toList(growable: false),
          ),
        )
        .where((section) => section.$2.isNotEmpty)
        .toList(growable: false);

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar.large(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                systemOverlayStyle:
                    Theme.of(context).brightness == Brightness.dark
                    ? SystemUiOverlayStyle.light
                    : SystemUiOverlayStyle.dark,
                title: Text(l10n.allSections),
                actions: [
                  IconButton(
                    tooltip: l10n.customizeSections,
                    onPressed: () => _showCustomize(context),
                    icon: const Icon(Icons.tune_rounded),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 42),
                sliver: SliverList.list(
                  children: [
                    _WorkspaceHero(connection: widget.connection),
                    const SizedBox(height: 18),
                    Text(
                      l10n.allSectionsBody,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 26),
                    if (visibleSections.isEmpty)
                      _InfoPanel(
                        icon: Icons.tune_rounded,
                        text: l10n.hiddenSectionsEmpty,
                      ),
                    for (final section in visibleSections) ...[
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 3,
                            color: _spec(l10n, section.$2.first).color,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            section.$1,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text('${section.$2.length}'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 600) {
                            return Material(
                              color: Colors.transparent,
                              child: Column(
                                children: [
                                  for (
                                    var index = 0;
                                    index < section.$2.length;
                                    index++
                                  ) ...[
                                    if (index > 0) const SizedBox(height: 8),
                                    _ModuleRow(
                                      key: ValueKey(
                                        'module-row-${section.$2[index].name}',
                                      ),
                                      spec: _spec(l10n, section.$2[index]),
                                      onTap: () =>
                                          _open(context, section.$2[index]),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }
                          final width = (constraints.maxWidth - 10) / 2;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: section.$2
                                .map(
                                  (kind) => SizedBox(
                                    width: width,
                                    child: _ModuleCard(
                                      key: ValueKey('module-card-${kind.name}'),
                                      spec: _spec(l10n, kind),
                                      onTap: () => _open(context, kind),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showCustomize(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.customizeSections,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(l10n.customizeSectionsBody),
                ],
              ),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: visibility,
                builder: (context, _) => ListView.builder(
                  itemCount: modules.length,
                  itemBuilder: (context, index) {
                    final kind = modules[index];
                    final spec = _spec(l10n, kind);
                    return SwitchListTile.adaptive(
                      key: ValueKey('module-toggle-${kind.name}'),
                      secondary: _IconTile(icon: spec.icon, color: spec.color),
                      title: Text(spec.title),
                      value: visibility.isVisible(kind.name),
                      onChanged: (value) =>
                          visibility.setVisible(kind.name, value),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: TextButton.icon(
                onPressed: visibility.reset,
                icon: const Icon(Icons.restart_alt_rounded),
                label: Text(l10n.restoreSections),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, _ModuleKind kind) {
    if (kind == _ModuleKind.settings) {
      widget.onOpenSettings();
      return;
    }
    final page = switch (kind) {
      _ModuleKind.devices => _DevicesModulePage(overview: widget.overview),
      _ModuleKind.notifications => _NotificationsModulePage(
        connection: widget.connection,
      ),
      _ModuleKind.telegram => _TelegramModulePage(
        overview: widget.overview,
        home: widget.home,
      ),
      _ModuleKind.automations => const _AutomationsModulePage(),
      _ModuleKind.smartHome => const _SmartHomeModulePage(),
      _ModuleKind.security => _SecurityModulePage(
        overview: widget.overview,
        connection: widget.connection,
      ),
      _ => null,
    };
    if (page != null) {
      Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
    }
  }
}

final class _ModuleSpec {
  const _ModuleSpec({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.live,
  });
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final bool live;
}

_ModuleSpec _spec(AppLocalizations l10n, _ModuleKind kind) => switch (kind) {
  _ModuleKind.notifications => _ModuleSpec(
    title: l10n.notificationHistory,
    body: l10n.notificationsModuleBody,
    icon: Icons.notifications_active_outlined,
    color: _moduleCoral,
    live: true,
  ),
  _ModuleKind.devices => _ModuleSpec(
    title: l10n.devicesTitle,
    body: l10n.devicesBody,
    icon: Icons.devices_other_rounded,
    color: _moduleMint,
    live: true,
  ),
  _ModuleKind.telegram => _ModuleSpec(
    title: l10n.telegramTitle,
    body: l10n.telegramModuleBody,
    icon: Icons.send_rounded,
    color: _moduleViolet,
    live: true,
  ),
  _ModuleKind.smartHome => _ModuleSpec(
    title: l10n.smartHomeTitle,
    body: l10n.smartHomeBody,
    icon: Icons.home_work_outlined,
    color: _moduleMint,
    live: false,
  ),
  _ModuleKind.automations => _ModuleSpec(
    title: l10n.automationsTitle,
    body: l10n.automationsBody,
    icon: Icons.bolt_rounded,
    color: _moduleGold,
    live: false,
  ),
  _ModuleKind.security => _ModuleSpec(
    title: l10n.securityCenter,
    body: l10n.securityCenterBody,
    icon: Icons.shield_outlined,
    color: _moduleViolet,
    live: true,
  ),
  _ModuleKind.settings => _ModuleSpec(
    title: l10n.settings,
    body: l10n.settingsModuleBody,
    icon: Icons.tune_rounded,
    color: _moduleCoral,
    live: true,
  ),
};

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.spec, required this.onTap, super.key});

  final _ModuleSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      child: Material(
        color: spec.color.withValues(alpha: .12),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(17, 15, 12, 15),
              child: Row(
                children: [
                  _IconTile(icon: spec.icon, color: spec.color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spec.title,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          spec.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                        if (!spec.live) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.preview,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right_rounded, color: spec.color),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.spec, required this.onTap, super.key});
  final _ModuleSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Material(
      color: spec.color.withValues(alpha: .12),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(28),
        topRight: Radius.circular(10),
        bottomLeft: Radius.circular(10),
        bottomRight: Radius.circular(28),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 178),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _IconTile(icon: spec.icon, color: spec.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _StatusChip(
                          text: spec.live ? l10n.availableNow : l10n.preview,
                          color: spec.live ? _moduleMint : _moduleGold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  spec.title,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  spec.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.arrow_outward_rounded, color: spec.color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspaceHero extends StatelessWidget {
  const _WorkspaceHero({required this.connection});
  final ConnectionController connection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = connection.profile;
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 18),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.hub_rounded, color: _moduleViolet, size: 29),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.privateWorkspace,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  profile?.serverName ?? l10n.appName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            profile?.secure == true
                ? Icons.verified_user_rounded
                : Icons.warning_amber_rounded,
            color: profile?.secure == true ? _moduleMint : _moduleGold,
          ),
        ],
      ),
    );
  }
}

class _DevicesModulePage extends StatelessWidget {
  const _DevicesModulePage({required this.overview});
  final MobileOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _DetailScaffold(
      title: l10n.devicesTitle,
      subtitle: l10n.devicesBody,
      icon: Icons.devices_other_rounded,
      color: _moduleMint,
      children: [
        _SummaryBand(
          values: [
            (
              '${overview.shareTargets.where((item) => item.online).length}',
              l10n.onlineNow,
            ),
            ('${overview.shareTargets.length}', l10n.shareCapableDevices),
          ],
        ),
        const SizedBox(height: 22),
        _SectionTitle(l10n.shareCapableDevices),
        const SizedBox(height: 10),
        if (overview.shareTargets.isEmpty)
          _InfoPanel(
            icon: Icons.devices_other_rounded,
            text: l10n.noLinkedDevices,
          )
        else
          ...overview.shareTargets.map(
            (device) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _IconTile(
                            icon: device.platform == 'android'
                                ? Icons.android_rounded
                                : Icons.devices_rounded,
                            color: device.online ? _moduleMint : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  device.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  device.ownedByCurrentUser
                                      ? l10n.yourDevice
                                      : l10n.householdDevice(
                                          device.ownerName ?? l10n.appName,
                                        ),
                                ),
                              ],
                            ),
                          ),
                          _StatusChip(
                            text: device.online
                                ? l10n.deviceOnline
                                : l10n.deviceOffline,
                            color: device.online ? _moduleMint : Colors.grey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        l10n.capabilities,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (device.supportsText)
                            const Chip(label: Text('text.receive')),
                          if (device.supportsUrl)
                            const Chip(label: Text('url.open')),
                          if (device.supportsFile)
                            const Chip(label: Text('file.receive')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationsModulePage extends StatelessWidget {
  const _NotificationsModulePage({required this.connection});
  final ConnectionController connection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: connection,
      builder: (context, _) => _DetailScaffold(
        title: l10n.notificationHistory,
        subtitle: l10n.notificationsModuleBody,
        icon: Icons.notifications_active_outlined,
        color: _moduleCoral,
        trailing: connection.notificationHistory.isEmpty
            ? null
            : TextButton(
                onPressed: connection.clearNotificationHistory,
                child: Text(l10n.clearHistory),
              ),
        children: [
          _InfoPanel(
            icon: Icons.lock_outline_rounded,
            text: l10n.notificationHistoryPrivacy,
          ),
          const SizedBox(height: 14),
          if (connection.notificationHistory.isEmpty)
            _InfoPanel(
              icon: Icons.notifications_none_rounded,
              text: l10n.noRecentEvents,
            )
          else
            ...connection.notificationHistory.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 9),
                child: ListTile(
                  leading: const _IconTile(
                    icon: Icons.notifications_rounded,
                    color: _moduleCoral,
                  ),
                  title: Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    item.body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    MaterialLocalizations.of(context).formatTimeOfDay(
                      TimeOfDay.fromDateTime(item.receivedAt.toLocal()),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AutomationsModulePage extends StatelessWidget {
  const _AutomationsModulePage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _DetailScaffold(
      title: l10n.automationsTitle,
      subtitle: l10n.automationsBody,
      icon: Icons.bolt_rounded,
      color: _moduleGold,
      badge: l10n.preview,
      children: [
        _PreviewNotice(text: l10n.plannedServerApi),
        const SizedBox(height: 16),
        _AutomationRow(
          icon: Icons.home_rounded,
          trigger: l10n.automationArrival,
          action: l10n.automationArrivalAction,
        ),
        _AutomationRow(
          icon: Icons.downloading_rounded,
          trigger: l10n.automationDownload,
          action: l10n.automationDownloadAction,
        ),
        _AutomationRow(
          icon: Icons.battery_alert_rounded,
          trigger: l10n.automationBattery,
          action: l10n.automationBatteryAction,
        ),
        const SizedBox(height: 14),
        _InfoPanel(icon: Icons.policy_outlined, text: l10n.automationSafety),
      ],
    );
  }
}

class _TelegramModulePage extends StatelessWidget {
  const _TelegramModulePage({required this.overview, required this.home});

  final MobileOverview overview;
  final HomeController home;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: home,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      final available =
          overview.telegram.enabled &&
          overview.permissions.contains('telegram.send');
      return _DetailScaffold(
        title: l10n.telegramTitle,
        subtitle: l10n.telegramModuleBody,
        icon: Icons.send_rounded,
        color: _moduleViolet,
        children: [
          _InfoPanel(
            icon: Icons.hub_outlined,
            text: overview.telegram.enabled
                ? l10n.telegramConnected
                : l10n.telegramDisconnected,
          ),
          if (!available) ...[
            const SizedBox(height: 12),
            Text(l10n.permissionsRequired),
          ],
          if (available) ...[
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: home.busyId == 'telegram' ? null : home.testTelegram,
              icon: home.busyId == 'telegram'
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(l10n.telegramTest),
            ),
          ],
          if (home.error != null) ...[
            const SizedBox(height: 16),
            SelectableText(home.error!),
          ],
        ],
      );
    },
  );
}

class _SmartHomeModulePage extends StatelessWidget {
  const _SmartHomeModulePage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _DetailScaffold(
      title: l10n.smartHomeTitle,
      subtitle: l10n.smartHomeBody,
      icon: Icons.home_work_outlined,
      color: _moduleMint,
      badge: l10n.preview,
      children: [
        SegmentedButton<int>(
          segments: [
            ButtonSegment(
              value: 0,
              label: Text(l10n.rooms),
              icon: const Icon(Icons.meeting_room_outlined),
            ),
            ButtonSegment(
              value: 1,
              label: Text(l10n.scenes),
              icon: const Icon(Icons.auto_awesome_outlined),
            ),
            ButtonSegment(
              value: 2,
              label: Text(l10n.sensors),
              icon: const Icon(Icons.sensors_outlined),
            ),
          ],
          selected: const {0},
          onSelectionChanged: (_) {},
          showSelectedIcon: false,
        ),
        const SizedBox(height: 18),
        _InfoPanel(
          icon: Icons.add_home_work_outlined,
          text: l10n.smartHomeEmpty,
        ),
        const SizedBox(height: 12),
        FilledButton.tonalIcon(
          onPressed: null,
          icon: const Icon(Icons.open_in_browser_rounded),
          label: Text(l10n.configureOnServer),
        ),
      ],
    );
  }
}

class _SecurityModulePage extends StatelessWidget {
  const _SecurityModulePage({required this.overview, required this.connection});
  final MobileOverview overview;
  final ConnectionController connection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = connection.profile;
    return _DetailScaffold(
      title: l10n.securityCenter,
      subtitle: l10n.securityCenterBody,
      icon: Icons.shield_outlined,
      color: _moduleViolet,
      children: [
        _SecurityRow(
          icon: Icons.fingerprint_rounded,
          title: l10n.verifiedIdentity,
          body: l10n.verifiedIdentityBody,
          detail: profile?.serverId,
        ),
        _SecurityRow(
          icon: Icons.group_off_outlined,
          title: l10n.accountIsolation,
          body: l10n.accountIsolationBody,
        ),
        _SecurityRow(
          icon: Icons.rule_rounded,
          title: l10n.explicitCapabilities,
          body: l10n.explicitCapabilitiesBody,
        ),
        const SizedBox(height: 18),
        _SectionTitle(l10n.capabilities),
        const SizedBox(height: 8),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: (overview.permissions.toList()..sort())
              .map((permission) => Chip(label: Text(permission)))
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _DetailScaffold extends StatelessWidget {
  const _DetailScaffold({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.children,
    this.badge,
    this.trailing,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Widget> children;
  final String? badge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      actions: [?trailing],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 30),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .13),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(42),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(42),
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8,
                top: -22,
                child: Icon(
                  icon,
                  size: 132,
                  color: color.withValues(alpha: .18),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(width: 44, height: 4, color: color),
                  const SizedBox(height: 25),
                  Icon(icon, size: 38, color: color),
                  const SizedBox(height: 25),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (badge != null) ...[
                    const SizedBox(height: 10),
                    _StatusChip(text: badge!, color: _moduleGold),
                  ],
                  const SizedBox(height: 9),
                  Text(subtitle, style: const TextStyle(height: 1.35)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        ...children,
      ],
    ),
  );
}

class _SummaryBand extends StatelessWidget {
  const _SummaryBand({required this.values});
  final List<(String, String)> values;

  @override
  Widget build(BuildContext context) => Row(
    children: values
        .map(
          (item) => Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      item.$1,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .toList(growable: false),
  );
}

class _AutomationRow extends StatelessWidget {
  const _AutomationRow({
    required this.icon,
    required this.trigger,
    required this.action,
  });
  final IconData icon;
  final String trigger;
  final String action;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _IconTile(icon: icon, color: _moduleGold),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trigger,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.arrow_forward_rounded, size: 15),
                    const SizedBox(width: 5),
                    Expanded(child: Text(action)),
                  ],
                ),
              ],
            ),
          ),
          Switch(value: false, onChanged: null),
        ],
      ),
    ),
  );
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.icon,
    required this.title,
    required this.body,
    this.detail,
  });
  final IconData icon;
  final String title;
  final String body;
  final String? detail;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(icon: icon, color: _moduleViolet),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(body),
                if (detail != null) ...[
                  const SizedBox(height: 8),
                  SelectableText(
                    detail!,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: _moduleMint),
        ],
      ),
    ),
  );
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(17),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
      ],
    ),
  );
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _moduleGold.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        const Icon(Icons.construction_rounded, color: _moduleGold),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    ),
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.titleMedium
        ?.copyWith(fontWeight: FontWeight.w900),
  );
}

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .16),
      borderRadius: BorderRadius.circular(14),
    ),
    alignment: Alignment.center,
    child: Icon(icon, color: color),
  );
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
    ),
  );
}
