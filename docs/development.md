# Development workflow

Keep changes scoped to one platform or shared protocol documentation where
possible. Before opening a pull request:

1. Run `scripts/check.sh`.
2. Run the platform build and unit tests.
3. Confirm no signing files, tokens, local URLs, or credentials are staged.
4. Describe any validation that could not run on the current machine.

English and Russian user-facing strings belong in platform localization files
from the first screen onward. Technical diagnostics should be concise, redacted,
and separate from the primary recovery message.
