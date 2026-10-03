import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/sharing/share_service.dart';
import '../../link/link_client.dart';
import '../../link/mobile_api.dart';
import '../../link/mobile_models.dart';
import '../../l10n/generated/app_localizations.dart';
import '../connection/connection_controller.dart';
import '../home/device_platform_icon.dart';
import '../home/home_controller.dart';

typedef QuickShareTargetsLoader = Future<List<MobileShareTarget>> Function();
typedef QuickShareSender = Future<bool> Function(
  MobileShareTarget target,
  SharedContent content,
);

class QuickShareView extends StatefulWidget {
  const QuickShareView({
    required this.connection,
    this.targetsLoader,
    this.sender,
    this.onClose,
    super.key,
  });

  final ConnectionController connection;
  final QuickShareTargetsLoader? targetsLoader;
  final QuickShareSender? sender;
  final VoidCallback? onClose;

  @override
  State<QuickShareView> createState() => _QuickShareViewState();
}

class _QuickShareViewState extends State<QuickShareView> {
  late final HomeController _home;
  List<MobileShareTarget>? _targets;
  String? _targetError;
  bool _loadingTargets = false;
  bool _sending = false;
  int _sentCount = 0;
  String? _loadedServerId;

  @override
  void initState() {
    super.initState();
    _home = HomeController(
      sessionProvider: widget.connection.authenticatedSession,
    )..setForeground(false);
    _home.addListener(_refresh);
    widget.connection.addListener(_connectionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _connectionChanged());
  }

