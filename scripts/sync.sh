#!/usr/bin/env bash
# Sync canonical rule files from _shared/ into each skill.
#
# Source of truth: _shared/{style,guidelines,errors,concurrency,performance,testing}.md
# Targets: uber-go-style/, go-style-review/
#
# Usage:
#   scripts/sync.sh           # copy _shared/ → each skill
#   scripts/sync.sh --check   # exit non-zero if any skill is out of sync

set -euo pipefail

SHARED_DIR="_shared"
SKILLS=(uber-go-style go-style-review)
FILES=(style.md guidelines.md errors.md concurrency.md performance.md testing.md)

cd "$(git rev-parse --show-toplevel)"

if [[ ! -d "$SHARED_DIR" ]]; then
  echo "error: $SHARED_DIR not found at repo root" >&2
  exit 1
fi

mode="copy"
if [[ "${1:-}" == "--check" ]]; then
  mode="check"
fi

drift=0
for skill in "${SKILLS[@]}"; do
  for f in "${FILES[@]}"; do
    src="$SHARED_DIR/$f"
    dst="$skill/$f"

    if [[ "$mode" == "check" ]]; then
      if ! diff -q "$src" "$dst" >/dev/null 2>&1; then
        echo "drift: $dst differs from $src"
        drift=1
      fi
    else
      cp "$src" "$dst"
    fi
  done
done

if [[ "$mode" == "check" ]]; then
  if [[ $drift -ne 0 ]]; then
    echo "Run scripts/sync.sh to fix." >&2
    exit 1
  fi
  echo "All skills in sync with $SHARED_DIR."
else
  echo "Synced $SHARED_DIR/ → ${SKILLS[*]}"
fi
