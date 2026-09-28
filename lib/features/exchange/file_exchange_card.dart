import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

import '../../core/sharing/share_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../link/exchange_api.dart';
import '../../link/link_client.dart';
import '../connection/connection_controller.dart';

final class SelectedExchangeFile {
  const SelectedExchangeFile({
    required this.file,
    required this.filename,
    required this.mimeType,
    required this.size,
  });

  final File file;
  final String filename;
  final String mimeType;
  final int size;
}

Future<SelectedExchangeFile?> pickExchangeFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.any,
    allowMultiple: false,
    withData: false,
  );
  final picked = result?.files.singleOrNull;
  final path = picked?.path;
  if (picked == null || path == null || path.isEmpty) return null;
  final file = File(path);
  return SelectedExchangeFile(
    file: file,
    filename: picked.name,
    mimeType: lookupMimeType(picked.name) ?? 'application/octet-stream',
    size: await file.length(),
  );
}

class FileExchangeCard extends StatefulWidget {
  const FileExchangeCard({
    required this.sessionProvider,
    required this.available,
    this.clipboardRelayEnabled = false,
    this.gateway = const ExchangeApi(),
    this.sharing = const PlatformShareService(),
    this.picker = pickExchangeFile,
    super.key,
  });

  final Future<AuthenticatedLinkSession?> Function() sessionProvider;
  final bool available;
  final bool clipboardRelayEnabled;
  final FileExchangeGateway gateway;
  final ShareService sharing;
  final Future<SelectedExchangeFile?> Function() picker;

  @override
  State<FileExchangeCard> createState() => _FileExchangeCardState();
}

class _FileExchangeCardState extends State<FileExchangeCard> {
  final _link = TextEditingController();
  List<FileExchange> _exchanges = const [];
  SelectedExchangeFile? _selected;
  FileExchange? _incoming;
  SavedSharedFile? _saved;
  LinkTransferCancellation? _cancellation;
  bool _expanded = false;
  bool _busy = false;
  bool _uploading = false;
  bool _downloading = false;
  bool _deleteAfterOpen = false;
  bool _quick = false;
  int _expiresInSeconds = 3600;
  String _access = 'account';
  int? _maxFileBytes;
  double? _progress;
  String? _error;

  @override
  void dispose() {
    _link.dispose();
    super.dispose();
  }

  String? _tokenFromInput(String value, Uri server) {
    final trimmed = value.trim();
    if (RegExp(r'^[A-Za-z0-9_-]{22}$').hasMatch(trimmed)) return trimmed;
    final link = Uri.tryParse(trimmed);
    if (link == null ||
        link.scheme != server.scheme ||
        link.host != server.host ||
        link.port != server.port ||
        link.userInfo.isNotEmpty ||
        link.hasQuery ||
        link.hasFragment ||
        link.pathSegments.length != 2 ||
        link.pathSegments.first != 'x') {
      return null;
    }
    final token = link.pathSegments.last;
    return RegExp(r'^[A-Za-z0-9_-]{22}$').hasMatch(token) ? token : null;
  }

  String? _shortCodeFromInput(String value, Uri server) {
    final trimmed = value.trim();
    final codePattern = RegExp(r'^[1-9A-HJ-NP-Za-km-z]{5}$');
    if (codePattern.hasMatch(trimmed)) return trimmed;
    final link = Uri.tryParse(trimmed);
    if (link == null ||
        link.scheme != server.scheme ||
        link.host != server.host ||
        link.port != server.port ||
        link.userInfo.isNotEmpty ||
        link.hasQuery ||
        link.hasFragment ||
        link.pathSegments.length != 2 ||
        link.pathSegments.first != 'f') {
      return null;
    }
    final code = link.pathSegments.last;
    return codePattern.hasMatch(code) ? code : null;
  }

