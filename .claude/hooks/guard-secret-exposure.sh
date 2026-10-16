#!/usr/bin/env bash
# PreToolUse hook (Bash) — block a command that would print a secret into the agent's context.
#
# Whatever a command prints reaches the model, its transcript and its logs: a token printed once
# (SONAR_TOKEN, SONARCLOUD_TOKEN…) must be rotated. The command only holds the variable *name*,
# so this hook matches names by suffix (_TOKEN, _API_KEY, _SECRET, _PASSWORD…); betterleaks,
# which matches *values*, scans the output afterwards (scan-output-for-secrets.sh).
#
# Blocked, per command of the line (split on ; && || and newlines):
#   - echo/printf of a secret-named variable, unless piped or redirected (`echo "$T" | docker login --password-stdin`);
#   - environment dumps: env, printenv, set, export -p, declare -p/-x (unless cut to the names), and `printenv <SECRET_NAME>`;
#   - reading a dotenv file (.env, .env.local…; .env.example and friends stay readable);
#   - CLIs that print a secret (az keyvault secret show, gh auth token, kubectl get secret -o yaml…),
#     unless captured by `$(…)` or piped into a `--password-stdin`;
#   - curl --verbose/--trace with a secret-named variable (prints the Authorization header).
set -uo pipefail

command=$(jq -r '.tool_input.command // empty' 2>/dev/null)
[[ -n "${command}" ]] || exit 0

secret_name='[A-Za-z0-9_]*(TOKEN|SECRET|PASSWORD|PASSWD|API_?KEY|_KEY|_PAT|_SAS|CREDENTIALS?|CONNECTION_?STRING)'
secret_variable="\\\$\\{?${secret_name}([^A-Za-z0-9_]|\$)"
secret_cli='az[[:space:]]+keyvault[[:space:]]+(secret|key|certificate)[[:space:]]+(show|download)|az[[:space:]]+account[[:space:]]+get-access-token|az[[:space:]].*(keys[[:space:]]+list|list-keys|show-connection-string|listKeys|listSecrets|list-secrets|credential[[:space:]]+(reset|list)|create-for-rbac)|gh[[:space:]]+auth[[:space:]]+(token|status[[:space:]].*(-t|--show-token))|kubectl[[:space:]]+get[[:space:]]+secrets?([[:space:]].*)?[[:space:]](-o|--output)[[:space:]=]*(yaml|json|jsonpath|go-template)|dotnet[[:space:]]+user-secrets[[:space:]]+list|security[[:space:]]+find-(generic|internet)-password[[:space:]].*-w'

deny() {
  cat >&2 <<EOF
🚫 BLOCKED: ${1}

Never print a secret: whatever a command prints reaches the model, the transcript and the logs,
and the secret then has to be rotated. Use the value without showing it:
  - check it is set:   [ -n "\${SONAR_TOKEN:-}" ] && echo set || echo missing
  - check its length:  echo "\${#SONAR_TOKEN}"
  - pass it inline:    curl -H "Authorization: Bearer \${SONAR_TOKEN}" …   (no -v)
  - capture a CLI one: TOKEN=\$(az keyvault secret show … --query value -o tsv)
  - list names only:   env | cut -d= -f1
If you really need the value, ask the user.
If the match is only text (a commit message, a heredoc), write it to a file with the Write tool
and pass the file instead (\`git commit -F <file>\`, \`gh pr create --body-file <file>\`).
EOF
  exit 2
}

segments=$(awk '{ gsub(/&&|\|\||;/, "\n"); print }' <<<"${command}")
while IFS= read -r segment; do
  # Drop leading shell keywords and grouping so `then echo $T` is seen as `echo $T`.
  segment=$(sed -E 's/^[[:space:]]*((then|do|else|elif|if|while|until|time)[[:space:]]+|[!{(][[:space:]]*)*//' <<<"${segment}")
  [[ -n "${segment}" ]] || continue
  first_command=${segment%%|*}
  first_command=$(sed -E 's/[[:space:]]+$//' <<<"${first_command}")

  if grep -Eq '^(echo|printf|print)([[:space:]]|$)' <<<"${segment}" \
    && ! grep -q '[|>]' <<<"${segment}" \
    && grep -Eqi "${secret_variable}" <<<"${segment}"; then
    deny "this prints a secret-named variable: \`${segment}\`."
  fi

  if grep -Eq '^(env|printenv|set|export|export[[:space:]]+-p|declare[[:space:]]+-[A-Za-z]*[px][A-Za-z]*|typeset[[:space:]]+-[A-Za-z]*x[A-Za-z]*)$' <<<"${first_command}" \
    && ! grep -Eq "\|[[:space:]]*cut[[:space:]]+-d[[:space:]]*[\"']?=[\"']?[[:space:]]+-f[[:space:]]*1([[:space:]]|\$)" <<<"${segment}"; then
    deny "\`${first_command}\` dumps the environment, secrets included."
  fi

  if grep -Eqi "^printenv[[:space:]]+${secret_name}([[:space:]]|\$)" <<<"${first_command}"; then
    deny "\`${first_command}\` prints a secret."
  fi

  if grep -Eq '^(cat|bat|less|more|head|tail|nl|strings|xxd|od|hexdump|grep|egrep|rg|ag|awk|sed|cut|sort|uniq|column|jq|yq)([[:space:]]|$)' <<<"${segment}" \
    && grep -Eq '(^|[[:space:]/"'"'"'=])\.env(\.[A-Za-z0-9_-]+)*([[:space:]"'"'"']|$)' <<<"${segment}" \
    && ! grep -Eq '\.env\.(example|sample|template|dist|defaults|schema)([[:space:]"'"'"']|$)' <<<"${segment}"; then
    deny "this reads a dotenv file, which holds secrets: \`${segment}\`."
  fi

  if grep -Eq "(${secret_cli})" <<<"${segment}"; then
    if grep -Eq '^(echo|printf|print|cat)([[:space:]]|$)' <<<"${segment}" \
      || ! grep -Eq "(\\\$\\([[:space:]]*(${secret_cli})|--password-stdin)" <<<"${segment}"; then
      deny "this prints a secret from a CLI: \`${segment}\`."
    fi
  fi

  if grep -Eq '(^|[[:space:]])curl[[:space:]]' <<<"${segment}" \
    && grep -Eq '[[:space:]](-[A-Za-z]*v[A-Za-z]*|--verbose|--trace|--trace-ascii)([[:space:]=]|$)' <<<"${segment}" \
    && grep -Eqi "${secret_variable}" <<<"${segment}"; then
    deny "\`curl\` in verbose/trace mode prints the request headers, secret included."
  fi
done <<<"${segments}"

exit 0
