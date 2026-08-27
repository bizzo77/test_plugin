#!/bin/bash
# BrainBox first-run setup.
#
# What this does: the very first time a session opens in a brand-new empty folder,
# it builds that person's starting folders. It never does it again.
#
# Why it is written this way: the Claude desktop app opens several sessions at the
# same moment, so this script can be started three or four times within one second.
# Only one of them is allowed to build anything. The lock is the "mkdir" on the
# marker folder below - on macOS and Linux that either succeeds or fails, and only
# one caller can ever succeed. Everyone else stops.

set -u

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
MARKER="$ROOT/.brainbox"
LOG="$ROOT/BrainBox-setup-log.txt"
NOW="$(date '+%A %d %B %Y at %I:%M:%S %p')"

# The starting folders. PLACEHOLDER NAMES - not yet decided by Jim.
# Change this one line when the real shape is settled.
FOLDERS="00_start_here 01_current_state 02_projects 03_decisions 04_reference 99_archive"

# 1. Already set up? Say so and stop. This is the "never again" guard.
if [ -d "$MARKER" ]; then
  echo "checked $NOW - already set up, nothing created" >> "$LOG"
  echo "BrainBox: this folder is already set up. Nothing was created."
  exit 0
fi

# 2. Not an empty folder? This is somebody's existing work. Stay out of it, silently.
CONTENTS="$(ls -A "$ROOT" 2>/dev/null | grep -v '^\.DS_Store$' || true)"
if [ -n "$CONTENTS" ]; then
  exit 0
fi

# 3. The lock. Only one of the simultaneous sessions can win this.
if ! mkdir "$MARKER" 2>/dev/null; then
  echo "checked $NOW - another session was already setting up, nothing created" >> "$LOG"
  echo "BrainBox: another session is setting this folder up. Nothing was created."
  exit 0
fi

# 4. The winner builds. mkdir -p never overwrites anything that already exists.
for d in $FOLDERS; do
  mkdir -p "$ROOT/$d"
done

cat > "$ROOT/README.txt" <<README
BrainBox
========

This folder was set up by BrainBox on $NOW.

The folders above are your starting shape. Put things in them.

The hidden folder .brainbox is how BrainBox knows this setup has already
been done. Leave it alone. If you delete it, the setup will run again.

BrainBox-setup-log.txt records every time BrainBox checked this folder.
README

echo "$NOW - CREATED the starting folders and README.txt" >> "$LOG"
echo "version $(cat "${CLAUDE_PLUGIN_ROOT:-.}/.claude-plugin/plugin.json" 2>/dev/null | grep '"version"' | head -1 | cut -d'"' -f4)" >> "$MARKER/setup-done.txt"
echo "$NOW" >> "$MARKER/setup-done.txt"

echo "BrainBox: first-run setup is done. Your starting folders have been created. See README.txt."
exit 0
