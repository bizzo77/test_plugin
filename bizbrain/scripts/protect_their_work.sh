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
printf '%s' "$CMD" | grep -Eq ">[[:space:]]*\"?[^|>]*($SHIPPED|bizbrain\.md|settings\.json)" &&
  refuse "that writes over one of the files this brain runs on."

# 4. The hidden folder the checks read.
printf '%s' "$CMD" | grep -q '\.bizbrain' &&
  printf '%s' "$CMD" | grep -Eq '(^|[^A-Za-z])(r[m]|mv|cp|truncate|sed[[:space:]]+-i)[[:space:]]|>' &&
  refuse "that changes the hidden .bizbrain folder, which is how this brain checks itself."

exit 0
