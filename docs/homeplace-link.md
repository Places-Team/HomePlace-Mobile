# HomePlace Link dependency

The HomePlace server repository is the canonical source for HomePlace Link behavior and schemas. This repository contains client models, examples, and tests only; they must follow the server contract rather than define a competing protocol.

The Flutter client supports Link protocol version 1 and currently uses:

- `GET /api/link/info` for product, server identity, protocol range, time, and feature discovery;
- `POST /api/link/pair` to create a short-lived pairing session;
- `POST /api/link/pairing/{id}/claim` to poll for web approval and receive the device credential;
- `POST /api/link/heartbeat` for foreground presence, event delivery, and acknowledgements;
- `DELETE /api/link/device` to revoke the current device.

Approved devices may also use scoped mobile endpoints:

- `GET /api/link/mobile/overview` for calendar, reminders, media queues, Telegram state, and monitoring;
- `POST /api/link/mobile/reminders` for personal reminder actions;
- `GET /api/link/mobile/requests/search` and `POST /api/link/mobile/requests` for Sonarr/Radarr requests;
- `POST /api/link/mobile/telegram` for an explicit delivery check;
- `POST /api/link/mobile/clipboard` to relay bounded text to the same user's capable devices.

The pairing document separates device capabilities from server permissions. Android clipboard events use `clipboard.offer`; the receiver presents the text for confirmation and acknowledges it only after copy or dismissal.

The server ID returned by pairing and heartbeat must match the ID previewed before pairing. The client rejects incompatible protocol ranges and does not infer unavailable features.

`docs/fixtures/link-info-v1.json` is a mobile test fixture. Update it and the Flutter contract tests whenever the canonical server response changes.

WebSocket presence, durable background delivery, richer commands, calendar editing, and file transfer are outside this milestone. They must be implemented against released server behavior before being advertised.
