#!/usr/bin/env bash
# Encrypt / decrypt the home secrets with sops + age (macOS and Ubuntu).
#   env  : ~/.env.secrets.yaml, loaded by mise [env] _.file and edited in place
#          (secrets:edit env); ~/.env.secrets (dotenv) is only an import/export format
#   kube : ~/.kube/config (yaml) <-> ~/.kube/config.sops.yaml (versioned in git)
# Usage: run-sops-encrypt.sh {edit|encrypt|decrypt|status} [env|kube|all]
# Through mise: mise run secrets:edit|secrets:encrypt|secrets:decrypt|secrets:status [env|kube]
# Never prints a secret value: only file names and states.

set -euo pipefail

export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-${HOME}/.config/sops/age/keys.txt}"

# Colors only on a terminal, and never when NO_COLOR is set (https://no-color.org)
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RED=$'\e[31m' GREEN=$'\e[32m' YELLOW=$'\e[33m' BLUE=$'\e[34m'
  BOLD=$'\e[1m' DIM=$'\e[2m' RESET=$'\e[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' BOLD='' DIM='' RESET=''
fi

info()  { printf '%sℹ️  %s%s\n' "${BLUE}" "$*" "${RESET}"; }
ok()    { printf '%s✅ %s%s\n' "${GREEN}" "$*" "${RESET}"; }
warn()  { printf '%s⚠️  %s%s\n' "${YELLOW}" "$*" "${RESET}" >&2; }
die()   { printf '%s❌ %s%s\n' "${RED}" "$*" "${RESET}" >&2; exit 1; }
title() { printf '\n%s%s %s%s\n' "${BOLD}" "$1" "$2" "${RESET}"; }

usage() {
  cat <<EOF
${BOLD}🔐 run-sops-encrypt.sh${RESET} — secrets sops + age du HOME

${BOLD}Usage :${RESET} $(basename "$0") {edit|encrypt|decrypt|status} [env|kube|all]

  ${GREEN}edit${RESET}     ✏️  édite le fichier chiffré dans \$EDITOR (env ou kube)
  ${GREEN}encrypt${RESET}  🔐 fichier en clair → fichier chiffré
  ${GREEN}decrypt${RESET}  🔓 fichier chiffré → fichier en clair (ancien gardé en .bak)
  ${GREEN}status${RESET}   🔎 présence, chiffrement et synchronisation

  ${BLUE}env${RESET}   🌱 ~/.env.secrets.yaml (~/.env.secrets : import/export seulement)
  ${BLUE}kube${RESET}  ☸️  ~/.kube/config  ↔ ~/.kube/config.sops.yaml
  ${BLUE}all${RESET}   les deux (défaut)

${DIM}Via mise : mise run secrets:edit env | secrets:status${RESET}
EOF
}

# Temporary files are removed on exit, whatever happens
TMP_FILES=()
cleanup() { rm -f ${TMP_FILES[@]+"${TMP_FILES[@]}"}; }
trap cleanup EXIT

SCOPE=all

set_target() {
  case "$1" in
    env)
      LABEL='🌱 env' TYPE=dotenv
      PLAIN="${HOME}/.env.secrets" SECRET="${HOME}/.env.secrets.yaml" ;;
    kube)
      LABEL='☸️  kube' TYPE=yaml
      PLAIN="${HOME}/.kube/config" SECRET="${HOME}/.kube/config.sops.yaml" ;;
    *) die "Cible inconnue : $1 (env, kube ou all)" ;;
  esac
}

# With "all", a missing file only skips its target; with an explicit target, it fails
missing() {
  [[ ${SCOPE} == all ]] || die "$*"
  warn "$* : ignoré"
}

require() {
  local cmd
  for cmd in sops age-keygen; do
    command -v "${cmd}" >/dev/null || die "${cmd} introuvable : lance « mise install »"
  done
  [[ -r ${SOPS_AGE_KEY_FILE} ]] || die "Clé age introuvable : ${SOPS_AGE_KEY_FILE}"
}

decrypt_to_stdout() {
  sops --decrypt --input-type yaml --output-type "${TYPE}" "${SECRET}"
}

encrypt() {
  set_target "$1"
  title '🔐' "Chiffrement ${LABEL}"
  [[ -f ${PLAIN} ]] || { missing "Fichier en clair absent : ${PLAIN}"; return 0; }
  # sops picks a new data key on each run: skip unchanged content to avoid git noise
  if [[ -s ${SECRET} ]] && cmp -s <(decrypt_to_stdout 2>/dev/null) "${PLAIN}"; then
    ok "Déjà à jour : ${SECRET}"
    return 0
  fi
  local recipients tmp
  recipients="$(age-keygen -y "${SOPS_AGE_KEY_FILE}" | paste -sd, -)"
  tmp="$(mktemp "${SECRET}.XXXXXX")"
  TMP_FILES+=("${tmp}")
  sops --config /dev/null --encrypt \
    --input-type "${TYPE}" --output-type yaml \
    --age "${recipients}" \
    --output "${tmp}" "${PLAIN}" || die "Échec du chiffrement : ${PLAIN}"
  chmod 600 "${tmp}"
  mv "${tmp}" "${SECRET}"
  ok "Chiffré : ${PLAIN} → ${SECRET}"
}

