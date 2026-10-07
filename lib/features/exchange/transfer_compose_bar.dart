import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

class TransferComposeBar extends StatelessWidget {
  const TransferComposeBar({
    required this.onPhotos,
    required this.onFiles,
    this.preparing = false,
    super.key,
  });

  final VoidCallback onPhotos;
  final VoidCallback onFiles;
  final bool preparing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    const accent = Color(0xffaf843b);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 19),
      decoration: BoxDecoration(
        color: dark ? const Color(0xff25251f) : const Color(0xfff2eddf),
        borderRadius: BorderRadius.circular(27),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: dark ? .24 : .16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.north_east_rounded, color: accent),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.sendFromPhone,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      l10n.sendFromPhoneHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.3,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('transfer-send-photos'),
                  onPressed: preparing ? null : onPhotos,
                  icon: const Icon(Icons.photo_library_outlined, size: 19),
                  label: Text(l10n.choosePhotos),
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    minimumSize: const Size(0, 50),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  key: const ValueKey('transfer-send-files'),
                  onPressed: preparing ? null : onFiles,
                  icon: const Icon(Icons.attach_file_rounded, size: 19),
                  label: Text(l10n.chooseFiles),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 50),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                ),
              ),
            ],
          ),
          if (preparing) ...[
            const SizedBox(height: 14),
            const LinearProgressIndicator(),
            const SizedBox(height: 7),
            Text(l10n.preparingFiles, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
