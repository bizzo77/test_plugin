#!/usr/bin/env python3
# Feeds commands to the guard exactly as Claude Code does (proper JSON on stdin)
# and reports which are refused. Run against any copy of the guard: pass its path.
import json, subprocess, sys

GUARD = sys.argv[1]

CASES = [
    # (expect, description, command)
    ("BLOCK", "write over the rule book",               'echo hi > CLAUDE.md'),
    ("BLOCK", "empty the rule book",                    ': > CLAUDE.md'),
    ("BLOCK", "write over About me (quoted)",           'cat > "About me.md"'),
    ("BLOCK", "write over START HERE (quoted)",         'echo x > "START HERE.md"'),
    ("BLOCK", "write over the catalogue",               'echo x > Catalogue.md'),
    ("BLOCK", "write over the voice settings",          'echo x > .claude/settings.json'),
    ("BLOCK", "write over the voice file",              'echo x > .claude/output-styles/bizbrain.md'),
    ("BLOCK", "rule book with a folder in front",       'echo x > brain/CLAUDE.md'),
    ("BLOCK", "delete a file (quoted name)",            'rm "About me.md"'),
    ("BLOCK", "delete a file (plain name)",             'rm notes.md'),
    ("BLOCK", "delete a folder",                        'rm -rf Today/'),
    ("BLOCK", "rename an original",                     'mv CLAUDE.md old.md'),
    ("BLOCK", "write into the hidden folder",           'echo x > .bizbrain/setup-done.txt'),
    ("BLOCK", "remove the hidden folder",               'rm -rf .bizbrain'),
    ("ALLOW", "write another file whose text names the rule book",
              'cat > notes.md <<EOF\nAdd to CLAUDE.md. Never rewrite it.\nEOF'),
    ("ALLOW", "write another file quoting all four names",
              'cat > plan.md <<EOF\n"About me.md", "CLAUDE.md", "Catalogue.md", "START HERE.md"\nEOF'),
    ("ALLOW", "a blockquote mentioning the catalogue",
              'cat > page.md <<EOF\n> Add it to Catalogue.md as you go\nEOF'),
    ("ALLOW", "append to the rule book",                'echo x >> CLAUDE.md'),
    ("ALLOW", "read the rule book",                     'cat CLAUDE.md'),
    ("ALLOW", "search the catalogue",                   'grep -n Inbox Catalogue.md'),
    ("ALLOW", "list the folder",                        'ls -la'),
    ("ALLOW", "read the hidden folder",                 'cat .bizbrain/setup-done.txt 2>/dev/null'),
    ("ALLOW", "write an ordinary new file",             'echo hello > Knowledge/trading.md'),
    ("ALLOW", "a word containing rm",                   'echo confirm the firmware'),
    ("ALLOW", "count lines in the rule book",           'wc -l CLAUDE.md'),
]

passed = failed = 0
for expect, desc, cmd in CASES:
    payload = json.dumps({"tool_name": "Bash", "tool_input": {"command": cmd}})
    r = subprocess.run(["bash", GUARD], input=payload, text=True, capture_output=True)
    got = "BLOCK" if r.returncode == 2 else "ALLOW"
    if got == expect:
        passed += 1
        print(f"ok    {got:<6} {desc}")
    else:
        failed += 1
        print(f"FAIL  wanted {expect} got {got} : {desc}")

print(f"\npassed {passed}, failed {failed}")
sys.exit(1 if failed else 0)
