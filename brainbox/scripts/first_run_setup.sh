#!/bin/bash
# BrainBox first-run setup.
#
# What this does: the very first time a session opens in a brand-new empty folder,
# it builds that person's brain and invites them to talk. It never does it again.
#
# Why the lock is here: the Claude desktop app opens several sessions at the same
# moment, so this script can be started three or four times within one second.
# Only one may build. The lock is the "mkdir" on the marker folder below - on macOS
# and Linux that either succeeds or fails, and only one caller can ever succeed.

set -u

ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
MARKER="$ROOT/.brainbox"
LOG="$ROOT/BrainBox-setup-log.txt"
ABOUT="$ROOT/00_start_here/ABOUT_YOU.md"
NOW="$(date '+%A %d %B %Y at %I:%M:%S %p')"
TODAY="$(date '+%-d %B %Y')"

# The starting folders. PLACEHOLDER NAMES - not yet chosen by Jim.
FOLDERS="00_start_here 01_current_state 02_projects 03_decisions 04_reference 99_archive"

# ---------------------------------------------------------------------------
# 1. Already set up? Stop. This is the "never again" guard.
# ---------------------------------------------------------------------------
if [ -d "$MARKER" ]; then
  echo "checked $NOW - already set up, nothing created" >> "$LOG"
  if [ -f "$ABOUT" ] && ! grep -q "^## " "$ABOUT" 2>/dev/null; then
    echo "This person's brain still knows nothing about them - 00_start_here/ABOUT_YOU.md"
    echo "has no answers in it yet. Early in this session, invite them once, in plain"
    echo "English, to tell you about themselves, their business, their ideal clients,"
    echo "what they do, their biggest challenge and how you can help. Write what they say"
    echo "into that file in their own words. Ask once. Do not nag."
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# 2. Not an empty folder? Stay out of it, silently. Somebody else's work.
# ---------------------------------------------------------------------------
CONTENTS="$(ls -A "$ROOT" 2>/dev/null | grep -v '^\.DS_Store$' || true)"
if [ -n "$CONTENTS" ]; then
  exit 0
fi

# ---------------------------------------------------------------------------
# 3. The lock. Only one of the simultaneous sessions can win this.
# ---------------------------------------------------------------------------
if ! mkdir "$MARKER" 2>/dev/null; then
  echo "checked $NOW - another session was already setting up, nothing created" >> "$LOG"
  exit 0
fi

# ---------------------------------------------------------------------------
# 4. The winner builds the brain.
# ---------------------------------------------------------------------------
for d in $FOLDERS; do
  mkdir -p "$ROOT/$d"
done

# --- The rule book. Claude Code reads this file at the start of every session. ---
cat > "$ROOT/CLAUDE.md" <<'RULES'
# How this brain works

**Read this first, every session. This is the whole rule book, and it is short on purpose.**

This folder is a second brain. It belongs to the person you are talking to. Your job is to
remember things for them, so that nothing they tell you is ever lost.

Talk to them in plain English. No jargon. If a normal person would not know a word, use a
different one.

## The one rule everything else serves

**The files are the brain. The conversation is not.** Chats get thrown away. Anything that
matters has to be written into a file here before the session ends, or it never happened.

## Remember every session

Write things down as you go, not at the end.

- Anything they tell you about themselves or their business goes into
  `00_start_here/ABOUT_YOU.md`, in their own words.
- Anything they decide goes into `03_decisions/`, with the date and the reason.
- Anything they say they want, doubt, or are weighing up goes into a file the same session,
  before you move on. This is the easiest thing in the world to lose.
- Before the session ends, write where things are up to in `01_current_state/`, so the next
  session picks up the thread instead of starting again.

## Date every fact, or point at where the truth lives

Never write an undated claim in the present tense. "13 clients" is true today and a lie next
week, and it will still read as truth.

Write it as **"13 clients as of 27 August 2026"**, or write down where the real number lives
and go and look each time. A fact must be timeless, dated, or a pointer.

## Never say they haven't got something without properly looking

