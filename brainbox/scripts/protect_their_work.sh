#!/bin/bash
# Blocks deleting the owner's work. This is the "only ever add" promise made real.
#
# Rules a model is merely asked to remember get lost in a long session. A check does not.
# Exit code 2 refuses the command and tells the assistant why.
#
# There is never a reason to remove a file from a second brain. Replaced files move to Done/.

set -u

INPUT="$(cat)"

# "rm" as a command of its own - not the "rm" inside words like confirm or firmware.
if printf '%s' "$INPUT" | grep -Eq '(^|[^A-Za-z])rm[[:space:]]+(-|["'"'"']?[A-Za-z0-9./~$])'; then
  echo "Blocked. Nothing in this brain is ever deleted." >&2
  echo "If the file has been replaced, move it to Done/ with a note at the top saying what" >&2
  echo "replaced it. If the owner asked for it gone, tell them it has moved to Done/ instead." >&2
  exit 2
fi
exit 0
