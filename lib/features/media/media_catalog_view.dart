import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../link/link_client.dart';
import '../../link/media_api.dart';
import '../connection/connection_controller.dart';

class MediaCatalogView extends StatefulWidget {
  const MediaCatalogView({
    required this.sessionProvider,
    required this.available,
    this.gateway = const MediaApi(),
    super.key,
  });

  final Future<AuthenticatedLinkSession?> Function() sessionProvider;
  final bool available;
  final MediaGateway gateway;

  @override
  State<MediaCatalogView> createState() => _MediaCatalogViewState();
}

class _MediaCatalogViewState extends State<MediaCatalogView> {
  final _search = TextEditingController();
  MediaCatalog? _catalog;
  AuthenticatedLinkSession? _session;
  bool _loading = false;
  int? _openingId;
  String? _error;
  String _kind = 'all';
  String _category = 'all';
  int _page = 1;
  int _revision = 0;
  String? _loadedLanguage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(MediaCatalogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.available && widget.available) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final language = _language;
    if (_loadedLanguage != null && _loadedLanguage != language) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
    _loadedLanguage = language;
  }

  @override
  void dispose() {
    _revision++;
    _search.dispose();
    super.dispose();
  }

  String get _language =>
      Localizations.localeOf(context).languageCode == 'ru' ? 'ru' : 'en';

  String _status(String status, AppLocalizations l10n) => switch (status) {
    'available' => l10n.mediaAvailable,
    'partially-available' => l10n.mediaPartiallyAvailable,
    'requested' => l10n.mediaAlreadyRequested,
    'pending' => l10n.mediaPending,
    _ => l10n.mediaMissing,
  };

  Future<void> _load({int page = 1}) async {
    if (!widget.available || !mounted) return;
    final revision = ++_revision;
    setState(() {
      _loading = true;
      _error = null;
      _catalog = null;
    });
    final session = await widget.sessionProvider();
    if (!mounted || revision != _revision) return;
    if (session == null) {
      setState(() {
        _loading = false;
        _error = AppLocalizations.of(context).exchangeReconnect;
      });
      return;
    }
    final result = await widget.gateway.discover(
      session,
      query: _search.text,
      kind: _kind,
      category: _category,
      language: _language,
      page: page,
    );
    if (!mounted || revision != _revision) return;
    setState(() {
      _session = session;
      _loading = false;
      switch (result) {
        case LinkSuccess<MediaCatalog>():
          _catalog = result.value;
          _page = page;
        case LinkFailure<MediaCatalog>():
          _error = result.message;
      }
    });
  }

  Future<void> _open(MediaTitle title) async {
    if (_openingId != null) return;
    setState(() => _openingId = title.id);
    final session = await widget.sessionProvider();
    if (!mounted) return;
    if (session == null) {
      setState(() {
        _openingId = null;
        _error = AppLocalizations.of(context).exchangeReconnect;
      });
      return;
    }
    final l10n = AppLocalizations.of(context);
    final result = await widget.gateway.details(session, title, _language);
    if (!mounted) return;
    setState(() => _openingId = null);
    if (result case LinkFailure<MediaDetails> failure) {
      setState(() => _error = failure.message);
      return;
    }
    final details = (result as LinkSuccess<MediaDetails>).value;
    final selectedSeasons = <int>{};
    String? profileKey;
    var busy = false;
    String? requestError;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, update) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              4,
              20,
              MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    details.title.title,
                    style: Theme.of(sheetContext).textTheme.headlineSmall,
                  ),
                  if (details.title.originalTitle != null &&
                      details.title.originalTitle != details.title.title)
                    Text(details.title.originalTitle!),
                  const SizedBox(height: 10),
                  Text(details.title.overview),
                  const SizedBox(height: 16),
                  Text(l10n.mediaStatus(_status(details.title.status, l10n))),
                  if (details.profiles.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      isExpanded: true,
                      initialValue: profileKey,
                      decoration: InputDecoration(labelText: l10n.mediaQuality),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(l10n.mediaDefaultQuality),
                        ),
                        ...details.profiles.map(
                          (profile) => DropdownMenuItem<String?>(
                            value: profile.key,
                            child: Text(profile.label),
                          ),
                        ),
                      ],
                      onChanged: busy
                          ? null
                          : (value) => update(() => profileKey = value),
                    ),
                  ],
                  if (details.title.kind == 'tv' &&
                      details.seasons.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      l10n.mediaSeasons,
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                    Text(l10n.mediaAllSeasonsHint),
                    Wrap(
                      spacing: 6,
                      children: details.seasons.map((season) {
                        return FilterChip(
                          label: Text('${season.number} · ${season.name}'),
                          selected: selectedSeasons.contains(season.number),
                          onSelected: busy
                              ? null
                              : (selected) => update(() {
                                  if (selected) {
                                    selectedSeasons.add(season.number);
                                  } else {
                                    selectedSeasons.remove(season.number);
                                  }
                                }),
                        );
                      }).toList(),
                    ),
                  ],
                  if (requestError != null)
                    Text(
                      requestError!,
                      style: TextStyle(
                        color: Theme.of(sheetContext).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          busy ||
                              details.title.status == 'available' ||
                              details.title.status == 'requested' ||
                              details.title.status == 'pending'
                          ? null
                          : () async {
                              update(() {
                                busy = true;
                                requestError = null;
                              });
                              final response = await widget.gateway.request(
                                session,
                                details.title,
                                seasons: selectedSeasons.isEmpty
                                    ? null
                                    : (selectedSeasons.toList()..sort()),
                                profileKey: profileKey,
                              );
                              if (!sheetContext.mounted) return;
                              if (response case LinkFailure<void> failure) {
                                update(() {
                                  busy = false;
                                  requestError = failure.message;
                                });
                              } else {
                                Navigator.pop(sheetContext);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(l10n.mediaRequested),
                                    ),
                                  );
                                  _load(page: _page);
                                }
                              }
                            },
                      icon: const Icon(Icons.add_rounded),
                      label: Text(l10n.request),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!widget.available) return Text(l10n.mediaPermissionNeeded);
    final catalog = _catalog;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _search,
          key: const ValueKey('media-catalog-search'),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: l10n.searchMedia,
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: IconButton(
              tooltip: l10n.search,
              icon: const Icon(Icons.arrow_forward_rounded),
              onPressed: () => _load(),
            ),
          ),
          onSubmitted: (_) => _load(),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final (value, label) in [
              ('all', l10n.mediaAll),
              ('movie', l10n.mediaMovies),
              ('tv', l10n.mediaSeries),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _kind == value,
                onSelected: (_) {
                  setState(() => _kind = value);
                  _load();
                },
              ),
            FilterChip(
              label: Text(l10n.mediaAnime),
              selected: _category == 'anime',
              onSelected: (selected) {
                setState(() => _category = selected ? 'anime' : 'all');
                _load();
              },
            ),
          ],
        ),
        if (_loading) const LinearProgressIndicator(),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          TextButton(
            onPressed: () => _load(page: _page),
            child: Text(l10n.retry),
          ),
        ],
        if (catalog != null && !_loading) ...[
          const SizedBox(height: 12),
          if (!catalog.configured)
            Text(l10n.mediaNotConfigured)
          else if (catalog.unavailable)
            Text(l10n.mediaUnavailable)
          else if (catalog.items.isEmpty)
            Text(l10n.mediaNoResults)
          else ...[
            for (final title in catalog.items)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: title.poster == null || _session == null
                      ? const Icon(Icons.movie_outlined)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: _VerifiedPoster(
                            session: _session!,
                            path: title.poster!,
                            gateway: widget.gateway,
                          ),
                        ),
                  title: Text(title.title),
                  subtitle: Text(
                    [
                      if (title.originalTitle != null &&
                          title.originalTitle != title.title)
                        title.originalTitle!,
                      if (title.year != null) '${title.year}',
                      _status(title.status, l10n),
                    ].join(' · '),
                  ),
                  trailing: _openingId == title.id
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: _openingId == null ? () => _open(title) : null,
                ),
              ),
            if (catalog.pages > 1)
              Row(
                children: [
                  IconButton(
                    tooltip: l10n.mediaPrevious,
                    onPressed: catalog.page > 1
                        ? () => _load(page: catalog.page - 1)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Text('${catalog.page} / ${catalog.pages}'),
                  IconButton(
                    tooltip: l10n.mediaNext,
                    onPressed: catalog.page < catalog.pages
                        ? () => _load(page: catalog.page + 1)
                        : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
          ],
        ],
      ],
    );
  }
}

class _VerifiedPoster extends StatefulWidget {
  const _VerifiedPoster({
    required this.session,
    required this.path,
    required this.gateway,
  });

  final AuthenticatedLinkSession session;
  final String path;
  final MediaGateway gateway;

  @override
  State<_VerifiedPoster> createState() => _VerifiedPosterState();
}

class _VerifiedPosterState extends State<_VerifiedPoster> {
  late Future<LinkResult<Uint8List>> _image;

  @override
  void initState() {
    super.initState();
    _image = widget.gateway.poster(widget.session, widget.path);
  }

  @override
  void didUpdateWidget(_VerifiedPoster oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.path != oldWidget.path ||
        widget.session.credential != oldWidget.session.credential ||
        widget.gateway != oldWidget.gateway) {
      _image = widget.gateway.poster(widget.session, widget.path);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<LinkResult<Uint8List>>(
    future: _image,
    builder: (context, snapshot) {
      final result = snapshot.data;
      if (result is! LinkSuccess<Uint8List>) {
        return const Icon(Icons.movie_outlined);
      }
      return Image.memory(
        result.value,
        width: 42,
        height: 62,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.movie_outlined),
      );
    },
  );
}
