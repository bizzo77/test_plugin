#!/bin/bash
# Refuses a write or an edit that would take something out of the files this brain came with.
#
# There was a warning for this after the write. It was not enough: on 29 August 2026 the
# brain rewrote About me.md, was told three headings had gone, and carried on. A message
# the assistant can read and ignore is not a guarantee. This refuses instead.
#
# Exit code 2 blocks and hands the reason back.
#
# Two shapes are handled:
#   a whole-file write - judged against every heading the file came with
#   a small edit       - judged on whether the piece being replaced contains one of them
# and separately, the two files that hold the brain's voice.

set -u

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
SHIPPED="$ROOT/.bizbrain/shipped-headings.txt"

INPUT="$(cat)"

FP="$(printf '%s' "$INPUT" | sed -n 's/.*"file_path"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
[ -n "$FP" ] || exit 0
NAME="${FP##*/}"

# --- The brain's own voice. Losing it is the worst thing that can happen to how it talks. ---
case "$FP" in
  *".claude/settings.json")
    printf '%s' "$INPUT" | grep -qF "BizBrain" && exit 0
    echo "Blocked. That would switch off this brain's voice. Leave the outputStyle set to" >&2
    echo "BizBrain." >&2
    exit 2 ;;
  *".claude/output-styles/bizbrain.md")
    printf '%s' "$INPUT" | grep -qF "name: BizBrain" && exit 0
    echo "Blocked. That would break this brain's voice file. It must keep its name line." >&2
    exit 2 ;;
esac

[ -f "$SHIPPED" ] || exit 0

case "$NAME" in
  "About me.md"|"CLAUDE.md"|"Catalogue.md"|"START HERE.md") ;;
  *) exit 0 ;;
esac

# A small edit sends only the piece being swapped. If a heading is in the part being taken
# out and not in the part going back, it is being removed.
OLD="$(printf '%s' "$INPUT" | sed -n 's/.*"old_string"[[:space:]]*:[[:space:]]*"\(.*\)"[[:space:]]*,[[:space:]]*"new_string".*/\1/p' | head -1)"
IS_EDIT=0
case "$INPUT" in
  *'"old_string"'*)
    # It is an edit. If the piece being swapped cannot be read, allow it. A false block
    # stops the brain doing its job, which is worse than the fault this guards against.
    [ -n "$OLD" ] || exit 0
    IS_EDIT=1 ;;
esac

# What we search for the heading. For an edit that has to be the replacement text only -
# the piece being taken out obviously still contains the heading being taken out.
HAY="$INPUT"
[ "$IS_EDIT" = "1" ] &&
  HAY="$(printf '%s' "$INPUT" | sed 's/.*"new_string"[[:space:]]*:[[:space:]]*//')"

MISSING=""
while IFS= read -r line; do
  [ -z "$line" ] && continue
  FILE="${line%%:*}"
  [ "$FILE" = "$NAME" ] || continue
  HEADING="${line#*:}"
  if [ "$IS_EDIT" = "1" ]; then
    # only judge headings that the edit actually touches
    printf '%s' "$OLD" | grep -qF "$HEADING" || continue
  fi
  printf '%s' "$HAY" | grep -qF "$HEADING" || MISSING="$MISSING  - ${HEADING#\#* }
"
done < "$SHIPPED"

[ -n "$MISSING" ] || exit 0

{
  echo "Blocked. That would take things out of $NAME, which came with this brain."
  echo "Missing from what you were about to save:"
  printf '%s' "$MISSING" | head -12
  echo "Do it again with those kept, spelled exactly as they are now, and put whatever you"
  echo "wanted to add underneath the heading that is already there. Do not consolidate them"
  echo "into a heading of your own."
  if [ "$NAME" = "About me.md" ]; then
    echo "Each of those headings is a question you still owe this person. Removing one is"
    echo "deciding never to ask it, and nothing afterwards would say so."
  fi
} >&2
exit 2
