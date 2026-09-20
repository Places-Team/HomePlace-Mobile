# HomePlace Link dependency

The HomePlace server repository is the canonical source for HomePlace Link behavior and schemas. This repository contains client models, examples, and tests only; they must follow the server contract rather than define a competing protocol.

The Flutter client supports Link protocol version 1 and currently uses:

- `GET /api/link/info` for product, server identity, protocol range, time, and feature discovery;
- `POST /api/link/pair` to create a short-lived pairing session;
- `POST /api/link/pairing/{id}/claim` to poll for web approval and receive the device credential;
- `POST /api/link/heartbeat` for foreground presence, event delivery, and acknowledgements;
- `DELETE /api/link/device` to revoke the current device.

Approved devices may also use scoped mobile endpoints:

- `GET /api/link/mobile/overview` for calendar, reminders, media queues, Telegram state, monitoring, and same-account share targets;
- `POST /api/link/mobile/reminders` to create, edit, complete, restore, delete, or clear completed reminders belonging to the paired user;
- `GET /api/link/mobile/requests/search` and `POST /api/link/mobile/requests` for Sonarr/Radarr requests;
- `POST /api/link/mobile/telegram` for an explicit delivery check;
- `POST /api/link/mobile/clipboard` to relay bounded text to the same user's capable devices.
- `POST /api/link/mobile/share` for confirmed text and URL offers to one same-account device;
- `POST /api/link/mobile/share/file` and `GET /api/link/mobile/share/file/{id}` for single-use encrypted file transfer.

The pairing document separates device capabilities from server permissions. Android clipboard events use `clipboard.offer`; the receiver presents the text for confirmation and acknowledges it only after copy or dismissal. Share events use `share.offer`, expire after five minutes, and are deleted when accepted or declined. Android advertises `share.send`, `text.receive`, `url.open`, and `file.receive`; iOS does not advertise them until its Share Extension and receiving UI are implemented.

The server ID returned by pairing and heartbeat must match the ID previewed before pairing. The client rejects incompatible protocol ranges and does not infer unavailable features.

`docs/fixtures/link-info-v1.json` is a mobile test fixture. Update it and the Flutter contract tests whenever the canonical server response changes.

The app can retain multiple connection profiles and switch between them only after revalidating the saved server ID. Credentials and transfer history remain isolated by server profile. Household sharing uses the server's explicit household membership and approval model and never exposes all accounts on an installation.

WebSocket presence, durable background delivery, richer commands, and local-network discovery remain outside this milestone. Discovery must wait for a canonical server advertisement contract rather than guessing endpoints or service names in the client.
