#!/bin/bash
# Runs after anything is written. Checks the two rules that are checkable:
# every file opens by saying what it is, and every file is in the catalogue.
#
# It only reports. It never changes a file. Silent when there is nothing to say.

set -u

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
CAT="$ROOT/Catalogue.md"
[ -d "$ROOT/.bizbrain" ] || exit 0

NO_OPENING=""
NOT_LISTED=""

while IFS= read -r f; do
  [ -f "$f" ] || continue
  NAME="$(basename "$f")"

  # Rule 6 - the first few lines say what it is, and carry a date.
  HEAD="$(head -6 "$f" 2>/dev/null)"
  if ! printf '%s' "$HEAD" | grep -Eq '[0-9]{4}|[0-9]{1,2} (January|February|March|April|May|June|July|August|September|October|November|December)'; then
    NO_OPENING="$NO_OPENING  - $NAME
"
  fi

  # Rule 7 - one save updates the catalogue too. Day pages are exempt: they are found by
  # their date, and a line a day would bury the catalogue within a month.
  case "$f" in
    "$ROOT"/Today/*) ;;
    *)
      if [ -f "$CAT" ] && ! grep -qF "$NAME" "$CAT"; then
        NOT_LISTED="$NOT_LISTED  - $NAME
"
      fi
      ;;
  esac
done <<EOF
$(find "$ROOT/Today" "$ROOT/People" "$ROOT/Projects" "$ROOT/Knowledge" "$ROOT/Decisions" \
      -type f -name '*.md' -mtime -2 2>/dev/null | head -60)
EOF

# --- Have any of the four shipped files been rewritten? ---
# About me.md, CLAUDE.md, Catalogue.md and START HERE.md came with this brain. The brain may
# add to them. It may not rebuild them around headings of its own, because whatever was under
# the old heading goes with it and nothing says so afterwards. Checked, not left to memory.
SHIPPED="$ROOT/.bizbrain/shipped-headings.txt"
if [ -f "$SHIPPED" ]; then
  MISSING=""
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    FILE="${line%%:*}"
    HEADING="${line#*:}"
    [ -f "$ROOT/$FILE" ] || continue
    grep -qF "$HEADING" "$ROOT/$FILE" || MISSING="$MISSING  - $FILE  ->  ${HEADING#\#* }
"
  done < "$SHIPPED"
  if [ -n "$MISSING" ]; then
    echo "STOP. Headings that came with this brain have gone:"
    printf '%s' "$MISSING" | head -14
    echo "Put them back, spelled exactly as they were. These four files came with the brain."
    echo "Add to them underneath the headings already there. Never rebuild one around headings"
    echo "of your own - whatever was under the old heading goes with it, and nothing afterwards"
    echo "says it was ever there. In About me.md a missing heading is a question you have"
    echo "quietly decided never to ask."
  fi
fi

# --- Is the brain's own voice still switched on? ---
# The voice is the one thing never lost when a long session is squeezed, so switching it off
# quietly is the worst thing that can happen to how this brain talks.
if [ -d "$ROOT/.claude" ]; then
  if [ ! -f "$ROOT/.claude/output-styles/bizbrain.md" ]; then
    echo "STOP. The brain's voice file .claude/output-styles/bizbrain.md has gone. Nothing"
    echo "works properly without it. Tell the owner, and do not carry on as if it is fine."
  elif ! grep -q "BizBrain" "$ROOT/.claude/settings.json" 2>/dev/null; then
    echo "STOP. .claude/settings.json no longer sets the BizBrain voice. Put it back:"
    echo '{ "outputStyle": "BizBrain" }'
  fi
fi

if [ -n "$NO_OPENING" ]; then
  echo "These files do not open by saying what they are and when. Fix them (rule 6):"
  printf '%s' "$NO_OPENING" | head -5
fi
if [ -n "$NOT_LISTED" ]; then
  echo "These files are missing from Catalogue.md. Add a line for each (rule 7):"
  printf '%s' "$NOT_LISTED" | head -5
fi
exit 0
