import 'package:flutter/material.dart';

import '../../core/branding/brand_mark.dart';
import '../../l10n/generated/app_localizations.dart';

class HomeAtlasHeader extends StatelessWidget {
  const HomeAtlasHeader({
    required this.destinationTitle,
    required this.serverName,
    required this.refreshing,
    required this.hasError,
    required this.onRefresh,
    required this.onError,
    required this.onNotifications,
    super.key,
  });

  final String destinationTitle;
  final String serverName;
  final bool refreshing;
  final bool hasError;
  final VoidCallback onRefresh;
  final VoidCallback? onError;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.inverseSurface,
              borderRadius: BorderRadius.circular(13),
            ),
            child: HomePlaceMark(size: 27, lightOnDark: !dark),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  serverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  destinationTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (hasError)
            IconButton(
              tooltip: l10n.errorDetails,
              onPressed: onError,
              icon: Icon(
                Icons.error_outline_rounded,
                color: theme.colorScheme.error,
              ),
            ),
          IconButton(
            tooltip: l10n.notificationHistory,
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: l10n.refresh,
            onPressed: refreshing ? null : onRefresh,
            icon: refreshing
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}
