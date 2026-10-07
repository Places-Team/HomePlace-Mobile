# Mobile navigation and transfer experience

Date: 2026-10-07
Status: Proposed for review

## Intent and scope

Keep the existing bottom pill and the native-feeling Flutter interface, but give
each destination one clear job. The immediate priority is a transfer experience
where a person can see an incoming offer, decide what to do, send to a named
device, and find a completed file without passing unrelated tools. This design
also removes duplicate notification entry points and reduces oversized headers
that hide useful content on a phone.

This is an information-architecture and interaction change to existing mobile
features. It does not introduce a new HomePlace Link protocol, broaden device
capabilities, or promise instant background delivery. The HomePlace server
repository remains the authority for event, transfer, account, and permission
behavior.

## Observed baseline

- The five main destinations are Home, Plan, Requests, Transfers, and Control;
  the rightmost pill button opens All sections. Retain those destinations and
  their one-handed reachability.
- Transfers currently interleaves incoming offers, outgoing queue, a temporary
  file exchange, clipboard controls, transfer activity, notification history,
  and a temporary text exchange in one long scroll. Notification history is
  duplicated in All sections.
- The same large APK was verified in `Downloads/HomePlace` on a Samsung, yet an
  offer remained visible. A second verified copy was created during testing
  and removed; a later retry failed before screen lock. This establishes a
  receipt/offer-state problem to investigate, not a proven cause of the earlier
  reported interruption near 80%.
- The current server file response is a full stream without HTTP Range support.
  True byte-range resume is outside this mobile-only change.

## Navigation map

| Destination | Primary responsibility | Direct content |
| --- | --- | --- |
| Home | Household tasks and plant care | Next actionable home item, plants, route into Plan |
| Plan | Date-based personal planning | Calendar, reminders, plants, ideas |
| Requests | Media and other server-backed requests | Request creation, status, recovery |
| Transfers | Addressed transfers between devices | Inbox, active progress, send composer, transfer history |
| Control | Operational monitoring | Health, services, containers, events with source/freshness labels |
| All sections | Infrequent destinations and settings | Devices, temporary exchange, integrations, security, settings |

The bottom pill retains its current five destinations plus the rightmost All
sections button. A section already present in the bottom pill does not appear
again as a destination in All sections. A detail page records its originating
destination, so system Back returns to that destination rather than closing
the app. An Android system share opens the Transfers send composer directly,
with the selected profile and previous navigation state retained.

Notification history has one global entry point: a bell in the shared header
beside Refresh. It opens a dedicated, profile-scoped history page. No full
notification feed appears in Transfers or All sections. A badge is shown only
if the app has a reliable, profile-scoped unread state; otherwise use an
unbadged bell. The existing error indicator remains distinct from the bell.

Temporary file and text links move to an **Exchange links** destination under
the sharing group in All sections. They retain their current account-only and
public-link warnings. Direct device offers never become public links, and a
temporary exchange never pretends to target a particular device.

## Transfers screen

The first viewport has a compact title, then the most urgent state:

1. **Inbox:** pending incoming files, text, and links from named devices.
   Each item shows sender, filename or safe preview, size when known, and
   Accept/Decline. A running download replaces those actions with determinate
   byte progress and Cancel. Household transfers never auto-accept. The
   opt-in, server-verified same-account file rule remains unchanged.
2. **Send:** one prominent action opens a bottom sheet with Photo, File,
   Text or link, and Send current clipboard. The last action is available only
   when foreground clipboard access and the user's relay setting permit it.
   Selecting content opens eligible named recipients and an explicit final
   confirmation. System Share Sheet content enters this same recipient flow.
3. **Recent:** a concise device-transfer history, with sent/received state,
   filename or content type, target/source, and time. A completed file offers
   visible Open and Folder actions. A successful receipt does not keep a
   Download action for the same event.

Only one primary action is visually dominant at a time. The empty state says
there are no pending transfers and still offers Send. Errors stay attached to
the relevant item with Retry or a recovery explanation; the global error
indicator remains for cross-screen failures. Pull-to-refresh remains
available, but it does not erase active progress.

