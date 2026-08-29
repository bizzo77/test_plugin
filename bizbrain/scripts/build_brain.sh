#!/bin/bash
# Builds a new brain, once, the first time a session opens in an empty folder.
#
# It copies the files in ../brain/ and stamps today's date into them. It holds none
# of the brain's own wording - every file a new owner gets is a real file sitting in
# ../brain/, so it can be read and changed on its own.
#
# The lock: the desktop app opens several sessions in the same second, so this can
# start three or four times at once. Only one may build. "mkdir" either succeeds or
# fails, and only one caller can ever succeed.

set -u

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/../brain" 2>/dev/null && pwd)"
MARKER="$ROOT/.bizbrain"
LOG="$MARKER/setup-log.txt"   # inside the hidden folder. Our log is not their file.
NOW="$(date '+%A %d %B %Y at %I:%M:%S %p')"
TODAY="$(date '+%-d %B %Y')"

FOLDERS="Inbox Today People Projects Knowledge Decisions Done"

# 1. Already built? Nothing to do. Saying where things are up to is the other script's job.
[ -d "$MARKER" ] && exit 0

# 2. Not an empty folder? Stay out of it, silently. Somebody else's work.
CONTENTS="$(ls -A "$ROOT" 2>/dev/null | grep -v '^\.DS_Store$' || true)"
[ -n "$CONTENTS" ] && exit 0

# 3. Everything we are about to copy must be there FIRST. The marker is written once and
#    the build never runs again, so a half-built brain is permanent. Check before claiming it.
for f in "CLAUDE.md" "START HERE.md" "About me.md" "Catalogue.md" \
         "dot_claude/settings.json" "dot_claude/output-styles/bizbrain.md"; do
  if [ ! -r "${SRC:-/nonexistent}/$f" ]; then
    echo "BizBrain could not build this brain: $f is missing from the plugin. Nothing has been"
    echo "created. Tell the owner to reinstall BizBrain rather than carrying on."
    exit 0
  fi
done

# 4. The lock. Only one of the simultaneous sessions wins this.
if ! mkdir "$MARKER" 2>/dev/null; then
  echo "checked $NOW - another session was already setting up, nothing created" >> "$LOG"
  exit 0
fi

# 5. The winner builds.
for d in $FOLDERS; do mkdir -p "$ROOT/$d"; done

stamp () {  # copy one file, putting the date where the placeholders are
  sed -e "s/{{TODAY}}/$TODAY/g" -e "s/{{NOW}}/$NOW/g" "$SRC/$1" > "$ROOT/$1.part" &&
  [ -s "$ROOT/$1.part" ] && mv "$ROOT/$1.part" "$ROOT/$1"
}
stamp "CLAUDE.md"
stamp "START HERE.md"
stamp "About me.md"
stamp "Catalogue.md"

mkdir -p "$ROOT/.claude/output-styles"
cp "$SRC/dot_claude/settings.json" "$ROOT/.claude/settings.json"
cp "$SRC/dot_claude/output-styles/bizbrain.md" "$ROOT/.claude/output-styles/bizbrain.md"

# Every heading in the four files that shipped with this brain. The after-write check
# compares against this list, so the brain cannot rewrite one of its own files around
# headings of its own and quietly lose what was in it.
{
  for f in "About me.md" "CLAUDE.md" "START HERE.md"; do
    grep -H '^#\{1,3\} ' "$SRC/$f" 2>/dev/null | sed "s|^$SRC/||"
  done
  # Catalogue.md is a list, not headings, so watch the things it lists instead. Losing a line
  # from it is how a file stops being findable.
  grep -o '`[^`]*`' "$SRC/Catalogue.md" 2>/dev/null | sed 's|^|Catalogue.md:|'
} > "$MARKER/shipped-headings.txt"

echo "$NOW - CREATED the brain: $FOLDERS, rule book, About me, Catalogue, START HERE" >> "$LOG"
echo "$NOW" >> "$MARKER/setup-done.txt"
exit 0
