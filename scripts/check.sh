#!/bin/sh
set -eu

root_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

if rg -n -i --glob '!.git/**' --glob '!scripts/check.sh' \
  '(api[_-]?key|private[_-]?key|client[_-]?secret)[[:space:]]*[:=][[:space:]]*[^[:space:]$<{]+' "$root_dir"; then
  echo "Possible committed secret found." >&2
  exit 1
fi

if rg -n --glob '*.md' --glob '*.kt' --glob '*.kts' --glob '*.swift' '[[:blank:]]+$' "$root_dir"; then
  echo "Trailing whitespace found." >&2
  exit 1
fi

echo "Repository checks passed."
