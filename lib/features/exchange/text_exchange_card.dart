import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../link/exchange_api.dart';
import '../../link/link_client.dart';
import '../connection/connection_controller.dart';

class TextExchangeCard extends StatefulWidget {
  const TextExchangeCard({
    required this.sessionProvider,
    required this.available,
    this.clipboardRelayEnabled = false,
    this.gateway = const ExchangeApi(),
    super.key,
  });

  final Future<AuthenticatedLinkSession?> Function() sessionProvider;
  final bool available;
  final bool clipboardRelayEnabled;
  final ExchangeGateway gateway;

  @override
  State<TextExchangeCard> createState() => _TextExchangeCardState();
}

class _TextExchangeCardState extends State<TextExchangeCard> {
  final _text = TextEditingController();
  List<TextExchange> _exchanges = const [];
  bool _expanded = false;
  bool _busy = false;
  bool _deleteAfterOpen = false;
  int _expiresInSeconds = 3600;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<AuthenticatedLinkSession?> _session() async {
    final session = await widget.sessionProvider();
    if (session == null && mounted) {
      setState(() => _error = AppLocalizations.of(context).exchangeReconnect);
    }
    return session;
  }

  Future<void> _load() async {
    if (_busy || !widget.available) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = await _session();
    if (session != null) {
      final result = await widget.gateway.list(session);
      if (mounted) {
        setState(() {
          switch (result) {
            case LinkSuccess<List<TextExchange>>():
              _exchanges = result.value;
            case LinkFailure<List<TextExchange>>():
              _error = result.message;
          }
        });
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _create() async {
    if (_busy || _text.text.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = await _session();
    if (session != null) {
      final result = await widget.gateway.createText(
        session,
        _text.text,
        expiresInSeconds: _expiresInSeconds,
        deleteAfterOpen: _deleteAfterOpen,
      );
      if (mounted) {
        setState(() {
          switch (result) {
            case LinkSuccess<TextExchange>():
              _exchanges = [result.value, ..._exchanges];
              _text.clear();
            case LinkFailure<TextExchange>():
              _error = result.message;
          }
        });
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _revoke(TextExchange exchange) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.exchangeRevoke),
        content: Text(l10n.exchangeRevokeConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.exchangeRevoke),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = await _session();
    if (session != null) {
      final result = await widget.gateway.revoke(session, exchange.token);
      if (mounted) {
        setState(() {
          switch (result) {
            case LinkSuccess<void>():
              _exchanges = _exchanges
                  .where((item) => item.token != exchange.token)
                  .toList();
            case LinkFailure<void>():
              _error = result.message;
          }
        });
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _copy(TextExchange exchange) async {
    if (widget.clipboardRelayEnabled) {
      final l10n = AppLocalizations.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.exchangeCopy),
          content: Text(l10n.exchangeClipboardWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.exchangeCopy),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    final session = await _session();
    if (session == null || !mounted) return;
    final url = session.address.uri.resolve('/x/${exchange.token}');
    await Clipboard.setData(ClipboardData(text: url.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).exchangeCopied)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.link_rounded, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.exchangeTitle,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: _expanded ? l10n.close : l10n.exchangeOpen,
                  onPressed: widget.available
                      ? () {
                          setState(() => _expanded = !_expanded);
                          if (_expanded) _load();
                        }
                      : null,
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                ),
              ],
            ),
            Text(l10n.exchangeSubtitle),
            if (!widget.available) ...[
              const SizedBox(height: 8),
              Text(l10n.permissionsRequired),
            ],
            if (_expanded && widget.available) ...[
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('exchange-text'),
                controller: _text,
                maxLines: 4,
                minLines: 2,
                maxLength: 16000,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.exchangeText,
                  alignLabelWithHint: true,
                ),
              ),
              Text(l10n.exchangeAccountOnly),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _expiresInSeconds,
                decoration: InputDecoration(labelText: l10n.exchangeExpiry),
                items: [
                  DropdownMenuItem(
                    value: 600,
                    child: Text(l10n.exchangeTenMinutes),
                  ),
                  DropdownMenuItem(
                    value: 3600,
                    child: Text(l10n.exchangeOneHour),
                  ),
                  DropdownMenuItem(
                    value: 86400,
                    child: Text(l10n.exchangeOneDay),
                  ),
                ],
                onChanged: _busy
                    ? null
                    : (value) =>
                          setState(() => _expiresInSeconds = value ?? 3600),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.exchangeOneTime),
                subtitle: Text(l10n.exchangeOneTimeWarning),
                value: _deleteAfterOpen,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _deleteAfterOpen = value),
              ),
              FilledButton.icon(
                onPressed: _busy || _text.text.trim().isEmpty ? null : _create,
                icon: const Icon(Icons.add_link_rounded),
                label: Text(l10n.exchangeCreate),
              ),
              if (_busy) const LinearProgressIndicator(),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: colors.error)),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.exchangeActive,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.refresh,
                    onPressed: _busy ? null : _load,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              if (_exchanges.isEmpty && !_busy) Text(l10n.exchangeEmpty),
              for (final exchange in _exchanges)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.exchangeTextLink),
                  subtitle: Text(
                    '${exchange.expiresAt.toLocal().toString().substring(0, 16)} · ${exchange.deleteAfterOpen ? l10n.exchangeOneTime : l10n.exchangeReusable}',
                  ),
                  trailing: Wrap(
                    spacing: 4,
                    children: [
                      IconButton(
                        tooltip: l10n.exchangeCopy,
                        onPressed: _busy ? null : () => _copy(exchange),
                        icon: const Icon(Icons.copy_rounded),
                      ),
                      IconButton(
                        tooltip: l10n.exchangeRevoke,
                        onPressed: _busy ? null : () => _revoke(exchange),
                        icon: const Icon(Icons.link_off_rounded),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
