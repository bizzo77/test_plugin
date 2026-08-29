#!/bin/bash
# Runs at the start of every session, once the brain exists.
#
# Two jobs. If the brain has never met this person, it makes sure the opening happens.
# Otherwise it reads the brain and hands over where things are up to, so the brain
# speaks first and they never have to ask.
#
# It reads. It never writes to any of the owner's files.

set -u

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
ABOUT="$ROOT/About me.md"

[ -d "$ROOT/.brainbox" ] || exit 0   # nothing built yet - not this script's job

# --- Never met them yet: the opening is the only thing that happens. ---
ANSWERED=0
if [ -f "$ABOUT" ]; then
  TOTAL="$(grep -c '^## ' "$ABOUT" | head -1 | tr -d ' \n')"
  BLANK="$(grep -c 'Waiting to be filled in' "$ABOUT" | head -1 | tr -d ' \n')"
  ANSWERED=$(( ${TOTAL:-0} - ${BLANK:-0} ))
fi

# The marker says they have not been met. If anything has actually been answered, the marker
# is stale - say so rather than putting them through the opening a second time.
if [ -f "$ABOUT" ] && grep -q "NOTHING SAVED YET" "$ABOUT" 2>/dev/null && [ "$ANSWERED" -gt 0 ]; then
  [ "$ANSWERED" -eq 1 ] && W="thing is" || W="things are"
  echo "This brain has already met them - $ANSWERED $W answered in About me.md - but"
  echo "the line NOTHING SAVED YET is still sitting in that file. Take that line out now. Do not"
  echo "give them the opening again."
  exit 0
fi

if [ -f "$ABOUT" ] && grep -q "NOTHING SAVED YET" "$ABOUT" 2>/dev/null; then
  cat <<'FIRST'
This person's brain has not met them yet.

Your first message in this session is the opening at the top of CLAUDE.md, under the heading
THE FIRST THING YOU DO. Say it word for word, then stop and wait. Do not use their name. Do
not greet them. Do not offer to skip it.
FIRST
  exit 0
fi

# --- Met them. Say where things are up to. ---
echo "Where this brain is up to. Open the session with this, in your own words, before they ask."
echo

LAST_DAY="$(ls -1 "$ROOT/Today" 2>/dev/null | sort | tail -1)"
if [ -n "$LAST_DAY" ]; then
  echo "Last written up: Today/$LAST_DAY - read it before you say anything."
else
  echo "Nothing in Today yet."
fi

LIVE="$(ls -1 "$ROOT/Projects" 2>/dev/null | head -12)"
if [ -n "$LIVE" ]; then
  echo
  echo "Live work in Projects:"
  printf '%s\n' "$LIVE" | sed 's/^/  - /'
fi

INBOX="$(ls -A "$ROOT/Inbox" 2>/dev/null | grep -v '^\.DS_Store$' | wc -l | tr -d ' ')"
if [ "${INBOX:-0}" -gt 0 ]; then
  echo
  [ "$INBOX" -eq 1 ] && WORD="thing is" || WORD="things are"
  echo "$INBOX $WORD waiting in Inbox. Clearing it is your job, not theirs."
fi

# grep -c prints 0 and also exits non-zero when nothing matches, so a "|| echo 0" here
# would print 0 twice and break the comparison below. tr -d picks off the stray newline.
BLANKS="$(grep -c 'Waiting to be filled in' "$ABOUT" 2>/dev/null | head -1 | tr -d ' \n')"
[ -n "$BLANKS" ] || BLANKS=0
if [ "${BLANKS:-0}" -gt 0 ]; then
  echo
  [ "$BLANKS" -eq 1 ] && WORD="blank is" || WORD="blanks are"
  echo "$BLANKS $WORD still unanswered in About me.md. That is your unfinished work:"
  grep -B2 'Waiting to be filled in' "$ABOUT" 2>/dev/null | grep '^## ' | sed 's/^## /  - /'
  echo "Ask about at most two of them, in ordinary conversation. Never as a list of questions."
fi
exit 0
