import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../link/mobile_models.dart';
import '../connection/connection_controller.dart';

const _moduleViolet = Color(0xff829eff);
const _moduleCoral = Color(0xffff746c);
const _moduleMint = Color(0xff70e1b4);
const _moduleGold = Color(0xffffc857);

enum _ModuleKind {
  plan,
  notifications,
  devices,
  clipboard,
  transfers,
  media,
  telegram,
  smartHome,
  monitoring,
  automations,
  security,
  settings,
}

final class HomeModulesPage extends StatelessWidget {
  const HomeModulesPage({
    required this.overview,
    required this.connection,
    required this.onOpenTab,
    required this.onOpenSettings,
    super.key,
  });

  final MobileOverview overview;
  final ConnectionController connection;
  final ValueChanged<int> onOpenTab;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sections = <(String, List<_ModuleKind>)>[
      (
        l10n.everydaySection,
        const [_ModuleKind.plan, _ModuleKind.notifications],
      ),
      (
        l10n.sharingSection,
        const [
          _ModuleKind.devices,
          _ModuleKind.clipboard,
          _ModuleKind.transfers,
        ],
      ),
      (
        l10n.servicesSection,
        const [_ModuleKind.media, _ModuleKind.telegram, _ModuleKind.smartHome],
      ),
      (
        l10n.systemSection,
        const [
          _ModuleKind.monitoring,
          _ModuleKind.automations,
          _ModuleKind.security,
          _ModuleKind.settings,
        ],
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          const Positioned(
            right: -110,
            top: -100,
            child: _Glow(color: _moduleViolet, size: 300),
          ),
          const Positioned(
            left: -130,
            bottom: -80,
            child: _Glow(color: _moduleCoral, size: 280),
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar.large(
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                title: Text(l10n.allSections),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 42),
                sliver: SliverList.list(
                  children: [
                    _WorkspaceHero(connection: connection),
                    const SizedBox(height: 18),
                    Text(
                      l10n.allSectionsBody,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 26),
                    for (final section in sections) ...[
                      Text(
                        section.$1.toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              letterSpacing: 1.7,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = (constraints.maxWidth - 10) / 2;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: section.$2
                                .map(
                                  (kind) => SizedBox(
                                    width: width,
                                    child: _ModuleCard(
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

  void _open(BuildContext context, _ModuleKind kind) {
    final tab = switch (kind) {
      _ModuleKind.plan => 1,
      _ModuleKind.clipboard => 0,
      _ModuleKind.transfers => 3,
      _ModuleKind.media => 2,
      _ModuleKind.telegram => 0,
      _ModuleKind.monitoring => 4,
      _ => null,
    };
    if (tab != null) {
      Navigator.pop(context);
      onOpenTab(tab);
      return;
    }
    if (kind == _ModuleKind.settings) {
      Navigator.pop(context);
      onOpenSettings();
      return;
    }
    final page = switch (kind) {
      _ModuleKind.devices => _DevicesModulePage(overview: overview),
      _ModuleKind.notifications => _NotificationsModulePage(
        connection: connection,
      ),
      _ModuleKind.automations => const _AutomationsModulePage(),
      _ModuleKind.smartHome => const _SmartHomeModulePage(),
      _ModuleKind.security => _SecurityModulePage(
        overview: overview,
        connection: connection,
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
  _ModuleKind.plan => _ModuleSpec(
    title: l10n.calendarTitle,
    body: l10n.calendarModuleBody,
    icon: Icons.event_note_rounded,
    color: _moduleViolet,
    live: true,
  ),
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
  _ModuleKind.clipboard => _ModuleSpec(
    title: l10n.clipboardTitle,
    body: l10n.clipboardModuleBody,
    icon: Icons.content_paste_go_rounded,
    color: _moduleGold,
    live: true,
  ),
  _ModuleKind.transfers => _ModuleSpec(
    title: l10n.transfersTitle,
    body: l10n.transfersModuleBody,
    icon: Icons.swap_horiz_rounded,
    color: _moduleViolet,
    live: true,
  ),
  _ModuleKind.media => _ModuleSpec(
    title: l10n.requestsTitle,
    body: l10n.mediaModuleBody,
    icon: Icons.movie_filter_outlined,
    color: _moduleCoral,
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
  _ModuleKind.monitoring => _ModuleSpec(
    title: l10n.monitoringTitle,
    body: l10n.monitoringModuleBody,
    icon: Icons.monitor_heart_outlined,
    color: _moduleMint,
    live: true,
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

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.spec, required this.onTap});
  final _ModuleSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: EdgeInsets.zero,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _moduleViolet.withValues(alpha: .24),
            _moduleCoral.withValues(alpha: .12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _moduleViolet.withValues(alpha: .22)),
      ),
      child: Row(
        children: [
          const _IconTile(icon: Icons.hub_rounded, color: _moduleViolet),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.privateWorkspace,
                  style: const TextStyle(fontWeight: FontWeight.w900),
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
    appBar: AppBar(title: Text(title), actions: [?trailing]),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconTile(icon: icon, color: color),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                        if (badge != null)
                          _StatusChip(text: badge!, color: _moduleGold),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(subtitle, style: const TextStyle(height: 1.35)),
                  ],
                ),
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

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: .18), Colors.transparent],
        ),
      ),
    ),
  );
}
