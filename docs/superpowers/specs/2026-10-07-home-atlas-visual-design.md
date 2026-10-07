# Home Atlas visual and interaction design

Date: 2026-10-07
Status: Proposed for review
Companion: [Mobile navigation and transfer experience](2026-10-07-mobile-navigation-and-transfer-design.md)

## Design intent

HomePlace should feel like a distinctive, calm place for the user's home,
not a stack of default dashboard cards. The user should immediately know what
needs attention, where an action will go, and what happened after acting.
Keep the existing bottom pill, native Flutter UI, English/Russian localization,
and all security and permission boundaries in the companion specification.

The visual direction is **Home Atlas**: an editorial field guide for a living
home. It combines warm paper-like surfaces, precise dark typography, real
plant photographs, and a few tactile interactions. It is neither a dark
server terminal nor a constantly animated game. A successful design feels
recognizable without making routine tasks slower.

## Current UI diagnosis

The current light theme has a useful warm base and a recognizable CatBox mark.
However, most screens repeat the same large heading, explanatory paragraph,
rounded rectangle, and oversized vertical gap. Important actions fall below
the bottom pill. Plan gives most of its first viewport to a month grid, even
when the user wants today's agenda. Transfers mixes addressed offers,
temporary links, clipboard, and notification history. Watering a plant is a
button in a bottom sheet followed by a generic snackbar. These patterns make
the product feel less specific than its capabilities deserve.

## Visual language

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| Canvas | `#F6F2E8` | `#121A17` | Main background |
| Raised paper | `#FFFCF5` | `#1C2822` | Focused action areas |
| Ink | `#1D2922` | `#EDF2EB` | Primary text and icons |
| Quiet ink | `#57665B` | `#B5C4B8` | Secondary text |
| Evergreen | `#2E6048` | `#A8D3B7` | Primary action and selected state |
| Clay | `#A64F35` | `#F0A58C` | Due/attention only, never decoration |

The exact tokens must pass contrast checks in their final Flutter usage;
adjust values rather than relying on opacity for small text. Keep warning and
error colors semantic. Do not use per-tab rainbow backgrounds or gradients.
Section identity comes from composition and a restrained motif: a botanical
stem in Home, a ruled date spine in Plan, a route line in Transfers, and
instrument ticks in Control. Motifs are static vectors or simple painters,
never animated full-screen backdrops.

Use one Cyrillic-capable, high-legibility sans family for controls and body
copy (candidate: Onest) and a restrained editorial serif for large section
headings only (candidate: Literata). Verify font licenses, Cyrillic coverage,
bundle size, and text scaling before adding assets; fall back to platform
fonts if a candidate fails. The large heading is an accent, not a repeated
hero taking a quarter of every screen. Numbers in monitoring and progress use
tabular figures.

Derive a subtle angled shoulder from the CatBox logo for a limited set of
hero surfaces. Ordinary rows stay flat; inner controls have tighter corners
than their containing surface. Avoid a border and shadow on every item.
Photographs come from the user's plants. Never substitute unrelated stock
imagery for a missing photo; use a purposeful botanical illustration or
initial-based placeholder instead.

## Shared shell

The shared header is one compact row: CatBox mark and the current destination
or connected home's name on the left; error indicator when needed, bell for
notification history, and Refresh on the right. Do not print HomePlace twice.
The bell is unbadged unless unread state is reliably profile-scoped. Header
actions have accessible labels and remain reachable when text scales.

The bottom pill keeps five destinations and the rightmost All sections button.
Its selected region moves with a short, interruptible translation rather than
rebuilding or fading the whole screen. Main-tab changes happen by tapping the
pill; horizontal gestures belong to local content such as the date rail or
plant gallery, avoiding nested swipe conflicts. A detail view returns to its
originating tab through system Back. Scroll position and loaded data survive
tab changes.

## Screen compositions

### Home

Start with a small date and a concise `Home` title, not a slogan. The first
viewport has one asymmetric plant-care feature: a real photo or illustrated
placeholder, the number due, and a clear `Care for plants` action. A horizontal
strip of at most three due plants follows; each tile states the next watering
date. The next household action is a short agenda row below. If nothing is
due, the surface becomes a calm next-watering preview rather than a large
empty card. Telegram, clipboard, and infrastructure counts never appear here.

### Plan

Keep four icon modes for Calendar, Reminders, Plants, and Ideas, with readable
semantic labels. Default Calendar shows a seven-day rail and the selected
day's agenda; expanding the rail reveals the full month without pushing all
events below the fold. Drag or swipe the rail to change weeks with one snap
and a light selection haptic, then tap a day to inspect it. Reminders separate
overdue, upcoming, and completed states without nested card stacks. The
content is navigable by buttons and screen reader without the gesture.

