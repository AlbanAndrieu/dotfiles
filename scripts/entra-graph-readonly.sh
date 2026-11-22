#!/usr/bin/env bash
# Personal Entra Nabla CLI session: interactive browser/FIDO2, Graph read-only.
set -euo pipefail
fail() { printf 'ENTRA_NABLA_BLOCKED: %s\n' "$1" >&2; exit 2; }
[[ "${ENTRA_NABLA_TENANT_ID:-}" =~ ^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$ ]] || fail "set ENTRA_NABLA_TENANT_ID to the personal tenant GUID"
command -v az >/dev/null 2>&1 || fail "Azure CLI not installed; use mise install azure-cli"

# Never reuse a cached company account accidentally. Credentials remain local.
export AZURE_CONFIG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/nabla-entra/azure-cli"
install -d -m 0700 "$AZURE_CONFIG_DIR"
mode="${1:-verify}"
case "$mode" in
  login)
    printf '%s\n' "Use the browser and choose the enrolled physical YubiKey/passkey."
    az login --tenant "$ENTRA_NABLA_TENANT_ID" --allow-no-subscriptions --output none ||
      fail "interactive sign-in failed; verify passkey registration in the Entra directory"
    ;;
  verify|me|apps) ;;
  *) fail "supported modes: login, verify, me, apps" ;;
esac

actual="$(az account show --query tenantId -o tsv 2>/dev/null)" ||
  fail "login required: mise run entra:login"
[[ "$actual" == "$ENTRA_NABLA_TENANT_ID" ]] ||
  fail "selected Azure CLI tenant does not match ENTRA_NABLA_TENANT_ID"
case "$mode" in
  login|verify)
    printf 'ENTRA_NABLA_TENANT_VERIFIED: tenant selected, no tokens printed\n'
    ;;
  me)
    az rest --method GET --url 'https://graph.microsoft.com/v1.0/me' --output json
    ;;
  apps)
    az rest --method GET --url 'https://graph.microsoft.com/v1.0/applications?$top=20&$select=id,appId,displayName' --output json
    ;;
esac
