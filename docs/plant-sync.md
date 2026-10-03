# Plant synchronization

HomePlace server is the canonical source of the `/api/link/plants` contract. The
mobile client uses this API only when the paired device has `plants.manage`.

Existing local plant cards and photos remain on the device until the user opts
to import them. Importing existing photos requires a separate confirmation and
never removes the local originals. New shared cards, edits, watering, deletion,
and photo changes use a durable local queue. Conflicts require an explicit
choice; a failed or offline upload remains queued.

Private photos are transferred through authenticated, account-scoped endpoints.
Binary requests retain the connection's TLS validation and response limits.
Downloaded photos are cached in a credential-scoped directory. A server photo
version is a generated image filename, not an integer counter. Neither account
changes nor re-pairing reuse another credential's photo cache.

Reminder channels, time, and repeat interval can be configured when the server
advertises `plantReminders`. Telegram delivery is opt-in. Notification taps can
open the corresponding plant card. Android and iOS notification delivery still
depends on their respective platform permissions and background restrictions.
