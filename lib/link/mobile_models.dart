final class MobileReminder {
  const MobileReminder({
    required this.id,
    required this.title,
    required this.at,
    required this.repeat,
  });
  factory MobileReminder.fromJson(Map<String, dynamic> json) => MobileReminder(
    id: json['id'] as String,
    title: json['title'] as String,
    at: DateTime.parse(json['at'] as String),
    repeat: json['repeat'] as String? ?? 'none',
  );
  final String id;
  final String title;
  final DateTime at;
  final String repeat;
}

final class MobileCalendarEvent {
  const MobileCalendarEvent({
    required this.id,
    required this.summary,
    required this.start,
    required this.end,
    required this.allDay,
    this.location,
  });
  factory MobileCalendarEvent.fromJson(Map<String, dynamic> json) =>
      MobileCalendarEvent(
        id: json['id'] as String,
        summary: json['summary'] as String? ?? '',
        start: DateTime.parse(json['start'] as String),
        end: DateTime.parse(json['end'] as String),
        allDay: json['allDay'] as bool? ?? false,
        location: json['location'] as String?,
      );
  final String id;
  final String summary;
  final DateTime start;
  final DateTime end;
  final bool allDay;
  final String? location;
}

final class MobileCalendar {
  const MobileCalendar({
    required this.connected,
    required this.events,
    this.email,
  });
  factory MobileCalendar.fromJson(Map<String, dynamic> json) => MobileCalendar(
    connected: json['connected'] as bool? ?? false,
    email: json['email'] as String?,
    events: _maps(json['events'])
        .map(MobileCalendarEvent.fromJson)
        .toList(growable: false),
  );
  final bool connected;
  final String? email;
  final List<MobileCalendarEvent> events;
}

final class MobileUpcoming {
  const MobileUpcoming({required this.title, required this.at, this.sub});
  factory MobileUpcoming.fromJson(Map<String, dynamic> json) => MobileUpcoming(
    title: json['title'] as String? ?? '',
    sub: json['sub'] as String?,
    at: DateTime.fromMillisecondsSinceEpoch((json['at'] as num).round()),
  );
  final String title;
  final String? sub;
  final DateTime at;
}

final class MobileQueueItem {
  const MobileQueueItem({
    required this.title,
    required this.status,
    required this.progress,
  });
  factory MobileQueueItem.fromJson(Map<String, dynamic> json) =>
      MobileQueueItem(
        title: json['title'] as String? ?? '',
        status: json['status'] as String? ?? '',
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
      );
  final String title;
  final String status;
  final double progress;
}

final class MobileArrInstance {
  const MobileArrInstance({
    required this.label,
    required this.kind,
    required this.queueCount,
    required this.warnings,
    required this.queue,
    required this.upcoming,
  });
  factory MobileArrInstance.fromJson(Map<String, dynamic> json) =>
      MobileArrInstance(
        label: json['label'] as String? ?? '',
        kind: json['kind'] as String? ?? '',
        queueCount: (json['queueCount'] as num?)?.round() ?? 0,
        warnings: (json['warnings'] as num?)?.round() ?? 0,
        queue: _maps(json['queue'])
            .map(MobileQueueItem.fromJson)
            .toList(growable: false),
        upcoming: _maps(json['upcoming'])
            .map(MobileUpcoming.fromJson)
            .toList(growable: false),
      );
  final String label;
  final String kind;
  final int queueCount;
  final int warnings;
  final List<MobileQueueItem> queue;
  final List<MobileUpcoming> upcoming;
}

final class MobileQbit {
  const MobileQbit({
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.active,
    required this.total,
  });
  factory MobileQbit.fromJson(Map<String, dynamic> json) => MobileQbit(
    downloadSpeed: (json['downloadSpeed'] as num?)?.round() ?? 0,
    uploadSpeed: (json['uploadSpeed'] as num?)?.round() ?? 0,
    active: (json['active'] as num?)?.round() ?? 0,
    total: (json['total'] as num?)?.round() ?? 0,
  );
  final int downloadSpeed;
  final int uploadSpeed;
  final int active;
  final int total;
}

final class MobileRequests {
  const MobileRequests({required this.instances, this.qbittorrent});
  factory MobileRequests.fromJson(Map<String, dynamic> json) => MobileRequests(
    instances: _maps(json['instances'])
        .map(MobileArrInstance.fromJson)
        .toList(growable: false),
    qbittorrent: json['qbittorrent'] is Map<String, dynamic>
        ? MobileQbit.fromJson(json['qbittorrent'] as Map<String, dynamic>)
        : null,
  );
  final List<MobileArrInstance> instances;
  final MobileQbit? qbittorrent;
}

