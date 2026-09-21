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

Android sharing is deliberately consent-driven. Selecting HomePlace in the system Share Sheet only imports a preview into the application. The user must choose one named device and confirm the send. The server always allows targets owned by the same `userId`; a device owned by another household user appears only when an administrator has explicitly enabled household sharing for that receiving device. Unknown and unauthorized targets receive the same generic unavailable response.

Text is limited to 8,000 characters. Links are limited to HTTP(S), may not contain embedded credentials, and are never opened automatically. Files are limited to 500 MB, streamed instead of being held in memory, encrypted at rest by the server with a random per-transfer AES-256-GCM key, and offered to exactly one target for five minutes. The receiver must accept before download and save. The client checks the response metadata, exact byte count, and advertised SHA-256 digest before asking the Android host to copy the private temporary file into `Downloads/HomePlace`. Cancellation or any mismatch deletes the temporary client file and leaves the offer available for an explicit retry until expiry. Content is not included in logs or notification text. Declined, accepted, and expired offers are removed with their server-side transfer data.

Android offers opt-in periodic notification checks through the operating system's WorkManager. Each run validates the saved server ID before reading the credential, processes only bounded `notification.deliver` events, and acknowledges them after local delivery. When background incoming review is also enabled, the worker validates offer metadata and posts a private notification but does not read, open, copy, download, save, decline, or acknowledge the offered content. Android controls the schedule with a minimum interval of about 15 minutes, so this is not advertised as realtime or persistent presence.

Delivered notification titles and bodies are retained in a bounded local history of 30 items. The history is encrypted with platform-secure storage, scoped to a hash of the server ID and device credential, and can be cleared from the application. Background diagnostics store only a timestamp and successful profile count in preferences; they never include credentials or payloads.

Android may optionally discover incoming clipboard, text, URL and file offers during the same periodic background check. The background worker validates the server identity and bounded event metadata, displays a private notification without embedding the shared value or filename, and deliberately leaves the event unacknowledged. The user must open the review surface and separately copy, open, save or decline each item. Notification deduplication stores event identifiers only. Multiple offers are queued independently and remain isolated to the authenticated profile and server-enforced account or household scope.
