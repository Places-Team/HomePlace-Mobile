# Mobile experience map

This is the product layout for the Flutter application, not a claim that every
server feature exists. The HomePlace server repository defines Link behavior.
Keep preview destinations visibly labeled until a compatible server endpoint
and a tested mobile implementation are available.

## Navigation model

The five destinations in the bottom pill are **Home**, **Plan**, **Requests**,
**Transfers**, and **Monitor**. The rightmost button in the same bottom pill
opens **All sections** for one-handed access. Settings and connection management
are available from that directory. An incoming Android system share opens Transfers and recipient
selection directly, without resetting the selected connection or landing on
Home first. Returning from a detail screen preserves the selected tab.

| Place | Primary question | Belongs here | Does not belong here |
| --- | --- | --- | --- |
| Home | What needs doing around my home? | Plant care, the nearest home task, entry to the plan | Telegram connection, clipboard relay, container counts, raw diagnostics |
| Plan | What needs a date or a place to start? | Calendar, reminders, plant watering, private ideas | Server configuration |
| Requests | What did I ask HomePlace to do? | Existing media requests and their status | Home chores or file inbox |
| Transfers | What am I sending or receiving? | Named devices, explicit share confirmation, files, links, text, Android clipboard, transfer history | Monitoring graphs |
| Monitor | Is HomePlace healthy? | Service/container state, health checks, recent events, drill-down diagnostics | Household chores |
| All sections | Where is a less-frequent tool? | Ideas, devices, notification history, Telegram, media, smart home preview, automations preview, security, settings | A second competing home dashboard |

## Screen sketches

These sketches describe hierarchy and interactions, not fixed pixel geometry.
Each screen supports loading, empty, error, offline, and permission-limited
states. Keep the pill reachable with large text and system font scaling.

### Home

```text
┌ HomePlace / current home                      Sections  Settings ┐
│ Everything in its place                                         │
│ Plants and the next thing to do at home.                       │
│                                                                │
│ ╭ Plant care ─────────────────────────────── All plants → ╮    │
│ │ Due / upcoming plants, photo, watering status           │    │
│ │ Tap card for details; water with undo                    │    │
│ ╰───────────────────────────────────────────────────────────╯    │
│                                                                │
│ Next up                                             Plan →      │
│ ╭ Date / nearest calendar event or active reminder ───────╮    │
│ ╰───────────────────────────────────────────────────────────╯    │
│                                                                │
│     Home       Plan       Requests       Transfers       Monitor│
└────────────────────────────────────────────────────────────────┘
```

Plant records and photos are private to this app's current connection profile.
They are not family-shared or backed up by the HomePlace server. The nearest
task uses the active server profile's calendar/reminder response; an empty
server response must say that nothing is planned. Future household modules
should earn a place here only when they expose a useful, real, everyday action.

### Plan

```text
Four icon modes with accessible labels → calendar, reminders, plants, ideas
Calendar mode → month selector → chosen day → day's calendar events
Reminders mode → past due first → upcoming → expandable completed history
Create / edit → date, time, repeat interval, save / delete
Plants mode → watering timeline → plant details or mark watered
Ideas mode → quick capture → category filter → edit / duplicate / delete
Idea action → prefill the server-backed reminder editor without deleting the idea
```

Calendar and reminders are server-backed and permission-gated. Plant watering
and ideas are local. Ideas use platform-secure storage scoped to the paired
server and device; they do not sync with Desktop or the server yet. The modes
keep those sources and storage boundaries clear. Flexible reminder recurrence
must use the server's supported format; the UI must not promise schedules it
cannot save.

### Requests

```text
Request status and recent actions
Create media request → choose supported target → confirm
Each request → state, relevant details, retry or recovery when allowed
```

Keep media actions in Requests, not Home. Display only integrations and actions
returned by the current server and allowed for this user. Never invent a
completed request when the server has not acknowledged it.

### Transfers

```text
Incoming offers first → accept or decline → progress → verify → open saved file
Outgoing queue → choose a named authorized recipient → confirm send
Android clipboard → foreground send / explicit received copy
Recent transfer activity and notification history
```

Do not preselect a household device for a file transfer. A same-account
seamless receive option is separate from household sharing and stays opt-in.
Successfully saved files must not be offered for download again. iOS should
only show clipboard or background options it actually implements.

### Monitor

```text
Summary → health and availability checks, time of last refresh
Containers → actual container inventory and state
Services → configured monitored services and response details
Events → recent operational changes and drill-down diagnostics
```

An availability-check count is not a container count. Label each data source
and freshness. If a read-only endpoint is missing, show a useful unavailable
state rather than a fabricated metric. Technical errors remain one tap away,
without transient banners covering routine navigation.

### All sections and settings

All sections groups everyday tools, sharing, services, and system controls.
On narrow windows it uses compact grouped rows so titles and availability
remain easy to scan; wider windows use two-column cards. The layout responds
to available width rather than device model or orientation.
Telegram lives in Services: show its actual connection state and the permitted
test action. It is never a Home card. Devices shows the active account's
authorized devices, not all devices on an installation. Notification history
is local. Smart Home and Automations remain marked previews until canonical
server APIs and permissions exist. Settings holds language, notifications,
privacy/background options, connection identity, disconnect/revoke, and
troubleshooting. Destructive or cross-device actions need explicit confirmation.

## Delivery status and boundaries

| Area | Current mobile state | Next useful increment |
| --- | --- | --- |
| Connection and pairing | Implemented for supported Link v1 servers | Recheck recovery copy and real TLS/identity failures |
| Plants | Local cards, photos, interval, watering and undo | Opt-in local watering alerts with native scheduling and permission checks |
| Ideas | Private local capture, categories, editing and reminder handoff | Connect to a canonical, account-scoped server API when it exists; plan conflict handling and migration before enabling sync |
| Calendar and reminders | Server-backed viewing and editing | Refine day agenda and recurrence validation against current server |
| Requests | Existing server-backed media actions | Improve per-request status and actionable failures |
| Files, links, text | Recipient selection, confirmation, receiving and save flow | Validate large-file and background paths on real devices |
| Android clipboard | Foreground relay and explicit copy | Keep platform restrictions visible; no silent background reads |
| Monitor | Server-backed dashboard and read-only drill-down | Improve freshness and source labels on each metric |
| Telegram | Server status and permitted test in Services | Only add account management if canonical APIs support it |
| Smart Home / Automations | Labeled previews | Wait for server contracts before claiming control |
| iOS platform behavior | Native build and supported Link behavior | Verify parity on a physical iPhone before advertising more capabilities |

## Design rules

On Android, launcher shortcuts open Ideas and Transfers after the saved
connection has been restored; they do not bypass pairing or share confirmation.

The Home screen is calm and task-first: one visual hero for plant care, one
nearest-action block, generous breathing room, and no row of infrastructure
numbers. Reuse the app's distinctive violet/coral/mint accents sparingly;
plant care uses a quieter green surface. Motion communicates state changes
(tab movement, watering completion, undo), not decoration. Use explicit labels,
44-point or larger touch targets, semantic icons, text scaling, dark/light
surfaces, and both English and Russian copy. No fake data or dead buttons in
preview screens.
