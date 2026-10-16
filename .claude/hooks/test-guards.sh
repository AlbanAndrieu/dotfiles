#!/usr/bin/env bash
# Regression tests of the agent guardrail hooks: bash ~/.claude/hooks/test-guards.sh
# Each case feeds a Bash tool call to a hook and checks it is blocked (2) or allowed (0).
# The SKIP_* gate variables come from a fixture repo whose lefthook.yml declares them, as a real
# project would.
# shellcheck disable=SC2016 # the cases are literal commands: their $VARS must not expand here
set -uo pipefail

hooks_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
fixture=$(mktemp -d)
trap 'rm -r -f -- "${fixture}"' EXIT
git -C "${fixture}" init -q
printf 'pre-commit:\n  skip:\n    - env: [SKIP_BETTERLEAKS, SKIP_TRIVY, SKIP_HARNESS_BUDGET, SKIP_COVERAGE_CHECK]\n' >"${fixture}/lefthook.yml"
git -C "${fixture}" add lefthook.yml
CLAUDE_PROJECT_DIR=${fixture}
export CLAUDE_PROJECT_DIR
failures=0

check() {
  local hook=$1 expected=$2 command=$3 actual
  jq -n --arg command "${command}" '{tool_input: {command: $command}}' | "${hooks_dir}/${hook}" >/dev/null 2>&1
  actual=$?
  if [[ "${actual}" != "${expected}" ]]; then
    echo "FAIL ${hook}: expected ${expected}, got ${actual} — ${command}"
    failures=$((failures + 1))
  fi
}

gates=guard-quality-gates.sh
check "${gates}" 2 'git commit --no-verify -m "x"'
check "${gates}" 2 'git commit -nm "x"'
check "${gates}" 2 'git -C api commit -an -m x'
check "${gates}" 2 'git push --no-verify'
check "${gates}" 2 'LEFTHOOK_EXCLUDE=yamllint git commit -m x'
check "${gates}" 2 'LEFTHOOK=0 git commit -m x'
check "${gates}" 2 'export SKIP_TRIVY=1'
check "${gates}" 2 'SKIP_BETTERLEAKS=1 git commit'
check "${gates}" 2 'SKIP_HARNESS_BUDGET=1 git commit -m x'
check "${gates}" 2 'SKIP_COVERAGE_CHECK=1 git commit -m x'
check "${gates}" 2 'SKIP=yamllint git commit -m x'
check "${gates}" 2 'HUSKY=0 git commit'
check "${gates}" 2 'git -c core.hooksPath=/dev/null commit -m x'
check "${gates}" 2 'git config core.hooksPath /tmp'
check "${gates}" 2 'lefthook uninstall'
check "${gates}" 2 'rm -f .git/hooks/pre-commit'
check "${gates}" 2 'echo "" > .git/hooks/pre-commit'
check "${gates}" 0 'git commit -m "feat: add login"'
check "${gates}" 0 'git commit --amend --no-edit'
check "${gates}" 0 'git commit -s -m x'
check "${gates}" 0 'git commit -F message.txt'
check "${gates}" 0 'git status && git commit -m "fix: use -n flag in head"'
check "${gates}" 0 'git commit -m "x" && git log -n 5'
check "${gates}" 0 'lefthook run pre-commit --all-files'
check "${gates}" 0 'SKIP_CONFIRM=1 just deploy'

secrets=guard-secret-exposure.sh
check "${secrets}" 2 'echo $SONAR_TOKEN'
check "${secrets}" 2 'echo "token: ${SONARCLOUD_TOKEN}"'
check "${secrets}" 2 'printf "%s\n" "$DD_API_KEY"'
check "${secrets}" 2 'source .env && echo $ALPIC_API_KEY'
check "${secrets}" 2 'if [ -n "$X" ]; then echo $GITHUB_TOKEN; fi'
check "${secrets}" 2 'for i in 1; do echo $X_TOKEN; done'
check "${secrets}" 2 'echo ${SONAR_TOKEN:0:6}'
check "${secrets}" 2 'env'
check "${secrets}" 2 'env | grep -i token'
check "${secrets}" 2 'printenv'
check "${secrets}" 2 'printenv SONAR_TOKEN'
check "${secrets}" 2 'export -p'
check "${secrets}" 2 'set'
check "${secrets}" 2 'cat .env'
check "${secrets}" 2 'cat api/.env.local'
check "${secrets}" 2 'grep TOKEN web/.env'
check "${secrets}" 2 'az keyvault secret show --vault-name kv --name sonar'
check "${secrets}" 2 'az account get-access-token'
check "${secrets}" 2 'az storage account keys list -n x'
check "${secrets}" 2 'gh auth token'
check "${secrets}" 2 'echo $(gh auth token)'
check "${secrets}" 2 'kubectl get secret foo -o yaml'
check "${secrets}" 2 'curl -v -H "Authorization: Bearer $SONAR_TOKEN" https://x'
check "${secrets}" 2 'dotnet user-secrets list'
check "${secrets}" 0 'echo ${#SONAR_TOKEN}'
check "${secrets}" 0 '[ -n "${SONAR_TOKEN:-}" ] && echo set || echo missing'
check "${secrets}" 0 'echo "$GH_TOKEN" | docker login ghcr.io --password-stdin'
check "${secrets}" 0 'curl -sf -H "Authorization: Bearer $SONAR_TOKEN" https://x'
check "${secrets}" 0 'TOKEN=$(az keyvault secret show --vault-name kv --name s --query value -o tsv)'
check "${secrets}" 0 'curl -H "Authorization: Bearer $(gh auth token)" https://x'
check "${secrets}" 0 'gh auth token | docker login --password-stdin'
check "${secrets}" 0 'cat .env.example'
check "${secrets}" 0 'env | cut -d= -f1'
check "${secrets}" 0 "printenv | cut -d'=' -f1 | grep TOKEN"
check "${secrets}" 0 'env FOO=1 npm test'
check "${secrets}" 0 'set -euo pipefail'
check "${secrets}" 0 'dotnet build'
check "${secrets}" 0 'cat README.md'

# The output scanner needs betterleaks; the fake token is built at run time so no file holds one.
# The fixture repo has no .betterleaks.toml, so this also covers the default-rules fallback.
if command -v betterleaks >/dev/null || mise which betterleaks >/dev/null 2>&1; then
  fake_token="sqp_$(openssl rand -hex 20)"
  leaked=$(jq -n --arg out "SONAR_TOKEN=${fake_token}" '{tool_response: {stdout: $out, stderr: ""}}' | "${hooks_dir}/scan-output-for-secrets.sh" | jq -r '.decision // empty')
  [[ "${leaked}" == "block" ]] || { echo "FAIL scan-output-for-secrets.sh: fake Sonar token not reported"; failures=$((failures + 1)); }
  clean=$(jq -n '{tool_response: {stdout: "all good", stderr: ""}}' | "${hooks_dir}/scan-output-for-secrets.sh")
  [[ -z "${clean}" ]] || { echo "FAIL scan-output-for-secrets.sh: clean output reported"; failures=$((failures + 1)); }
else
  echo "SKIP scan-output-for-secrets.sh: betterleaks not installed"
fi

if ((failures > 0)); then
  echo "${failures} case(s) failed"
  exit 1
fi
echo "All guard cases pass"
