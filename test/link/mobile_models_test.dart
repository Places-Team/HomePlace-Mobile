import 'package:flutter_test/flutter_test.dart';
import 'package:homeplace/link/mobile_models.dart';

void main() {
  test('parses the authenticated mobile overview', () {
    final overview = MobileOverview.fromJson({
      'serverTime': '2026-09-20T10:00:00Z',
      'permissions': ['dashboard.read', 'reminder.manage'],
      'reminders': [
        {
          'id': 'r1',
          'title': 'Water plants',
          'at': '2026-09-20T18:00:00Z',
          'repeat': 'weekly',
          'done': true,
          'createdAt': '2026-09-19T18:00:00Z',
          'completedAt': '2026-09-20T09:00:00Z',
        },
      ],
      'calendar': {
        'connected': true,
        'email': 'home@example.test',
        'events': [
          {
            'id': 'e1',
            'summary': 'Dinner',
            'start': '2026-09-20T19:00:00Z',
            'end': '2026-09-20T20:00:00Z',
            'allDay': false,
          },
        ],
      },
      'requests': {'instances': [], 'qbittorrent': null},
      'telegram': {'connected': true, 'enabled': true, 'source': 'ui'},
      'monitoring': {
        'total': 2,
        'online': 1,
        'offline': 1,
        'unknown': 0,
        'services': [],
        'recent': [],
      },
      'shareTargets': [
        {
          'id': 'device-2',
          'name': 'Family tablet',
          'platform': 'android',
          'supportsText': true,
          'supportsUrl': true,
          'supportsFile': true,
          'online': true,
        },
      ],
    });

    expect(overview.reminders.single.repeat, 'weekly');
    expect(overview.reminders.single.done, isTrue);
    expect(overview.reminders.single.completedAt, isNotNull);
    expect(overview.calendar.events.single.summary, 'Dinner');
    expect(overview.telegram.enabled, isTrue);
    expect(overview.monitoring.offline, 1);
    expect(overview.shareTargets.single.name, 'Family tablet');
    expect(overview.shareTargets.single.supportsFile, isTrue);
  });
}
