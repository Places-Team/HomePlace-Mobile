import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../connection/connection_controller.dart';

class NotificationHistoryPage extends StatelessWidget {
  const NotificationHistoryPage({required this.connection, super.key});

  final ConnectionController connection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationHistory),
        actions: [
          ListenableBuilder(
            listenable: connection,
            builder: (context, _) => connection.notificationHistory.isEmpty
                ? const SizedBox.shrink()
                : TextButton(
                    onPressed: connection.clearNotificationHistory,
                    child: Text(l10n.clearHistory),
                  ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: connection,
        builder: (context, _) {
          final items = connection.notificationHistory;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
            children: [
              Text(
                l10n.notificationHistoryPrivacy,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Text(l10n.noRecentNotifications),
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(item.body),
                              const SizedBox(height: 3),
                              Text(
                                MaterialLocalizations.of(context)
                                    .formatTimeOfDay(
                                      TimeOfDay.fromDateTime(
                                        item.receivedAt.toLocal(),
                                      ),
                                    ),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