This is the most common way a brain like this fails - worse than making things up. Saying
"there's nothing about that" when there is, teaches them not to trust it, and then they stop
using it.

Before you say anything is missing, look under every name it might have, and in every folder.
If you are still unsure, show them what you found and say you are not certain.

## Never invent anything

Not a name, not a date, not a number, not a relationship. If something is unknown, write
**"not known yet"**. An empty section is the correct answer when nothing has happened - never
fill one in to make it look finished.

## Say how sure you are

When it matters, say which of these it is: they told you, several sources agree, one source
only, or you are guessing.

## One subject, one file

Before you create anything, look for a file that already covers it. If there is one, add to
it. Never leave two files arguing about the same thing.

When a file is genuinely replaced, move the old one to `99_archive/` with a note at the top
saying what replaced it. Never delete it.

## Every file opens by saying what it is

The first two or three sentences of every file say what it is, why it was kept, and the date.
A later session may open that one file with nothing else around it, and needs to know in ten
seconds whether it matters.

## Keep the contents list up to date

`00_start_here/CONTENTS.md` lists every file with one line saying what is in it. Read it at
the start of a session - reading one list is faster than hunting through everything. Add a
line to it every time you make a new file.

## Only ever add

Never delete, merge or tidy away any of their work while they are not watching. Adding is
always safe. Removing is theirs to ask for.
RULES

# --- Where their own answers go. ---
cat > "$ABOUT" <<ABOUTFILE
# About you

*This file holds what your brain knows about you, in your own words. Started $TODAY.*

It is empty because your brain has not met you yet. It fills up as you talk.
ABOUTFILE

# --- The contents list. ---
cat > "$ROOT/00_start_here/CONTENTS.md" <<CONTENTSFILE
# What is in this brain

*A list of every file, with one line saying what is in it. Started $TODAY.*
*Read this first. Add a line to it every time a new file is made.*

- \`CLAUDE.md\` - the rule book. How this brain works.
- \`README.txt\` - what this folder is, for a human.
- \`00_start_here/ABOUT_YOU.md\` - who you are, in your own words.
- \`00_start_here/CONTENTS.md\` - this list.
- \`01_current_state/\` - where things are up to right now.
- \`02_projects/\` - one folder per thing you are working on.
- \`03_decisions/\` - what you decided, when, and why.
- \`04_reference/\` - things worth keeping that are not yours.
- \`99_archive/\` - replaced files. Never deleted, just moved here.
CONTENTSFILE

cat > "$ROOT/README.txt" <<README
BrainBox
========

This is your second brain. It was set up on $NOW.

It is a plain folder of plain files. Nothing here is locked, and you can open
any of it yourself.

Start with 00_start_here/CONTENTS.md - it lists everything in here.

The hidden folder .brainbox is how BrainBox knows this setup has already been
done. Leave it alone.
README

echo "$NOW - CREATED the brain: folders, rule book, About You, contents list" >> "$LOG"
echo "$NOW" >> "$MARKER/setup-done.txt"

# ---------------------------------------------------------------------------
# 5. The invitation. Claude reads this and opens the conversation with it.
# ---------------------------------------------------------------------------
cat <<'INVITE'
BrainBox first run. This person's brain has just been created and knows nothing about
them. Before anything else, and before mentioning any file or folder, say this to them
in your own words, in plain English:

  This brain knows nothing about you yet. It's an empty folder.

  It learns as you use it - every session adds to what it knows. But it has to start
  somewhere, and the more it knows about you now, the more use it is straight away.
  There are no wrong answers and you can't break it.

Then invite them to talk, two questions at a time, not all six at once:

  - Tell me about your business.
  - Tell me about you.
  - Who are your ideal clients?
  - What do you actually do for them?
  - What's your biggest challenge right now?
  - How can I help you?

Follow whatever they say and ask more. More is better than less.

Write what they tell you into 00_start_here/ABOUT_YOU.md as you go, in their own words,
under plain headings. Add to that file. Never overwrite what is in it.

Do not talk about folders, files, versions or setup. Just start talking to them.
INVITE
exit 0
