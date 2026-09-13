# Repository conventions

- Write documentation, code comments, UI source strings, and commit messages in English.
- Do not add tool or generator attribution to repository content or commit messages.
- Present HomePlace as a standalone self-hosted product.
- Keep Android and iOS interfaces native. Share protocol fixtures and terminology, not UI abstractions.
- Treat the HomePlace server repository as the canonical source for HomePlace Link schemas and API behavior.
- Store credentials only in Android Keystore or iOS Keychain and never log sensitive payloads.
- Advertise only capabilities that are implemented and available on the current OS version.
- Commit with `Olmae <sviteyo@gmail.com>` and push completed, validated milestones to the configured upstream.
