#!/usr/bin/env bash
# Contract tests da superficie do release-gate repo-central-only.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MANIFEST="$REPO_ROOT/.engrama/release-surface.manifest"
SYNC_SCRIPT="$REPO_ROOT/bin/sync-template.sh"
RELEASE_GATE="$REPO_ROOT/bin/release-gate.sh"

[ -f "$MANIFEST" ] || { echo "FATAL: manifest ausente em $MANIFEST"; exit 1; }
[ -f "$SYNC_SCRIPT" ] || { echo "FATAL: sync-template ausente em $SYNC_SCRIPT"; exit 1; }
[ -f "$RELEASE_GATE" ] || { echo "FATAL: release-gate ausente em $RELEASE_GATE"; exit 1; }

PASS=0; FAIL=0; HOLES=0; RESULTS=""

check() {
  local id="$1" tag="$2" ok="$3" desc="$4" mark
  if [ "$ok" -eq 0 ]; then mark="ok"; PASS=$((PASS + 1)); else mark="XX"; FAIL=$((FAIL + 1)); fi
  [ "$tag" = "FURO" ] && HOLES=$((HOLES + 1))
  RESULTS="$RESULTS\n  [$mark] $id  ($tag)  | $desc"
}

expand_manifest() {
  local rule prefix
  while IFS= read -r rule || [ -n "$rule" ]; do
    rule="${rule%$'\r'}"
    case "$rule" in
      ''|\#*)
        continue
        ;;
      */\*\*)
        prefix="${rule%/**}"
        find "$REPO_ROOT/$prefix" -type f | sed "s#^$REPO_ROOT/##" | sort
        ;;
      *)
        printf '%s\n' "$rule"
        ;;
    esac
  done < "$MANIFEST" | sort -u
}

sync_source_set() {
  root_var_value() {
    local var_name="$1"
    sed -n "s/^${var_name}=\"\\\$REPO_ROOT\\/\\(.*\\)\"$/\\1/p" "$SYNC_SCRIPT"
  }

  {
    printf '%s\n' ROOT_GATE
    # shellcheck disable=SC2016
    grep -Eo 'cp "\$ROOT_[A-Z_]+"' "$SYNC_SCRIPT" | sed 's/^cp "\$\([^"]*\)"$/\1/'
  } | sort -u | while IFS= read -r var_name; do
    [ -n "$var_name" ] || continue
    root_var_value "$var_name"
  done | sort -u
}

expected_surface_set() {
  {
    find "$REPO_ROOT/template" -type f | sed "s#^$REPO_ROOT/##" | sort
    sync_source_set
    printf '%s\n' \
      "VERSION" \
      ".engrama/CLAUDE.md" \
      ".engrama/engine/githooks/pre-commit" \
      ".engrama/engine/config/models.conf" \
      ".engrama/engine/config/subscriptions.conf" \
      "bin/bootstrap.sh" \
      "bin/install.sh"
  } | sort -u
}

manifest_expanded="$(expand_manifest)"
expected_expanded="$(expected_surface_set)"

if [ "$manifest_expanded" = "$expected_expanded" ]; then
  _r=0
else
  _r=1
fi
check RS1 CORRETO "$_r" "manifest expandido bate com template/** + fontes reais do sync-template + entrypoints distribuidos"

if ! printf '%s\n' "$manifest_expanded" | grep -Fxq 'bin/release-gate.sh'; then
  _r=0
else
  _r=1
fi
check RS2 CORRETO "$_r" "bin/release-gate.sh e root-only e nao entra no payload do manifest"

if ! printf '%s\n' "$manifest_expanded" | grep -Fxq 'bin/sync-template.sh'; then
  _r=0
else
  _r=1
fi
check RS3 CORRETO "$_r" "bin/sync-template.sh continua tooling de mantenedor fora do payload"

if [ ! -e "$REPO_ROOT/template/bin/release-gate.sh" ] && [ ! -e "$REPO_ROOT/template/.engrama/release-surface.manifest" ]; then
  _r=0
else
  _r=1
fi
check RS4 CORRETO "$_r" "template nao distribui release-gate nem o manifest root-only"

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: CORRETO = contrato esperado da superficie de release."
[ "$FAIL" -eq 0 ] || exit 1
