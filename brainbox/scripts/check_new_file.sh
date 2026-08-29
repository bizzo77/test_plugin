#!/bin/bash
# Runs after anything is written. Checks the two rules that are checkable:
# every file opens by saying what it is, and every file is in the catalogue.
#
# It only reports. It never changes a file. Silent when there is nothing to say.

set -u

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
CAT="$ROOT/Catalogue.md"
[ -d "$ROOT/.brainbox" ] || exit 0

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
      -type f -name '*.md' 2>/dev/null | head -60)
EOF

# --- Has About me.md lost one of the headings it shipped with? ---
# A heading is a question the brain still owes them. Delete one and the question is gone
# for good, with nothing to say so. This is checked, not left to memory.
HEADINGS="$ROOT/.brainbox/about-headings.txt"
ABOUT="$ROOT/About me.md"
if [ -f "$HEADINGS" ] && [ -f "$ABOUT" ]; then
  MISSING=""
  while IFS= read -r h; do
    [ -z "$h" ] && continue
    grep -qF "$h" "$ABOUT" || MISSING="$MISSING  - ${h#\#\# }
"
  done < "$HEADINGS"
  if [ -n "$MISSING" ]; then
    echo "STOP. These headings have gone from About me.md:"
    printf '%s' "$MISSING"
    echo "Put them back, spelled exactly as they were, with their waiting line underneath if"
    echo "they were never answered. Those headings are your job list. Write their answers"
    echo "underneath the heading that is already there. Never rebuild the file around headings"
    echo "of your own."
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
