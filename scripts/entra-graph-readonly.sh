#!/usr/bin/env bash
# Read-only Graph queries in personal Entra tenant. Never print bearer tokens.
set -euo pipefail
fail() { printf 'ENTRA_GRAPH_BLOCKED: %s\n' "$1" >&2; exit 2; }
[[ "${ENTRA_LAB_TENANT_ID:-}" =~ ^[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}$ ]] || fail "set an explicit personal tenant GUID"
command -v az >/dev/null 2>&1 || fail "Azure CLI not installed; review mise install azure-cli"
actual="$(az account show --query tenantId -o tsv 2>/dev/null)" || fail "az login --tenant PERSONAL_GUID required"
[[ "$actual" == "$ENTRA_LAB_TENANT_ID" ]] || fail "active tenant does not match personal lab"
case "${1:-verify}" in
  verify)
    printf 'ENTRA_LAB_TENANT_VERIFIED: expected tenant selected; no credentials shown\n'
    ;;
  me)
    az rest --method GET --url "https://graph.microsoft.com/v1.0/me" --output json
    ;;
  apps)
    az rest --method GET --url 'https://graph.microsoft.com/v1.0/applications?$top=20&$select=id,appId,displayName' --output json
    ;;
  *)
    fail "supported modes: verify, me, apps"
    ;;
esac