The old permanent clipboard card is removed. Clipboard relay preferences live
with device-sharing settings; a received clipboard item still appears in the
Inbox and requires an explicit Copy action. Foreground-only reads, account
isolation, and consent remain unchanged.

## Transfer state and reliability boundary

Model an incoming file as offered, accepted, downloading, verifying, saving,
saved-awaiting-ack, completed, declined, cancelled, or failed. Persist a
profile-scoped receipt keyed by server ID, device ID, and event ID only after
the platform has saved a size- and SHA-256-verified file. The receipt holds
non-secret file metadata and a platform file handle, not credentials or file
contents. On restart, confirm the saved handle remains accessible before
suppressing that offer. Retry the server acknowledgement until confirmed; do
not start another download merely because the acknowledgement was delayed.
If the file is missing, show recovery instead of claiming it was downloaded.

The current in-app download is not handed off to Android's background worker.
Add that handoff only with a durable accepted-transfer record and test it as
a separate increment; Android scheduling and battery policy still apply. The
UI must show only real byte progress. A failed or interrupted transfer must
remain recoverable; without server Range support a retry starts from zero and
says so. Introduce resumable byte ranges only in a separate server-backed
protocol change. Do not advertise equivalent iOS background behavior unless
it is implemented and validated on iOS.

## Visual and motion rules

The detailed visual language, screen compositions, gestures, and plant-care
interaction are defined in the companion
[Home Atlas visual and interaction design](2026-10-07-home-atlas-visual-design.md).

Use one compact shared header with app identity, connection/error state, bell,
and Refresh. Section titles are concise and descriptive; avoid repeating
HomePlace or using metaphorical health labels in place of actual data. Maintain
the current warm light and dark palettes, but use fewer simultaneous accent
colors and fewer nested rounded cards. Distinguish sections by typography,
spacing, and restrained surface color rather than a stack of equal cards.

Preserve the bottom pill's active-state feedback. Use approximately 100–150 ms
for presses and 200–300 ms for short section/state changes; do not animate
large page layouts or expensive blur during tab switching. Respect the OS
reduced-motion setting. Keep 44-point-equivalent touch targets, scalable text,
semantics for icon-only actions, and both English and Russian strings. The
active transfer state remains readable without animation.

## Component boundaries

- The shell owns bottom navigation, shared header, notification route, and
  return-to-origin behavior. It does not own transfer protocol decisions.
- The Transfers feature owns inbox/send/recent presentation and a small
  transfer-state view model. It consumes connection events and existing
  sharing APIs rather than redefining Link payloads.
- Exchange links keeps its existing server-backed file/text controls in one
  separate destination.
- A receipt store records verified local file completion and pending
  acknowledgement for the active connection profile. It contains no secret.
- Kotlin remains responsible for Android file saving, background work,
  notifications, and system Share Sheet integration. Swift remains responsible
  for iOS-only system services. Shared Flutter code never claims unsupported
  platform behavior.

## Delivery and validation

Implement as reviewable increments: (1) visual tokens, compact shell/header,
and return navigation, (2) Home/Plan plant-care interaction, (3) Transfers
and Exchange links separation, (4) receipt/acknowledgement recovery, and
(5) remaining screen and motion polish. Keep existing native and Flutter
functionality available during each increment.

Automated checks cover navigation destinations and Back, transfer action
visibility, permission-dependent clipboard controls, server/profile isolation,
verified receipt persistence and acknowledgement retry, and localization.
Run Flutter analysis and tests, then build and exercise Android first. On a
fresh Samsung file offer, verify Accept, progress, lock/unlock behavior,
completion, Open/Folder, restart, and no repeated download offer. Test a
failed download and an unavailable server separately. iOS layout and
capability parity follow only after Android validation; record any untested
physical-device behavior explicitly.

## Non-goals

No new public file sharing by default, no silent household acceptance, no
background clipboard reads, no fabricated monitoring metrics, no new Link
capabilities, and no claim of byte-range resume or guaranteed instant push.
