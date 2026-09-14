# HomePlace Link dependency

The HomePlace server repository is the canonical source for HomePlace Link behavior and schemas. This repository contains client models, examples, and tests only; they must follow the server contract rather than define a competing protocol.

The Flutter client supports Link protocol version 1 and currently uses:

- `GET /api/link/info` for product, server identity, protocol range, time, and feature discovery;
- `POST /api/link/pair` to create a short-lived pairing session;
- `POST /api/link/pairing/{id}/claim` to poll for web approval and receive the device credential;
- `POST /api/link/heartbeat` for foreground presence, event delivery, and acknowledgements;
- `DELETE /api/link/device` to revoke the current device.

The server ID returned by pairing and heartbeat must match the ID previewed before pairing. The client rejects incompatible protocol ranges and does not infer unavailable features.

`docs/fixtures/link-info-v1.json` is a mobile test fixture. Update it and the Flutter contract tests whenever the canonical server response changes.

WebSocket presence, durable background delivery, richer commands, and file transfer are outside this migration milestone. They must be implemented against released server behavior before being advertised.
