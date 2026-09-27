import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import 'idea_controller.dart';
import 'idea_store.dart';

const _ideaMint = Color(0xff70e1b4);

class IdeasWorkspace extends StatefulWidget {
  const IdeasWorkspace({
    required this.controller,
    required this.onMakeReminder,
    required this.canMakeReminder,
    required this.clipboardRelayEnabled,
    super.key,
  });

  final IdeaController controller;
  final ValueChanged<String> onMakeReminder;
  final bool canMakeReminder;
  final bool clipboardRelayEnabled;

  @override
  State<IdeasWorkspace> createState() => _IdeasWorkspaceState();
}

class _IdeasWorkspaceState extends State<IdeasWorkspace> {
  final _draft = TextEditingController();
  String _category = 'inbox';
  String? _filter;

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  String _label(AppLocalizations l10n, String category) => switch (category) {
    'inbox' => l10n.ideasInbox,
    'home' => l10n.ideasHome,
    'work' => l10n.ideasWork,
    'media' => l10n.ideasMedia,
    'later' => l10n.ideasLater,
    _ => category.startsWith('custom:') ? category.substring(7) : category,
  };

  Future<void> _createIdea() async {
    final saved = await widget.controller.add(_draft.text, _category);
    if (!mounted) return;
    if (saved) {
      _draft.clear();
      FocusScope.of(context).unfocus();
      setState(() => _filter = null);
    } else {
      _showSaveError();
    }
  }

  void _showSaveError() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).ideasSaveError)),
    );
  }

  Future<void> _newCategory() async {
    final l10n = AppLocalizations.of(context);
    final input = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.ideasNewCategory),
        content: TextField(
          controller: input,
          autofocus: true,
          maxLength: 40,
          decoration: InputDecoration(labelText: l10n.ideasCategoryName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, input.text),
            child: Text(l10n.ideasNewCategory),
          ),
        ],
      ),
    );
    input.dispose();
    if (!mounted || name == null) return;
    final clean = name.trim();
    if (clean.isEmpty) return;
    if (await widget.controller.addCategory(clean)) {
      if (mounted) setState(() => _category = 'custom:$clean');
    } else if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.ideasCategoryExists)));
    }
  }

  Future<void> _editIdea(HomeIdea idea) async {
    final l10n = AppLocalizations.of(context);
    final input = TextEditingController(text: idea.text);
    var category = idea.category;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            24 + MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.ideasEdit,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: input,
                autofocus: true,
                minLines: 2,
                maxLines: 5,
                maxLength: 500,
                onChanged: (_) => updateSheet(() {}),
                decoration: InputDecoration(hintText: l10n.ideasCaptureHint),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: InputDecoration(labelText: l10n.ideasCategory),
                items: [
                  for (final item in widget.controller.categories)
                    DropdownMenuItem(
                      value: item,
                      child: Text(_label(l10n, item)),
                    ),
                ],
                onChanged: (value) =>
                    updateSheet(() => category = value ?? category),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: input.text.trim().isEmpty || widget.controller.busy
                    ? null
                    : () async {
                        final saved = await widget.controller.update(
                          idea,
                          input.text,
                          category,
                        );
                        if (!sheetContext.mounted) return;
                        if (saved) {
                          Navigator.pop(sheetContext);
                        } else {
                          _showSaveError();
                        }
                      },
                child: Text(l10n.ideasSave),
              ),
            ],
          ),
        ),
      ),
    );
    input.dispose();
  }

  Future<void> _copyIdea(HomeIdea idea) async {
    final l10n = AppLocalizations.of(context);
    if (widget.clipboardRelayEnabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.ideasCopy),
          content: Text(l10n.ideasClipboardWarning),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.ideasCopyConfirm),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await Clipboard.setData(ClipboardData(text: idea.text));
  }

  Future<void> _deleteIdea(HomeIdea idea) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.ideasDelete),
        content: Text(l10n.ideasDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.ideasDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!await widget.controller.remove(idea) && mounted) _showSaveError();
  }

  Future<void> _openIdea(HomeIdea idea) async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _label(l10n, idea.category),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 12),
              SelectableText(
                idea.text,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 22),
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: Text(l10n.ideasEdit),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _editIdea(idea);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(l10n.ideasToReminder),
                enabled: widget.canMakeReminder,
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.onMakeReminder(idea.text);
                },
              ),
              ListTile(
                leading: const Icon(Icons.content_copy_rounded),
                title: Text(l10n.ideasCopy),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _copyIdea(idea);
                },
              ),
              ListTile(
                leading: const Icon(Icons.control_point_duplicate_rounded),
                title: Text(l10n.ideasDuplicate),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  if (!await widget.controller.duplicate(idea) && mounted) {
                    _showSaveError();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded),
                title: Text(l10n.ideasDelete),
                textColor: Theme.of(context).colorScheme.error,
                iconColor: Theme.of(context).colorScheme.error,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _deleteIdea(idea);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final l10n = AppLocalizations.of(context);
      final controller = widget.controller;
      if (controller.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (controller.error != null && controller.ideas.isEmpty) {
        return Column(
          children: [
            Text(l10n.ideasLoadError),
            TextButton(onPressed: controller.load, child: Text(l10n.tryAgain)),
          ],
        );
      }
      final visible = controller.ideas
          .where((idea) => _filter == null || idea.category == _filter)
          .toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.ideasTitle,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '${controller.ideas.length}',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(color: _ideaMint, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _ideaMint.withValues(alpha: .11),
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const ValueKey('idea-draft'),
                  controller: _draft,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 500,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: l10n.ideasCaptureHint,
                    prefixIcon: const Icon(Icons.lightbulb_outline_rounded),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('idea-category-$_category'),
                        initialValue: _category,
                        decoration: InputDecoration(
                          labelText: l10n.ideasCategory,
                        ),
                        items: [
                          for (final category in controller.categories)
                            DropdownMenuItem(
                              value: category,
                              child: Text(_label(l10n, category)),
                            ),
                        ],
                        onChanged: (value) =>
                            setState(() => _category = value ?? _category),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      onPressed: controller.busy ? null : _newCategory,
                      tooltip: l10n.ideasNewCategory,
                      icon: const Icon(Icons.create_new_folder_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: controller.busy || _draft.text.trim().isEmpty
                        ? null
                        : _createIdea,
                    icon: const Icon(Icons.arrow_upward_rounded),
                    label: Text(l10n.ideasAdd),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: _ideaMint,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.ideasLocalOnly,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.ideasAll),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
                for (final category in controller.categories) ...[
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(_label(l10n, category)),
                    selected: _filter == category,
                    onSelected: (_) => setState(() => _filter = category),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 28),
              child: Column(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    size: 38,
                    color: _ideaMint,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l10n.ideasEmptyTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.ideasEmptyBody,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          for (final idea in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  key: ValueKey('idea-${idea.id}'),
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _openIdea(idea),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                    child: Row(
                      children: [
                        Container(
                          width: 5,
                          height: 42,
                          decoration: BoxDecoration(
                            color: _ideaMint,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                idea.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${_label(l10n, idea.category)} · '
                                '${MaterialLocalizations.of(context).formatMediumDate(idea.createdAt)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