decrypt() {
  set_target "$1"
  title '🔓' "Déchiffrement ${LABEL}"
  [[ -s ${SECRET} ]] || { missing "Fichier chiffré absent : ${SECRET}"; return 0; }
  local tmp
  mkdir -p "$(dirname "${PLAIN}")"
  # mktemp creates the file with mode 600: the clear text is never world-readable
  tmp="$(mktemp "${PLAIN}.XXXXXX")"
  TMP_FILES+=("${tmp}")
  decrypt_to_stdout >"${tmp}" || die "Échec du déchiffrement : ${SECRET} (clé ${SOPS_AGE_KEY_FILE} ?)"
  if [[ -f ${PLAIN} ]]; then
    if cmp -s "${tmp}" "${PLAIN}"; then
      ok "Déjà à jour : ${PLAIN}"
      return 0
    fi
    cp -p "${PLAIN}" "${PLAIN}.bak"
    info "Ancienne version sauvegardée : ${PLAIN}.bak"
  fi
  mv "${tmp}" "${PLAIN}"
  ok "Déchiffré : ${SECRET} → ${PLAIN}"
}

edit() {
  set_target "$1"
  title '✏️ ' "Édition ${LABEL}"
  [[ -s ${SECRET} ]] || die "Fichier chiffré absent : ${SECRET}"
  # sops decrypts into a private temp file, opens $EDITOR, then re-encrypts in place
  local rc=0
  sops edit "${SECRET}" || rc=$?
  case ${rc} in
    0) ok "Enregistré : ${SECRET}" ;;
    200) info "Aucune modification : ${SECRET}"; return 0 ;;
    *) die "Échec de l'édition : ${SECRET}" ;;
  esac
  # kubectl reads the clear ~/.kube/config: refresh it
  if [[ $1 == kube ]]; then
    decrypt kube
  fi
}

status() {
  set_target "$1"
  title '🔎' "État ${LABEL}"
  if [[ $1 == env ]]; then
    # The clear dotenv is no longer needed: mise reads the encrypted file
    if [[ -f ${PLAIN} ]]; then
      warn "En clair encore présent : ${PLAIN} (inutile, à supprimer une fois chiffré)"
    else
      ok "Pas de fichier en clair : édition via « mise run secrets:edit env »"
    fi
  elif [[ -f ${PLAIN} ]]; then
    info "En clair : ${PLAIN}"
  else
    warn "En clair absent : ${PLAIN}"
  fi
  if [[ ! -s ${SECRET} ]]; then
    warn "Chiffré absent : ${SECRET}"
    return 0
  fi
  if ! sops filestatus "${SECRET}" 2>/dev/null | grep -q '"encrypted":true'; then
    warn "NON chiffré : ${SECRET}"
  elif ! decrypt_to_stdout >/dev/null 2>&1; then
    warn "Indéchiffrable avec ${SOPS_AGE_KEY_FILE} : ${SECRET}"
  elif [[ -f ${PLAIN} ]] && ! cmp -s <(decrypt_to_stdout 2>/dev/null) "${PLAIN}"; then
    warn "Désynchronisé : lance encrypt (clair plus récent) ou decrypt (chiffré plus récent)"
  else
    ok "Chiffré et à jour : ${SECRET}"
  fi
  # Checks that mise actually loads the secrets, without showing any value
  if [[ $1 == env ]] && command -v mise >/dev/null; then
    # shellcheck disable=SC2016 # expanded by the inner bash, inside the mise env
    if mise exec -- bash -c '[ -n "${SONARCLOUD_TOKEN:-}" ]' 2>/dev/null; then
      ok "mise charge les secrets (SONARCLOUD_TOKEN défini)"
    else
      warn "mise ne charge pas SONARCLOUD_TOKEN depuis ${SECRET}"
    fi
  fi
}

main() {
  local action="${1:-}" target
  SCOPE="${2:-all}"
  case "${action}" in
    edit) [[ ${SCOPE} != all ]] || die "edit : précise la cible (env ou kube)" ;;
    encrypt | decrypt | status) ;;
    -h | --help | help) usage; return 0 ;;
    '') usage; return 1 ;;
    *) usage >&2; die "Action inconnue : ${action}" ;;
  esac
  require
  if [[ ${SCOPE} == all ]]; then
    for target in env kube; do
      "${action}" "${target}"
    done
  else
    "${action}" "${SCOPE}"
  fi
}

main "$@"