  Future<void> _inspect() async {
    if (_busy) return;
    final session = await _session();
    if (session == null || !mounted) return;
    var token = _tokenFromInput(_link.text, session.address.uri);
    final shortCode = token == null
        ? _shortCodeFromInput(_link.text, session.address.uri)
        : null;
    if (token == null && shortCode == null) {
      setState(
        () => _error = AppLocalizations.of(context).fileExchangeInvalidLink,
      );
      return;
    }
    setState(() {
      _busy = true;
      _incoming = null;
      _saved = null;
      _error = null;
    });
    if (shortCode != null) {
      final resolved = await widget.gateway.resolveShortCode(
        session,
        shortCode,
      );
      if (!mounted) return;
      if (resolved case LinkFailure<String> failure) {
        setState(() {
          _busy = false;
          _error = failure.message;
        });
        return;
      }
      token = (resolved as LinkSuccess<String>).value;
    }
    final result = await widget.gateway.inspectFile(session, token!);
    if (!mounted) return;
    setState(() {
      _busy = false;
      switch (result) {
        case LinkSuccess<FileExchange>():
          _incoming = result.value;
        case LinkFailure<FileExchange>():
          _error = result.message;
      }
    });
  }

  Future<void> _download() async {
    final exchange = _incoming;
    if (exchange == null || _busy || !widget.sharing.isSupported) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.fileExchangeDownload),
        content: Text(
          '${exchange.filename} · ${_formatSize(exchange.size)}\n\n'
          '${exchange.deleteAfterOpen ? l10n.fileExchangeOneTimeWarning : l10n.fileExchangeSaveConfirm}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.fileExchangeDownload),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final session = await _session();
    if (session == null || !mounted) return;
    final cancellation = LinkTransferCancellation();
    setState(() {
      _busy = true;
      _downloading = true;
      _cancellation = cancellation;
      _progress = 0;
      _error = null;
      _saved = null;
    });
    String? temporaryPath;
    try {
      temporaryPath = await widget.sharing.createTemporaryFilePath();
      final result = await widget.gateway.downloadFile(
        session,
        exchange,
        destination: File(temporaryPath),
        cancellation: cancellation,
        onProgress: (received, total) {
          if (mounted && total > 0) {
            final next = received / total;
            if (_progress == null ||
                (next - _progress!).abs() >= .01 ||
                next == 1) {
              setState(() => _progress = next);
            }
          }
        },
      );
      if (result case LinkSuccess<DownloadedLinkFile> success) {
        if (cancellation.isCancelled) return;
        final saved = await widget.sharing.saveFilePath(
          success.value.file.path,
          exchange.filename,
          exchange.mimeType,
        );
        if (mounted) {
          setState(() {
            _saved = saved;
            _incoming = null;
          });
        }
      } else if (result case LinkFailure<DownloadedLinkFile> failure) {
        if (mounted && failure.kind != LinkFailureKind.cancelled) {
          setState(() => _error = failure.message);
        }
      }
    } on Object {
      if (mounted) {
        setState(() => _error = l10n.fileExchangeSaveError);
      }
    } finally {
      if (temporaryPath != null) {
        try {
          await File(temporaryPath).delete();
        } on Object {
          // The successful MediaStore copy or transfer error is authoritative.
        }
      }
      if (mounted) {
        setState(() {
          _busy = false;
          _downloading = false;
          _cancellation = null;
          _progress = null;
        });
      }
    }
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
      final limit = await widget.gateway.fileLimit(session);
      if (mounted) {
        setState(() {
          switch (limit) {
            case LinkSuccess<int>():
              _maxFileBytes = limit.value;
            case LinkFailure<int>():
              _maxFileBytes = null;
              _error = limit.message;
          }
        });
      }
      final result = await widget.gateway.listFiles(session);
      if (mounted) {
        setState(() {
          switch (result) {
            case LinkSuccess<List<FileExchange>>():
              _exchanges = result.value;
            case LinkFailure<List<FileExchange>>():
              _error = result.message;
          }
        });
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _pick() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await _session();
      if (session == null || !mounted) return;
      final result = await widget.gateway.fileLimit(session);
      if (!mounted) return;
      if (result case LinkFailure<int> failure) {
        setState(() => _error = failure.message);
        return;
      }
      final limit = (result as LinkSuccess<int>).value;
      setState(() => _maxFileBytes = limit);
      if (limit < 1) {
        setState(
          () =>
              _error = AppLocalizations.of(context)
                  .fileExchangeSizeError('0 B'),
        );
        return;
      }
      final selected = await widget.picker();
      if (selected == null || !mounted) return;
      if (selected.size < 1 || selected.size > limit) {
        setState(
          () =>
              _error = AppLocalizations.of(context)
                  .fileExchangeSizeError(_formatSize(limit)),
        );
        return;
      }
      setState(() => _selected = selected);
    } on Object {
      if (mounted) {
        setState(
          () => _error = AppLocalizations.of(context).fileExchangePickError,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmPublic() async {
    final l10n = AppLocalizations.of(context);
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.fileExchangePublic),
            content: Text(l10n.fileExchangePublicWarning),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.fileExchangeConfirmPublic),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _upload() async {
    final selected = _selected;
    if (_busy || selected == null) return;
    if ((_access == 'link' || _quick) && !await _confirmPublic()) return;
    if (!mounted) return;
    final session = await _session();
    if (session == null || !mounted) return;
    final cancellation = LinkTransferCancellation();
    setState(() {
      _busy = true;
      _uploading = true;
      _cancellation = cancellation;
      _progress = 0;
      _error = null;
    });
    final result = await widget.gateway.createFile(
      session,
      selected.file,
      filename: selected.filename,
      mimeType: selected.mimeType,
      expiresInSeconds: _expiresInSeconds,
      access: _access,
      deleteAfterOpen: _deleteAfterOpen,
      quick: _quick,
      cancellation: cancellation,
      onProgress: (sent, total) {
        if (mounted && total > 0) {
          final next = sent / total;
          if (_progress == null ||
              (next - _progress!).abs() >= .01 ||
              next == 1) {
            setState(() => _progress = next);
          }
        }
      },
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _uploading = false;
      _cancellation = null;
      _progress = null;
      switch (result) {
        case LinkSuccess<FileExchange>():
          _exchanges = [result.value, ..._exchanges];
          _selected = null;
        case LinkFailure<FileExchange>():
          if (result.kind != LinkFailureKind.cancelled) _error = result.message;
      }
    });
  }

  Future<void> _copy(FileExchange exchange) async {
    final l10n = AppLocalizations.of(context);
    if (widget.clipboardRelayEnabled) {
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
    await Clipboard.setData(
      ClipboardData(
        text: session.address.uri
            .resolve(
              exchange.shortCode == null
                  ? '/x/${exchange.token}'
                  : '/f/${exchange.shortCode}',
            )
            .toString(),
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.exchangeCopied)));
    }
  }

  Future<void> _revoke(FileExchange exchange) async {
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
                  .where((entry) => entry.token != exchange.token)
                  .toList();
            case LinkFailure<void>():
              _error = result.message;
          }
        });
      }
    }
    if (mounted) setState(() => _busy = false);
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
                Icon(Icons.folder_zip_outlined, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.fileExchangeTitle,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: _expanded ? l10n.close : l10n.fileExchangeOpen,
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
            Text(l10n.fileExchangeSubtitle),
            if (!widget.available) ...[
              const SizedBox(height: 8),
              Text(l10n.permissionsRequired),
            ],
            if (_expanded && widget.available) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _busy ? null : _pick,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(l10n.fileExchangeChoose),
              ),
              if (_maxFileBytes != null)
                Text(l10n.fileExchangeLimit(_formatSize(_maxFileBytes!))),
              if (_selected != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${_selected!.filename} · ${_formatSize(_selected!.size)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.fileExchangeQuick),
                subtitle: Text(l10n.fileExchangeQuickWarning),
                value: _quick,
                onChanged: _busy
                    ? null
                    : (value) => setState(() => _quick = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey('file-exchange-access-$_quick'),
                isExpanded: true,
                initialValue: _quick ? 'link' : _access,
                decoration: InputDecoration(labelText: l10n.fileExchangeAccess),
                items: [
                  DropdownMenuItem(
                    value: 'account',
                    child: Text(l10n.fileExchangeAccount),
                  ),
                  DropdownMenuItem(
                    value: 'link',
                    child: Text(l10n.fileExchangePublic),
                  ),
                ],
                onChanged: _busy || _quick
                    ? null
                    : (value) => setState(() => _access = value ?? 'account'),
              ),
              if (_access == 'link' && !_quick) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.fileExchangePublicWarning,
                  style: TextStyle(color: colors.error),
                ),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                key: ValueKey('file-exchange-expiry-$_quick'),
                initialValue: _quick ? 600 : _expiresInSeconds,
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
                onChanged: _busy || _quick
                    ? null
                    : (value) =>
                          setState(() => _expiresInSeconds = value ?? 3600),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.exchangeOneTime),
                subtitle: Text(l10n.exchangeOneTimeWarning),
                value: _quick || _deleteAfterOpen,
                onChanged: _busy || _quick
                    ? null
                    : (value) => setState(() => _deleteAfterOpen = value),
              ),
              FilledButton.icon(
                onPressed: _busy || _selected == null ? null : _upload,
                icon: const Icon(Icons.cloud_upload_outlined),
                label: Text(l10n.fileExchangeUpload),
              ),
              if (_uploading) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(value: _progress),
                TextButton.icon(
                  onPressed: _cancellation?.cancel,
                  icon: const Icon(Icons.close_rounded),
                  label: Text(l10n.cancel),
                ),
              ] else if (_busy)
                const LinearProgressIndicator(),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(color: colors.error)),
              ],
              if (widget.sharing.isSupported) ...[
                const SizedBox(height: 22),
                Text(
                  l10n.fileExchangeReceive,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('file-exchange-link'),
                  controller: _link,
                  maxLines: 1,
                  maxLength: 2048,
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setState(() {
                    _incoming = null;
                    _saved = null;
                  }),
                  decoration: InputDecoration(
                    labelText: l10n.fileExchangeLink,
                    hintText: 'https://home.example/x/...',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _busy || _link.text.trim().isEmpty
                      ? null
                      : _inspect,
                  icon: const Icon(Icons.search_rounded),
                  label: Text(l10n.fileExchangeCheck),
                ),
                if (_incoming != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${_incoming!.filename} · ${_formatSize(_incoming!.size)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _incoming!.deleteAfterOpen
                        ? l10n.fileExchangeOneTimeWarning
                        : l10n.fileExchangeSaveConfirm,
                  ),
                  FilledButton.icon(
                    onPressed: _busy ? null : _download,
                    icon: const Icon(Icons.download_rounded),
                    label: Text(l10n.fileExchangeDownload),
                  ),
                ],
                if (_downloading) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(value: _progress),
                  TextButton.icon(
                    onPressed: _cancellation?.cancel,
                    icon: const Icon(Icons.close_rounded),
                    label: Text(l10n.cancel),
                  ),
                ],
                if (_saved != null)
                  FilledButton.tonalIcon(
                    onPressed: () async {
                      try {
                        await widget.sharing.openSavedFile(_saved!);
                      } on Object {
                        if (mounted) {
                          setState(() => _error = l10n.fileExchangeOpenError);
                        }
                      }
                    },
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: Text(l10n.fileExchangeOpenSaved),
                  ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.fileExchangeActive,
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
              if (_exchanges.isEmpty && !_busy) Text(l10n.fileExchangeEmpty),
              for (final exchange in _exchanges)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    exchange.filename,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${exchange.shortCode == null ? '' : '${l10n.fileExchangeCode}: ${exchange.shortCode} · '}${_formatSize(exchange.size)} · ${exchange.access == 'account' ? l10n.fileExchangeAccount : l10n.fileExchangePublic} · ${exchange.expiresAt.toLocal().toString().substring(0, 16)}',
                    maxLines: 3,
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

String _formatSize(int size) {
  if (size >= 1024 * 1024 * 1024) {
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GiB';
  }
  if (size >= 1024 * 1024) {
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  if (size >= 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
  return '$size B';
}
