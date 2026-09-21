# Repository conventions

- Write documentation, code comments, UI source strings, and commit messages in English.
- Do not add automated-generation attribution to repository content or history.
- Present HomePlace as a standalone self-hosted product.
- Use Flutter for shared UI, state, networking, protocol models, and application logic.
- Keep Kotlin and Swift integrations where the operating system requires native security or background APIs.
- Treat the HomePlace server repository as the canonical source for HomePlace Link schemas and behavior.
- Preserve `legacy/` until Flutter parity is implemented, tested, and reviewed.
- Store credentials only in Android Keystore-backed storage or iOS Keychain and never log sensitive payloads.
- Advertise only capabilities implemented on the current platform and OS version.
- Validate Android first, then iOS.
- Keep device capabilities and server action permissions separate. Clipboard reads must stay foreground-only and incoming clipboard writes must require an explicit user action.
- Keep Share Sheet content ephemeral and consent-driven. Require a named same-account target and send confirmation, require receiver acceptance, and never broaden delivery to every account on an installation.
- Seamless receiving is opt-in, foreground-only, and limited to integrity-checked files with a server-derived same-account marker. Household devices, URLs, text, and clipboard always require a specific user action.
- Commit with `Olmae <sviteyo@gmail.com>` and push completed, validated milestones to the configured upstream.
