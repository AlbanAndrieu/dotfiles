#!/bin/zsh

set -euo pipefail

export SOPS_AGE_KEY_FILE="$HOME/.config/sops/age/keys.txt"

INPUT="$HOME/.env.secrets"
OUTPUT="$HOME/.env.secrets.yaml"
TEMP_OUTPUT="$(mktemp "$HOME/.env.secrets.yaml.XXXXXX")"

trap 'rm -f "$TEMP_OUTPUT"' EXIT

RECIPIENTS="$(age-keygen -y "$SOPS_AGE_KEY_FILE" | paste -sd, -)"

sops \
  --config /dev/null \
  --encrypt \
  --input-type dotenv \
  --output-type yaml \
  --age "$RECIPIENTS" \
  --output "$TEMP_OUTPUT" \
  "$INPUT"

chmod 600 "$TEMP_OUTPUT"
mv "$TEMP_OUTPUT" "$OUTPUT"

echo "Fichier SOPS créé : $OUTPUT"

# mise exec -- sh -c '
#   if [ -n "${SONARCLOUD_TOKEN:-}" ]; then
#     echo "SONARCLOUD_TOKEN est chargé"
#   else
#     echo "SONARCLOUD_TOKEN est absent"
#     exit 1
#   fi
# '

test -n "${SONARCLOUD_TOKEN:-}" \
  && echo "Variable chargée" \
  || echo "Variable absente"
