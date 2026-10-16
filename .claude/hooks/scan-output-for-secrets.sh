#!/usr/bin/env bash
# PostToolUse hook (Bash) — scan what a command printed with betterleaks.
#
# Second line of defense behind guard-secret-exposure.sh, which only sees variable names: this
# one sees values. It uses the .betterleaks.toml of the current repo when there is one (same
# rules as its pre-commit hook), the betterleaks default rules otherwise. The output has already
# reached the agent, so the hook cannot hide it; it makes sure the leak is reported to the user
# (for rotation) and never repeated.
#
# Silent when betterleaks is not installed (`mise use -g betterleaks` provides it).
set -uo pipefail

input=$(cat)
output=$(jq -r '.tool_response | if type == "object" then [.stdout, .stderr] | map(select(. != null)) | join("\n") else tostring end' <<<"${input}" 2>/dev/null)
[[ -n "${output}" ]] || exit 0

repo_root=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --show-toplevel 2>/dev/null || pwd)
betterleaks=$(command -v betterleaks || (cd "${repo_root}" && mise which betterleaks 2>/dev/null)) || exit 0
[[ -x "${betterleaks}" ]] || exit 0

config=()
[[ -f "${repo_root}/.betterleaks.toml" ]] && config=(--config "${repo_root}/.betterleaks.toml")

rules=$("${betterleaks}" stdin ${config[@]+"${config[@]}"} --redact --no-banner --log-level error \
  --report-format json --report-path - <<<"${output}" 2>/dev/null \
  | jq -r '[.[].RuleID] | unique | join(", ")' 2>/dev/null)
[[ -n "${rules}" ]] || exit 0

reason="betterleaks found a secret in the output of this command (rules: ${rules}). Do not repeat, quote, summarize or store it — not in chat, a file, a commit, a PR or a memory. Tell the user now which command printed it and that the credential must be rotated, then carry on without using the printed value."
jq -n --arg reason "${reason}" '{decision: "block", reason: $reason}'
