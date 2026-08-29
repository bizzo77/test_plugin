#!/bin/bash
# Refuses a write that would rebuild one of the four files this brain came with.
#
# There was a warning for this after the write. It was not enough: on 29 August 2026 the
# brain rewrote About me.md, was told three headings had gone, and carried on. A message
# the assistant can read and ignore is not a guarantee. This refuses the write instead.
#
# Exit code 2 blocks the write and hands the reason back.
#
# It can only do this for a whole-file write, which is the case that caused the fault.
# A small edit does not carry the whole file, so that is still caught by the check that
# runs afterwards.

set -u

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
SHIPPED="$ROOT/.brainbox/shipped-headings.txt"
[ -f "$SHIPPED" ] || exit 0

INPUT="$(cat)"

FP="$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
[ -n "$FP" ] || exit 0
NAME="${FP##*/}"

case "$NAME" in
  "About me.md"|"CLAUDE.md"|"Catalogue.md"|"START HERE.md") ;;
  *) exit 0 ;;
esac

MISSING=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  FILE="${line%%:*}"
  [ "$FILE" = "$NAME" ] || continue
  HEADING="${line#*:}"
  printf '%s' "$INPUT" | grep -qF "$HEADING" || MISSING="$MISSING  - ${HEADING#\#* }
"
done < "$SHIPPED"

[ -n "$MISSING" ] || exit 0

{
  echo "Blocked. This write would take things out of $NAME, which came with this brain."
  echo "Missing from what you were about to save:"
  printf '%s' "$MISSING" | head -12
  echo "Write it again with those kept, spelled exactly as they are now, and put whatever you"
  echo "wanted to add underneath the heading that is already there. Do not consolidate them"
  echo "into a heading of your own."
  if [ "$NAME" = "About me.md" ]; then
    echo "Each of those headings is a question you still owe this person. Removing one is"
    echo "deciding never to ask it, and nothing afterwards would say so."
  fi
} >&2
exit 2
