# Security model

HomePlace Mobile assumes that server addresses, local networks, QR payloads,
and incoming Link messages may be hostile.

## Connection rules

- Public DNS names require HTTPS.
- HTTP is accepted only for loopback, RFC 1918 IPv4, link-local IPv4, `.local`
  hostnames, and local or unique-local IPv6 addresses.
- Credentials embedded in URLs are rejected.
- Redirects are not followed during server identity validation.
- Invalid public TLS certificates are never accepted silently.
- Explicit self-signed certificate support must show and confirm a fingerprint
  before any credential is sent.
- A reconnect must prove the stored server ID before the client uses device
  credentials.

## Secrets

Android private keys are generated in Android Keystore. iOS private keys and
tokens are stored in Keychain. Logs, analytics, crash metadata, exported
diagnostics, and UI errors must redact tokens, private keys, pairing secrets,
authorization headers, and full sensitive payloads.

## Capabilities and commands

The client advertises only implemented capabilities available in its current
permission and OS state. Commands are allowlisted by capability, checked for
protocol compatibility and expiry, and deduplicated by command ID. Revocation
removes local credentials and ends active connectivity.

## Current boundary

This repository currently validates server identity metadata but does not yet
submit pairing secrets. Pairing will be enabled only after the canonical server
endpoints and schemas are implemented and released.
