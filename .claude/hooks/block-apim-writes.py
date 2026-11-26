#!/usr/bin/env python3
"""PreToolUse hook (Bash): block every write to Azure API Management.

Claude Code must not change an APIM instance or its policies, loggers, named
values, subscriptions, diagnostics or role assignments, whatever the
permission mode and even when the user asks: it hands the user the exact
command, diff, impact and rollback to run themselves.

A command is blocked (exit 2) when it, or a script or template file it names,
references APIM (Microsoft.ApiManagement, *.azure-api.net, az apim,
azurerm_api_management) and also carries a write: an HTTP PUT, PATCH, DELETE
or POST (curl, az rest, Invoke-RestMethod, Python), curl sending data, or a
mutating az verb (create, update, delete, import, restore...). POST is blocked
too, so list* actions that return APIM secrets are blocked on purpose.
Reads (GET, az apim show/list, Activity Log queries) pass.
"""

import json
import os
import re
import shlex
import sys

APIM = re.compile(
    r"Microsoft\.ApiManagement|\.azure-api\.net|\baz\s+apim\b|azurerm_api_management",
    re.IGNORECASE,
)
METHOD = r"['\"]?(?:PUT|PATCH|DELETE|POST)\b"
HTTP_WRITE = [
    re.compile(r"(?:^|\s)-X\s*" + METHOD, re.IGNORECASE),
    re.compile(r"--request[=\s]+" + METHOD, re.IGNORECASE),
    re.compile(r"-{1,2}method['\"]?[=\s,]+" + METHOD, re.IGNORECASE),
    re.compile(r"(?:^|\s)-m\s+" + METHOD, re.IGNORECASE),
    re.compile(r"\bcurl\b[^\n|;&]*\s(?:-d|--data(?:-raw|-binary|-urlencode)?|--json|-F|--form|-T|--upload-file)(?:\s|=)"),
    re.compile(r"\bmethod\s*=\s*" + METHOD, re.IGNORECASE),
    re.compile(r"\.(?:put|patch|delete|post)\s*\("),
    re.compile(r"\bRequest\s*\([^)]*\bdata\s*="),
]
AZ_WRITE_VERBS = {
    "add",
    "apply-network-updates",
    "assign",
    "backup",
    "create",
    "delete",
    "deploy",
    "disable",
    "enable",
    "import",
    "invoke-action",
    "lock",
    "move",
    "patch",
    "purge",
    "regenerate",
    "remove",
    "renew",
    "reset",
    "restart",
    "restore",
    "set",
    "start",
    "stop",
    "sync",
    "tag",
    "update",
    "upload",
}
SCRIPT_EXT = (
    ".py",
    ".sh",
    ".bash",
    ".zsh",
    ".js",
    ".mjs",
    ".ts",
    ".ps1",
    ".rb",
    ".json",
    ".bicep",
    ".tf",
    ".xml",
)
RUNNERS = re.compile(r"^(?:python[\d.]*|node|bash|sh|zsh|pwsh|powershell|ruby|deno|tsx|ts-node|source|\.)$")
# Words that may come before the interpreter: `sudo python3 x.py`, `uv run python x.py`.
PREFIXES = {"sudo", "exec", "time", "env", "nohup", "command", "uv", "run", "mise", "poetry"}
SEGMENT_SPLIT = re.compile(r"\n|;|&&|\|\||\|")
MAX_FILE = 2 * 1024 * 1024


def block(reason):
    sys.stderr.write(
        "APIM write guard: " + reason + ". Claude Code must not change Azure API Management "
        "(instance, policies, loggers, named values, subscriptions, diagnostics). Give the user "
        "the exact command or diff, its impact and its rollback, and let them run it.\n",
    )
    sys.exit(2)


def tokens(text):
    try:
        return shlex.split(text, posix=True)
    except ValueError:
        return text.split()


def referenced_files(command, cwd):
    """Contents of the scripts the command runs and of the @files or templates it sends.

    Files only read or edited (jq . settings.json) are left out, so config files that
    merely mention APIM do not block the command.
    """
    found = []
    for segment in SEGMENT_SPLIT.split(command):
        words = tokens(segment)
        runner = False
        for i, word in enumerate(words):
            in_command_position = all("=" in w or w in PREFIXES for w in words[:i])
            if in_command_position and RUNNERS.match(os.path.basename(word)):
                runner = True
                continue
            sent = word.startswith("@") or (i > 0 and words[i - 1] == "--template-file")
            path = word.lstrip("@")
            if not (runner or sent or i == 0) or not path.lower().endswith(SCRIPT_EXT):
                continue
            path = os.path.join(cwd, os.path.expanduser(path))
            try:
                if os.path.isfile(path) and os.path.getsize(path) <= MAX_FILE:
                    with open(path, encoding="utf-8", errors="replace") as handle:
                        found.append(handle.read())
            except OSError:
                continue
    return found


def az_writes(text):
    for segment in SEGMENT_SPLIT.split(text):
        words = tokens(segment)
        for i, word in enumerate(words):
            if word == "az" or word.endswith("/az"):
                verbs = []
                for sub in words[i + 1 :]:
                    if sub.startswith("-"):
                        break
                    verbs.append(sub.lower())
                if AZ_WRITE_VERBS.intersection(verbs):
                    return " ".join(["az"] + verbs)
    return None


def main(raw):
    payload = json.loads(raw)
    command = payload.get("tool_input", {}).get("command", "") or ""
    cwd = payload.get("cwd") or os.getcwd()
    # Each file is checked with the command but apart from the other files, so a marker
    # in one file and a write in an unrelated one do not add up.
    for text in [command] + [command + "\n" + f for f in referenced_files(command, cwd)]:
        check(text)


def check(text):
    if not APIM.search(text):
        return
    for pattern in HTTP_WRITE:
        match = pattern.search(text)
        if match:
            block("write call to APIM (" + match.group(0).strip()[:40] + ")")
    verb = az_writes(text)
    if verb:
        block("mutating az command on APIM (" + verb + ")")


if __name__ == "__main__":
    RAW = sys.stdin.read()
    try:
        main(RAW)
    except SystemExit:
        raise
    except Exception as error:  # fail closed only when the call mentions APIM
        if APIM.search(RAW):
            block("could not check the command (" + type(error).__name__ + ")")
