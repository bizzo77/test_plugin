#!/bin/bash
# Refuses shell commands that would take something away from this brain.
#
# Rules a model is merely asked to remember get lost in a long session. A check does not.
# Exit code 2 refuses the command and tells the assistant why.
#
# Four things are refused:
#   1. deleting a file - there is never a reason to remove one from a second brain
#   2. moving or renaming one of the four files the brain came with
#   3. emptying a file by redirecting over it, which would get past the write check
#   4. touching the hidden .bizbrain folder, which is what the checks read

set -u

INPUT="$(cat)"
CMD="$(printf '%s' "$INPUT" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\(.*\)".*/\1/p' | head -1)"
[ -n "$CMD" ] || CMD="$INPUT"

SHIPPED='About me\.md|CLAUDE\.md|Catalogue\.md|START HERE\.md'

refuse () {
  echo "Blocked. $1" >&2
  echo "Nothing in this brain is ever taken away. If a file has been replaced, move it to Done/" >&2
  echo "with a note at the top saying what replaced it. If the owner asked for something gone," >&2
  echo "tell them it has moved to Done/ instead." >&2
  exit 2
}

# 1. Deleting.
printf '%s' "$CMD" | grep -Eq '(^|[^A-Za-z])r[m][[:space:]]+(-|["'"'"']?[A-Za-z0-9./~$])' &&
  refuse "that command deletes files."

# 2. Moving or renaming a file the brain came with.
printf '%s' "$CMD" | grep -Eq '(^|[^A-Za-z])(mv|cp)[[:space:]]' &&
  printf '%s' "$CMD" | grep -Eq "$SHIPPED" &&
  refuse "that moves or renames one of the four files this brain came with."

# 3. Emptying a file by writing over it from the shell.
#    Judge only what the redirect points AT. An earlier version searched the whole command,
#    so writing a note that merely mentioned one of these file names was refused - and a note
#    about a file is not a change to that file.
#    A quoted target is read whole, so a file name with a space in it is still seen.
#    Backslashes are stripped first: they survive the trip through the message and would
#    otherwise hide a quoted name like "About me.md".
PLAIN="$(printf '%s' "$CMD" | tr -d '\\')"
REDIRECT="$(printf '%s' "$PLAIN" | sed -n 's/.*[^>2]>[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
[ -n "$REDIRECT" ] ||
  REDIRECT="$(printf '%s' "$PLAIN" | sed -n 's/.*[^>2]>[[:space:]]*\([^"[:space:];|&]*\).*/\1/p' | head -1)"
if [ -n "$REDIRECT" ]; then
  printf '%s' "$REDIRECT" | grep -Eq "($SHIPPED|bizbrain\.md|settings\.json)$" &&
    refuse "that writes over one of the files this brain runs on."
fi

# 4. The hidden folder the checks read. Only changes to it - reading it is fine, and an
#    earlier version refused any command that so much as mentioned the folder and happened
#    to contain a > anywhere, which caught ordinary reads ending in 2>/dev/null.
printf '%s' "$CMD" | grep -Eq '(^|[^A-Za-z])(r[m]|mv|cp|truncate|sed[[:space:]]+-i)[[:space:]][^|;&]*\.bizbrain' &&
  refuse "that changes the hidden .bizbrain folder, which is how this brain checks itself."
printf '%s' "$CMD" | grep -Eq '>[[:space:]]*"?[^|>;& ]*\.bizbrain' &&
  refuse "that writes into the hidden .bizbrain folder, which is how this brain checks itself."

exit 0