final class MobileServiceStatus {
  const MobileServiceStatus({
    required this.id,
    required this.title,
    required this.status,
    this.latencyMs,
    this.checkedAt,
  });
  factory MobileServiceStatus.fromJson(Map<String, dynamic> json) =>
      MobileServiceStatus(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        status: json['status'] as String? ?? 'unknown',
        latencyMs: (json['latencyMs'] as num?)?.round(),
        checkedAt: json['checkedAt'] is String
            ? DateTime.tryParse(json['checkedAt'] as String)
            : null,
      );
  final String id;
  final String title;
  final String status;
  final int? latencyMs;
  final DateTime? checkedAt;
}

final class MobileEvent {
  const MobileEvent({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.at,
    this.detail,
  });
  factory MobileEvent.fromJson(Map<String, dynamic> json) => MobileEvent(
    id: json['id'] as String,
    type: json['type'] as String? ?? '',
    severity: json['severity'] as String? ?? 'info',
    title: json['title'] as String? ?? '',
    detail: json['detail'] as String?,
    at: DateTime.parse(json['at'] as String),
  );
  final String id;
  final String type;
  final String severity;
  final String title;
  final String? detail;
  final DateTime at;
}

final class MobileMonitoring {
  const MobileMonitoring({
    required this.total,
    required this.online,
    required this.offline,
    required this.unknown,
    required this.services,
    required this.recent,
  });
  factory MobileMonitoring.fromJson(Map<String, dynamic> json) =>
      MobileMonitoring(
        total: (json['total'] as num?)?.round() ?? 0,
        online: (json['online'] as num?)?.round() ?? 0,
        offline: (json['offline'] as num?)?.round() ?? 0,
        unknown: (json['unknown'] as num?)?.round() ?? 0,
        services: _maps(json['services'])
            .map(MobileServiceStatus.fromJson)
            .toList(growable: false),
        recent: _maps(json['recent'])
            .map(MobileEvent.fromJson)
            .toList(growable: false),
      );
  final int total;
  final int online;
  final int offline;
  final int unknown;
  final List<MobileServiceStatus> services;
  final List<MobileEvent> recent;
}

final class MobileTelegram {
  const MobileTelegram({
    required this.connected,
    required this.enabled,
    required this.source,
  });
  factory MobileTelegram.fromJson(Map<String, dynamic> json) => MobileTelegram(
    connected: json['connected'] as bool? ?? false,
    enabled: json['enabled'] as bool? ?? false,
    source: json['source'] as String? ?? 'none',
  );
  final bool connected;
  final bool enabled;
  final String source;
}

final class MobileOverview {
  const MobileOverview({
    required this.serverTime,
    required this.permissions,
    required this.reminders,
    required this.calendar,
    required this.requests,
    required this.telegram,
    required this.monitoring,
  });
  factory MobileOverview.fromJson(Map<String, dynamic> json) => MobileOverview(
    serverTime: DateTime.parse(json['serverTime'] as String),
    permissions: (json['permissions'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toSet(),
    reminders: _maps(json['reminders'])
        .map(MobileReminder.fromJson)
        .toList(growable: false),
    calendar: MobileCalendar.fromJson(
      json['calendar'] as Map<String, dynamic>? ?? const {},
    ),
    requests: MobileRequests.fromJson(
      json['requests'] as Map<String, dynamic>? ?? const {},
    ),
    telegram: MobileTelegram.fromJson(
      json['telegram'] as Map<String, dynamic>? ?? const {},
    ),
    monitoring: MobileMonitoring.fromJson(
      json['monitoring'] as Map<String, dynamic>? ?? const {},
    ),
  );
  final DateTime serverTime;
  final Set<String> permissions;
  final List<MobileReminder> reminders;
  final MobileCalendar calendar;
  final MobileRequests requests;
  final MobileTelegram telegram;
  final MobileMonitoring monitoring;
}

final class MobileSearchResult {
  const MobileSearchResult({
    required this.instanceLabel,
    required this.kind,
    required this.title,
    required this.inLibrary,
    required this.externalId,
    this.year,
    this.poster,
    this.overview,
  });
  factory MobileSearchResult.fromJson(Map<String, dynamic> json) =>
      MobileSearchResult(
        instanceLabel: json['instanceLabel'] as String? ?? '',
        kind: json['kind'] as String? ?? '',
        title: json['title'] as String? ?? '',
        year: (json['year'] as num?)?.round(),
        poster: json['poster'] as String?,
        overview: json['overview'] as String?,
        inLibrary: json['inLibrary'] as bool? ?? false,
        externalId: (json['externalId'] as num?)?.round() ?? 0,
      );
  final String instanceLabel;
  final String kind;
  final String title;
  final int? year;
  final String? poster;
  final String? overview;
  final bool inLibrary;
  final int externalId;
}

List<Map<String, dynamic>> _maps(Object? value) =>
    (value as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
