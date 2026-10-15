#!/usr/bin/env python3
"""PreToolUse hook (Bash): ask before any recursive rm outside the temp directory.

Replaces the "Bash(rm -rf *)" / "Bash(rm -r *)" ask rules, which cannot carve
out an exception: a recursive rm whose every target sits under /private/tmp/
(or /tmp/) gets no decision from this hook, so the normal permission flow
decides; any other recursive rm is turned into an "ask".

A target counts as safe only when it is a literal absolute path (no variable,
command substitution, glob, ~ or ..), does not end with "/", is not the temp
root itself, and still lies under the temp root once symlinks are resolved.
Anything the hook cannot parse is treated as unsafe.
"""

import json
import os
import shlex
import sys

TEMP_ROOTS = {os.path.realpath(p) for p in ("/tmp", "/private/tmp") if os.path.isdir(p)}
SEPARATORS = {";", "&&", "||", "|", "&", "(", ")", "|&", ";;"}
UNSAFE_CHARS = set("$`*?[]{}~")


def ask(reason):
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "ask",
                    "permissionDecisionReason": reason,
                },
            },
        ),
    )
    sys.exit(0)


def is_recursive(flags):
    for flag in flags:
        if flag == "--recursive":
            return True
        if flag.startswith("-") and not flag.startswith("--") and ("r" in flag or "R" in flag):
            return True
    return False


def is_safe_target(path):
    if not path.startswith("/") or path.endswith("/") or UNSAFE_CHARS & set(path):
        return False
    if ".." in path.split("/"):
        return False
    real = os.path.realpath(path)
    return any(real.startswith(root + "/") for root in TEMP_ROOTS)


def segments(command):
    for line in command.splitlines():
        lexer = shlex.shlex(line, posix=True, punctuation_chars=True)
        lexer.whitespace_split = True
        current = []
        for token in lexer:
            if token in SEPARATORS:
                if current:
                    yield current
                current = []
            else:
                current.append(token)
        if current:
            yield current


def main():
    command = json.load(sys.stdin).get("tool_input", {}).get("command", "")
    if "rm" not in command:
        return
    try:
        parts = list(segments(command))
    except ValueError:
        ask("Recursive rm guard: could not parse the command, confirm it")
    for tokens in parts:
        positions = [i for i, t in enumerate(tokens) if t == "rm" or t.endswith("/rm")]
        if not positions:
            continue
        start = positions[0]
        args = tokens[start + 1 :]
        if "--" in args:
            cut = args.index("--")
            flags, targets = args[:cut], args[cut + 1 :]
        else:
            flags = [a for a in args if a.startswith("-")]
            targets = [a for a in args if not a.startswith("-")]
        if not is_recursive(flags):
            continue
        # rm reached through another command (xargs, find -exec, sudo...):
        # its targets are not on the command line, so they cannot be checked.
        if start != 0:
            ask("Recursive rm through another command: targets cannot be checked")
        unsafe = [t for t in targets if not is_safe_target(t)]
        if not targets or unsafe:
            ask("Recursive rm outside /private/tmp/: " + (" ".join(unsafe) or "no target"))


if __name__ == "__main__":
    main()
