# Architecture

HomePlace Mobile contains two native applications that follow the same product
language and HomePlace Link contract without sharing UI code.

## Boundaries

Each application is divided into four responsibilities:

1. **UI and state** own onboarding, permission explanations, progress, and
   actionable error presentation.
2. **Protocol** owns versioned request and response models plus compatibility
   checks. Canonical schemas remain in the HomePlace server repository.
3. **Networking** owns URL normalization, TLS policy, redirects, timeouts, and
   Link API transport.
4. **Secure storage** owns device keys, tokens, and credential references using
   the platform security APIs.

Platform background behavior stays platform-specific. Android may offer a
user-enabled foreground service. iOS reports foreground and background
capabilities according to the APIs the operating system actually permits.

## Connection state

The initial connection flow is a finite state machine:

`welcome → address entry → validating → server preview → pairing → connected`

Every network state has a timeout and a recoverable error path. A successful
server preview records no secret. Persisted connection profiles store server
identity and URL metadata separately from credentials.

## Dependencies

Dependencies are injected at application boundaries. Android ViewModels accept
repository interfaces and iOS observable models accept protocol-conforming
clients. Tests can therefore use deterministic transports without weakening
production TLS or secure-storage behavior.
