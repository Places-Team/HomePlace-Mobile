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

The initial Flutter slice advertises `notification.receive` only after permission is available and `device.presence` with the `foreground` constraint. Unsupported capabilities are omitted. Incoming events are allowlisted, validated, and acknowledged by event ID; unknown or malformed events are ignored.

Persistent background delivery is not implemented in this milestone and is not advertised.
