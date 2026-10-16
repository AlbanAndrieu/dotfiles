#!/usr/bin/env bash
# PreToolUse hook (Bash) — block the agent from bypassing a git hook or a quality gate.
#
# The lefthook checks (betterleaks, trivy, shellcheck, yamllint, coverage, harness budget…) only
# run locally: a bypass leaves no trace in CI. A broken check is reported to the user, who
# decides — an agent never skips one on its own (e.g. committing with LEFTHOOK_EXCLUDE because
# yamllint crashed).
#
# Blocked: --no-verify, `git commit -n`, LEFTHOOK=0 / LEFTHOOK_EXCLUDE / LEFTHOOK_CONFIG, HUSKY=0,
# SKIP= (pre-commit), every SKIP_* variable a lefthook.yml of the repo honors, core.hooksPath,
# `lefthook uninstall`, and changes to .git/hooks.
# shellcheck disable=SC2016 # backticks in the deny messages are Markdown, not command substitution
set -uo pipefail

command=$(jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -n "${command}" ]] || exit 0

deny() {
  cat >&2 <<EOF
🚫 BLOCKED: ${1}

Quality gates and git hooks are never bypassed by an agent. Fix the finding, or — when the
check itself is broken (crashing tool, wrong version) — stop and report it to the user with
the error. Only the user may decide to skip it, by running the command themselves.
If the match is only text (a commit message, a heredoc), write it to a file with the Write tool
and pass the file instead (\`git commit -F <file>\`, \`gh pr create --body-file <file>\`).
EOF
  exit 2
}

if grep -Eq -- '(^|[[:space:]])--no-verify([[:space:]=]|$)' <<<"${command}"; then
  deny '`--no-verify` skips the git hooks.'
fi

# Quoted text (a commit message) is dropped first: a flag there is not a flag.
unquoted=$(sed -E "s/\"[^\"]*\"//g; s/'[^']*'//g" <<<"${command}")
if grep -Eq -- '(^|[^A-Za-z0-9_-])git[[:space:]]([^;&|]*[[:space:]])?commit([[:space:]][^;&|]*)?[[:space:]]-[A-Za-z]*n[A-Za-z]*([[:space:]]|$)' <<<"${unquoted}"; then
  deny '`git commit -n` is `--no-verify`: it skips the git hooks.'
fi

# Every SKIP_* variable a lefthook config of the repo honors, so a new gate is covered without
# touching this hook.
repo_root=$(git -C "${CLAUDE_PROJECT_DIR:-.}" rev-parse --show-toplevel 2>/dev/null || pwd)
gate_variables=$(git -C "${repo_root}" ls-files -z -- '*lefthook*.yml' '*lefthook*.yaml' 2>/dev/null \
  | (cd "${repo_root}" && xargs -0 grep -ohE 'SKIP_[A-Z0-9_]+' 2>/dev/null) | sort -u | paste -sd'|' -)
gate_variables="LEFTHOOK|LEFTHOOK_EXCLUDE|LEFTHOOK_CONFIG|LEFTHOOK_BIN|HUSKY|SKIP${gate_variables:+|${gate_variables}}"
if variable=$(grep -oE "(^|[^A-Za-z0-9_])(${gate_variables})=" <<<"${command}" | head -n 1) && [[ -n "${variable}" ]]; then
  deny "\`${variable//[^A-Z0-9_=]/}\` disables a git hook or a quality gate."
fi

if grep -Eq -- 'core\.hooksPath' <<<"${command}"; then
  deny '`core.hooksPath` redirects git away from the repo hooks.'
fi

if grep -Eq -- '(^|[^A-Za-z0-9_-])lefthook[[:space:]]+uninstall' <<<"${command}"; then
  deny '`lefthook uninstall` removes the git hooks.'
fi

if grep -Eq -- '((rm|mv|cp|ln|chmod|truncate|tee)[[:space:]][^;&|]*|>[[:space:]]*[^[:space:]]*)\.git/hooks' <<<"${command}"; then
  deny 'changing `.git/hooks` disables the git hooks.'
fi

exit 0