### Requests

Use a compact search and filter strip above a readable list of real media
results. Poster size, title, status, and next available action carry the
hierarchy; omit a large introductory paragraph on every visit. Request
submission gets a clear pending/confirmed/failed state tied to the server
response. No decorative success animation before acknowledgement.

### Transfers

Use the companion spec's Inbox, Send, Recent hierarchy. An incoming offer is
visually a short path from the sender's device glyph to this phone, with the
name and file type as primary text. Accept/Decline are always explicit.
Sending opens a low, one-handed composer; choosing a named recipient stages
the route, and the route animates only after final confirmation. During a
download, a dot travels along the route according to actual verified byte
progress. `Verifying` and `Saving` are separate textual stages; neither
pretends to be extra download percentage. The saved state exposes Open and
Folder. Temporary links live in Exchange links, not this screen.

### Control and All sections

Control opens with a compact honest health statement and last-refresh time.
Availability checks, Docker containers, monitored services, and events are
separate named views; the same `11 online` number is not repeated as a
container count. Use tabular figures and quiet instrument marks, not a wall
of brightly colored metric cards. All sections is a compact, scannable
directory of destinations absent from the bottom pill. Preview modules remain
visibly previews, not fake controls.

## Signature plant-care interaction

In a plant detail page, place a droplet handle within the lower thumb zone and
a visible soil/watering target on the plant portrait. Holding then dragging
the droplet into the target gives a small threshold haptic and fills a thin
water path. Release inside the target invokes the existing water action once.
Releasing outside returns the droplet without a write. A persistent, plainly
labeled `Watered today` button performs the same action for accessibility,
large text, or users who prefer tapping. Neither the gesture nor animation is
required to use the feature.

After the local save succeeds, show a short ripple in the portrait, a slight
leaf lift, and the recalculated next-watering date. If a server sync is
pending, say `Saved on this device · Waiting to sync`; do not claim remote
completion. If saving fails, return to the previous state with an inline
error. Offer `Undo` for at least five seconds and retain the previous
watering timestamp so it can be restored. Repeated drags while saving are
ignored, preventing duplicate writes. The animation is feedback, not a
blocking screen or an unbounded particle effect.

## Other gestures and motion

- A short press state (100–150 ms) confirms touch. Destination changes and
  expanding content take roughly 200–300 ms, remain interruptible, and use
  translation/opacity rather than large relayout or blur.
- Swipe on a reminder or transfer row may reveal secondary actions, but never
  deletes, declines, or sends immediately. Every revealed action also has a
  visible menu or button alternative.
- A completed transfer route settles once, with a light haptic. Progress never
  runs ahead of actual bytes or restarts as a decorative loop.
- Empty states explain the next useful action. Loading preserves the shape of
  content without indefinitely blocking the bottom navigation.
- Respect the platform reduced-motion preference: replace travel/ripple with
  an immediate state change. Haptics respect device settings. No autoplay
  motion continues while a screen is idle.

## Accessibility, privacy, and performance

All actions remain operable without gestures or haptics. Interactive targets
are at least 44 logical points, semantic labels describe icon-only controls,
and headings, file names, and dates survive enlarged text without clipping.
Test both languages and light/dark mode. Do not show sensitive transfer
previews on the lock screen or animate private content into another profile.

Keep animation controllers local to visible widgets, pause them offscreen,
avoid whole-page animated backgrounds, and preserve tab state instead of
refetching on every switch. Measure tab changes, plant watering, and transfer
progress in Flutter profile mode on the Android emulator and Samsung at its
selected refresh rate. Compare frame timing with the current app; any
repeatable jank must be reduced before release. iOS gets the same visual
language, but platform-specific gestures and background claims require
separate device validation.

## Acceptance examples

1. On Home, a person can identify the next plant needing water and the next
   household action without scrolling past a large introduction.
2. A plant can be marked watered by gesture or button. Cancelled drag writes
   nothing; success updates its next date; Undo restores the previous date.
3. A shared file opens to a named-recipient flow, requires confirmation, and
   displays real progress without exposing unrelated temporary-link tools.
4. A notification is reachable from the common header, not duplicated inside
   Transfers or All sections.
5. At enlarged text and reduced motion, every action and state remains clear.
6. Android tab switching and the plant interaction are measured on device;
   the redesign does not reintroduce the reported frame drops.

## Non-goals

No gamified plant scoring, no simulated growth unrelated to saved watering
state, no hidden-only gestures, no automatic household file acceptance, no
full-screen animation system, and no unsupported iOS background behavior.