  @override
  void dispose() {
    widget.connection.removeListener(_connectionChanged);
    _home.removeListener(_refresh);
    _home.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _connectionChanged() {
    if (!mounted) return;
    final serverId = widget.connection.profile?.serverId;
    if (serverId != _loadedServerId) {
      _targets = null;
      _targetError = null;
      _loadedServerId = serverId;
    }
    if (widget.connection.stage == ConnectionStage.connected &&
        _targets == null &&
        !_loadingTargets) {
      unawaited(_loadTargets());
    }
    setState(() {});
  }

  Future<List<MobileShareTarget>> _loadFromServer() async {
    final session = await widget.connection.authenticatedSession();
    if (session == null) throw StateError('Secure connection is unavailable.');
    final response = await const MobileApi().shareTargets(session);
    if (response case LinkFailure<List<MobileShareTarget>> failure) {
      throw StateError(failure.message);
    }
    return (response as LinkSuccess<List<MobileShareTarget>>).value;
  }

  Future<void> _loadTargets() async {
    _loadingTargets = true;
    _targetError = null;
    setState(() {});
    final serverId = widget.connection.profile?.serverId;
    try {
      final targets = await (widget.targetsLoader?.call() ?? _loadFromServer())
          .timeout(const Duration(seconds: 20));
      if (!mounted || widget.connection.profile?.serverId != serverId) return;
      _targets = targets;
    } on Object catch (error) {
      if (!mounted) return;
      _targetError = error is StateError
          ? error.message
          : 'Could not load devices.';
    } finally {
      if (mounted) {
        _loadingTargets = false;
        setState(() {});
      }
    }
  }

  List<MobileShareTarget> _compatibleTargets(List<SharedContent> contents) {
    final targets = (_targets ?? const <MobileShareTarget>[])
        .where(
          (target) => contents.every(
            (content) => switch (content.kind) {
              SharedContentKind.text => target.supportsText,
              SharedContentKind.url => target.supportsUrl,
              SharedContentKind.file => target.supportsFile,
            },
          ),
        )
        .toList(growable: false);
    targets.sort((a, b) {
      final ownership = (b.ownedByCurrentUser ? 1 : 0).compareTo(
        a.ownedByCurrentUser ? 1 : 0,
      );
      if (ownership != 0) return ownership;
      final presence = (b.online ? 1 : 0).compareTo(a.online ? 1 : 0);
      if (presence != 0) return presence;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return targets;
  }

  Future<void> _confirmAndSend(MobileShareTarget target) async {
    if (_sending) return;
    final contents = List<SharedContent>.of(
      widget.connection.pendingOutgoingShares,
    );
    if (contents.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmShareTitle),
        content: Text(
          contents.length > 1 && !target.ownedByCurrentUser
              ? l10n.confirmMultipleHouseholdShareBody(
                  contents.length,
                  target.ownerName ?? l10n.appName,
                  target.name,
                )
              : contents.length > 1
              ? l10n.confirmMultipleShareBody(contents.length, target.name)
              : target.ownedByCurrentUser
              ? l10n.confirmShareBody(target.name)
              : l10n.confirmHouseholdShareBody(
                  target.ownerName ?? l10n.appName,
                  target.name,
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.send),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _sending = true;
    _sentCount = 0;
    setState(() {});
    try {
      for (final content in contents) {
        if (widget.connection.profile?.serverId != _loadedServerId) break;
        final sent =
            await (widget.sender?.call(target, content) ??
                _home.sendSharedContent(target, content));
        if (!mounted || !sent) break;
        widget.connection.clearOutgoingShare(content);
        _sentCount++;
      }
      if (mounted && widget.connection.pendingOutgoingShares.isEmpty) {
        _finish();
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _finish() {
    if (widget.onClose case final callback?) {
      callback();
    } else {
      unawaited(SystemNavigator.pop());
    }
  }

  void _cancel() {
    if (_sending) {
      _home.cancelFileTransfer();
      return;
    }
    widget.connection.clearAllOutgoingShares();
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final contents = widget.connection.pendingOutgoingShares;
    final targets = _compatibleTargets(contents);
    final connected = widget.connection.stage == ConnectionStage.connected;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.scrim.withValues(alpha: 0.55),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              margin: const EdgeInsets.all(18),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.ios_share_rounded, color: colors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.quickShareTitle,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.cancel,
                          onPressed: _cancel,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      contents.length == 1
                          ? switch (contents.first.kind) {
                              SharedContentKind.file =>
                                contents.first.filename ?? l10n.readyToShare,
                              _ => contents.first.value ?? l10n.readyToShare,
                            }
                          : l10n.itemsReadyToShare(contents.length),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 18),
                    Text(l10n.chooseDevice),
                    const SizedBox(height: 8),
                    if (_sending) ...[
                      LinearProgressIndicator(
                        value: _home.fileTransferProgress,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.itemsReadyToShare(contents.length - _sentCount),
                      ),
                    ] else if (!connected) ...[
                      Text(widget.connection.error ?? l10n.quickShareWaiting),
                      if (widget.connection.stage ==
                          ConnectionStage.reconnecting)
                        TextButton(
                          onPressed: widget.connection.retrySavedConnection,
                          child: Text(l10n.retry),
                        ),
                    ] else if (_loadingTargets) ...[
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(l10n.quickShareWaiting),
                    ] else if (_targetError != null) ...[
                      Text(_targetError!),
                      TextButton(
                        onPressed: _loadTargets,
                        child: Text(l10n.retry),
                      ),
                    ] else if (targets.isEmpty)
                      Text(l10n.noShareDevices)
                    else
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: targets.length,
                          itemBuilder: (context, index) {
                            final target = targets[index];
                            return ListTile(
                              leading: DevicePlatformIcon(
                                platform: target.platform,
                              ),
                              title: Text(target.name),
                              subtitle: Text(
                                target.ownedByCurrentUser
                                    ? l10n.yourDevice
                                    : l10n.householdDevice(
                                        target.ownerName ?? l10n.appName,
                                      ),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => _confirmAndSend(target),
                            );
                          },
                        ),
                      ),
                    if (_home.error case final error?) ...[
                      const SizedBox(height: 8),
                      Text(error, style: TextStyle(color: colors.error)),
                    ],
                    const SizedBox(height: 12),
                    TextButton(onPressed: _cancel, child: Text(l10n.cancel)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
