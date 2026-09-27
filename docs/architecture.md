# Architecture

The user-facing tab and module hierarchy is documented in
[`mobile-experience-map.md`](mobile-experience-map.md). Its previews are not
protocol contracts; only the HomePlace server defines Link behavior.

HomePlace Mobile uses one Flutter application for Android and iOS. Shared Dart code owns product UI and Link behavior; Kotlin and Swift own security and system integration that cannot be represented faithfully as shared application logic.

## Layers

1. `lib/main.dart` and `lib/features/` own localized UI, the finite connection state machine, the mobile dashboard state, the five-tab navigation shell, and the full module map.
2. `lib/link/` owns client-side models, compatibility checks, pairing, heartbeat, authenticated mobile actions, and event transport.
3. `lib/core/network/` owns address normalization and connection security classification.
4. `lib/core/storage/` separates non-secret connection profile metadata from credentials.
5. `android/` and `ios/` expose native identity keys and platform services through narrow Flutter channels and plugins.

The HomePlace server remains canonical for Link schemas and endpoint behavior. Mobile models intentionally validate only the subset required by the supported protocol version.

## Connection state

`welcome → address → validating → preview → pairing → connected`

Network requests have bounded timeouts and explicit error paths. Pairing secrets exist only for the short pairing session. A persisted profile records the server ID, URL, device ID, security state, and optional certificate fingerprint; its credential is stored separately.

On reconnect, the client requests `/api/link/info` before using the saved credential and stops if the server ID differs. Foreground heartbeat delivers allowlisted events and acknowledges their IDs on the next request.

After pairing, `HomeController` reads the authenticated mobile overview and refreshes it every 30 seconds while the application is open. Calendar, reminders, media requests, Telegram, and monitoring reuse server-owned services and models. Reminder history includes upcoming, overdue, and completed items; every mutation remains scoped to the paired user's ID on the server. The app does not keep a competing local source of truth.

The five bottom destinations remain task-oriented: Home, Plan, Requests,
Transfers, and Control. The bottom-pill module directory exposes the broader product
architecture without squeezing more destinations into the bottom pill. Live
cards route to existing features; Devices, Notifications, and Security render
only data already returned for the active profile. Automations and Smart Home
are interaction previews marked as waiting for compatible server APIs. Preview
screens never advertise capabilities, fabricate device state, or send actions.

On Android, `ACTION_SEND` and `ACTION_SEND_MULTIPLE` intents are reduced to bounded text, HTTP(S) URLs, or private cache files. A batch contains at most ten items and 500 MB total. Shared Dart UI queues every item in the transfer center, moves directly to Transfers, filters the server-provided authorized device list by real receiver capability, identifies household targets, and presents explicit named-recipient selection and confirmation before upload. Successfully sent items leave the queue; a failed item and everything after it remain available for retry. The receiving device accepts or declines each server offer from the transfer center or private notification actions. Files up to 500 MB are streamed in both directions. Android creates the destination temporary file inside the application's canonical cache directory before Flutter downloads into it; exact size and SHA-256 are verified before the Android host copies it to `Downloads/HomePlace` and returns a scoped `content://` handle for the Open action. The same bounded pipeline is available to a headless WorkManager engine through a registered Android storage plugin. The event is acknowledged only after that save succeeds. An opt-in seamless path can request this acceptance automatically only when the canonical server marks both devices as belonging to the same account; household devices always require explicit confirmation.

The Control screen splits the canonical dashboard response into summary,
container, monitored-service, and event views. Availability-check totals never
claim to be container totals. Container state and health come from the server's
configured read-only Docker endpoints. The client derives aggregate counts and
average latency only from the current response and does not create a competing
monitoring data source.

## Local plant care

Plant cards are a device-local feature. `PlantStore` persists bounded metadata in application preferences and optional photos in private application documents. The storage namespace is a hash of the saved server and paired device IDs, so another connection profile cannot display the same cards. The Home page shows the nearest watering dates; Plans shows the same local schedule beside server-backed calendar and reminders. Watering an item updates its last-watered date and derives the next date from a 1–90 day interval. No plant record is sent to HomePlace Link or advertised as a server capability because the canonical server has no plant API.

Saved profiles restore on startup. A failed connection check enters a retry state that keeps the saved address and credentials. The client still checks `/api/link/info` and the server ID before using credentials. Entering a different address remains an explicit choice.

## Ideas

The Transfers page offers temporary account-only text exchanges through the
canonical server `/api/exchange` routes. It never creates a public link from
this control. The bearer URL is copied only on request; when automatic
clipboard relay is enabled, copying requires an extra warning. Active links
are fetched with the paired device's `share.relay` permission and can be
revoked. Expiry and one-time-open behavior are server-authoritative. This
does not replace direct addressed Link offers, and exchange text is not
persisted in mobile preferences or transfer history.


The Ideas workspace follows Desktop's quick-capture workflow.
`IdeaController` owns UI state and validation; `IdeaStore` separates
persistence. New pairings request `ideas.manage`. `ServerIdeaStore` uses
the canonical `/api/link/ideas` route for account-scoped categories and
ideas, including paginated reads and authenticated changes. An uncertain
write must be refreshed before another change to avoid a blind retry.

`SecureIdeaStore` remains available to older pairings without Ideas
permission. Its versioned data stays in Android Keystore-backed storage
or iOS Keychain under a server-and-device-scoped key. When server access
is granted, an explicit, idempotent import copies local ideas without
deleting the phone data. The server is authoritative for synced ideas;
Desktop-only local records are not assumed to be server data.
While the app is open, each successful mobile overview refresh also reloads
account ideas when `ideas.manage` is granted. This includes foreground polling
and manual refresh, so Desktop changes appear without restarting mobile.
Failed refreshes do not replace cached ideas or upload local-only ideas.
Synced ideas retain Desktop notes, pin state, and completion state. Mobile
updates send only changed fields, leaving unrelated Desktop fields intact.
These advanced controls are hidden for local-only ideas because the canonical
legacy import accepts titles and categories only. Mobile reads both active
and archived pages from the server and can restore account ideas from archive.

## Native boundaries

- Android generates a P-256 identity key in Android Keystore. Narrow Kotlin channels perform foreground clipboard access, Share Sheet ingestion, safe URL opening, and confirmed file saving. A registered application-context plugin exposes only protected temporary-file creation and MediaStore saving to headless WorkManager engines. Workers periodically validate each server, deliver notifications, resolve declines, and download only explicitly accepted or server-verified same-account files. Launcher shortcuts open Ideas or Transfers only after the normal connection flow and grant no additional capability.
- iOS generates a P-256 identity key in Keychain. Notification, a future Share Extension, and permitted background behavior remain iOS-specific. The current iOS build does not advertise sharing capabilities.
- Shared code never claims unrestricted background execution, arbitrary app launching, or remote system control. Android clipboard relay is foreground-only and incoming text requires an explicit copy action. iOS does not advertise clipboard relay.

## Migration policy

The former native applications are preserved under `legacy/`. They are reference implementations, not build targets. Remove a legacy feature only after the Flutter equivalent has been implemented, covered by appropriate tests, and reviewed on its real platform.
