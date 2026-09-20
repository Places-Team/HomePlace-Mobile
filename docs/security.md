# Security model

HomePlace Mobile treats server addresses, QR payloads, local networks, certificates, and incoming Link events as untrusted input.

## Connection rules

- Public DNS names require HTTPS.
- HTTP is accepted only for loopback, RFC 1918 IPv4, IPv4 link-local, `.local` names, single-label local hostnames, and IPv6 loopback, link-local, or unique-local addresses.
- URL credentials, paths, queries, fragments, invalid ports, and unsupported schemes are rejected.
- Redirects are not followed during Link requests.
- Invalid TLS certificates are rejected. A self-signed certificate is accepted only after the user confirms its SHA-256 fingerprint, which is pinned to the profile.
- A reconnect verifies the stored server ID before sending the device credential.

## Secrets

Android identity keys are generated in Android Keystore. iOS identity keys are generated in Keychain. Both platforms send the P-256 public key as Base64-encoded SubjectPublicKeyInfo DER. Device credentials use secure platform storage. Pairing secrets, credentials, private keys, authorization headers, and full sensitive payloads must never enter logs, analytics, diagnostics, or UI errors.

Disconnect requests server-side revocation before deleting the local credential. An already-revoked credential is treated as safe to remove locally.

## Capabilities and events

The Flutter client advertises `notification.receive` only after permission is available and `device.presence` with the `foreground` constraint. Android additionally advertises `clipboard.send` with a foreground constraint and `clipboard.receive` with `requiresConfirmation=true`. iOS does not advertise clipboard capabilities. Unsupported capabilities are omitted.

Capabilities describe what the device can do. Server permissions describe what an approved device may request: dashboard reads, reminder management, media requests, Telegram delivery checks, clipboard relay, and sharing. Requested permissions are shown in the web approval screen and stored with the device. The mobile API checks both the device credential and the required permission.

Clipboard text is bounded to 8,000 characters, relayed only to capable devices approved for the same user, and kept in the existing per-device event queue for at most five minutes. Acknowledgement deletes the payload instead of retaining it as event history. Android never reads the clipboard in the background. Incoming text is shown in the application and copied only after the user confirms it.

Incoming events are allowlisted, validated, and acknowledged by event ID; unknown or malformed events are ignored.

Android sharing is deliberately consent-driven. Selecting HomePlace in the system Share Sheet only imports a preview into the application. The user must choose one named device and confirm the send. The server returns and accepts only devices owned by the same `userId`; a target from another account receives the same generic unavailable response as an unknown target. A future family feature must use explicit household membership and consent rather than weakening this boundary.

Text is limited to 8,000 characters. Links are limited to HTTP(S), may not contain embedded credentials, and are never opened automatically. Files are limited to 5 MB, encrypted at rest with a random per-transfer AES-256-GCM key, and offered to exactly one target for five minutes. The receiver must accept before download and save, and the client verifies the advertised SHA-256 digest. Content is not included in logs or notification text. Declined and expired offers are removed; downloaded file transfers are consumed once.

Android offers opt-in periodic notification checks through the operating system's WorkManager. Each run validates the saved server ID before reading the credential, processes only bounded `notification.deliver` events, and acknowledges them after local delivery. Clipboard, links, and files are never handled by the background worker. Android controls the schedule with a minimum interval of about 15 minutes, so this is not advertised as realtime or persistent presence.
