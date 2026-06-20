#!/usr/bin/env bash
# Contract tests da sincronizacao raiz -> template.
# Detecta drift da logica do gate, hook divergente e referencia fantasma ao
# sincronizador. Uso: bash tests/contract/sync.test.sh
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ROOT_GATE="$REPO_ROOT/.engrama/scripts/critique-gate.sh"
TEMPLATE_GATE="$REPO_ROOT/template/.engrama/scripts/critique-gate.sh"
ROOT_HOOK="$REPO_ROOT/.engrama/scripts/critique-gate-hook.sh"
TEMPLATE_HOOK="$REPO_ROOT/template/.engrama/scripts/critique-gate-hook.sh"
ROOT_SESSION_CONTEXT="$REPO_ROOT/.engrama/scripts/session-context.sh"
TEMPLATE_SESSION_CONTEXT="$REPO_ROOT/template/.engrama/scripts/session-context.sh"
ROOT_LINT="$REPO_ROOT/lint.sh"
TEMPLATE_LINT="$REPO_ROOT/template/lint.sh"
ROOT_SETTINGS="$REPO_ROOT/.claude/settings.json"
TEMPLATE_SETTINGS="$REPO_ROOT/template/.claude/settings.json"
SYNC_SCRIPT="$REPO_ROOT/sync-template.sh"

PASS=0; FAIL=0; HOLES=0; RESULTS=""

_probe="$(mktemp -d 2>/dev/null)" || { echo "FATAL: mktemp indisponivel — abortando"; exit 3; }
git -C "$_probe" init -q 2>/dev/null || { echo "FATAL: git init indisponivel — abortando"; rm -rf "$_probe"; exit 3; }
rm -rf "$_probe"

check() { # <id> <tag> <cond 0/1> <desc>
  local id="$1" tag="$2" ok="$3" desc="$4" mark
  if [ "$ok" -eq 0 ]; then mark="ok"; PASS=$((PASS+1)); else mark="XX"; FAIL=$((FAIL+1)); fi
  [ "$tag" = "FURO" ] && HOLES=$((HOLES+1))
  RESULTS="$RESULTS\n  [$mark] $id  ($tag)  | $desc"
}

extract_logic_without_template_config() {
  local src="$1" out="$2"
  awk '
    BEGIN { mode = "prefix" }
    /^EXECUTOR_CMD=/{ mode = "skip_vars"; next }
    mode == "prefix" { print; next }
    mode == "skip_vars" && /^REPO_ROOT=/{ mode = "middle" }
    mode == "middle" && /CONFIG DO PROJETO:/{ mode = "skip_classify"; next }
    mode == "middle" { print; next }
    mode == "skip_classify" && /^while IFS= read -r /{ mode = "tail" }
    mode == "tail" { print }
  ' "$src" > "$out"
}

TMPDIR_SYNC="$(mktemp -d 2>/dev/null || mktemp -d -t engrama-sync-test)"
trap 'rm -rf "$TMPDIR_SYNC"' EXIT

extract_logic_without_template_config "$ROOT_GATE" "$TMPDIR_SYNC/root.logic"
extract_logic_without_template_config "$TEMPLATE_GATE" "$TMPDIR_SYNC/template.logic"

if cmp -s "$TMPDIR_SYNC/root.logic" "$TMPDIR_SYNC/template.logic"; then _r=0; else _r=1; fi
check S1 CORRETO "$_r" "gate raiz/template com logica identica fora vars placeholder + classify"

if cmp -s "$ROOT_HOOK" "$TEMPLATE_HOOK"; then _r=0; else _r=1; fi
check S2 CORRETO "$_r" "hook do template identico ao da raiz"

if cmp -s "$ROOT_SESSION_CONTEXT" "$TEMPLATE_SESSION_CONTEXT"; then _r=0; else _r=1; fi
check S2B CORRETO "$_r" "session-context do template identico ao da raiz"

if grep -q 'sync-template\.sh' "$ROOT_GATE" && [ -f "$SYNC_SCRIPT" ]; then _r=0; else _r=1; fi
check S3 CORRETO "$_r" "referencia a sync-template.sh resolve para arquivo existente"

if cmp -s "$ROOT_LINT" "$TEMPLATE_LINT"; then _r=0; else _r=1; fi
check S3B CORRETO "$_r" "lint.sh do template identico ao da raiz"

if cmp -s "$ROOT_SETTINGS" "$TEMPLATE_SETTINGS"; then _r=0; else _r=1; fi
check S3C CORRETO "$_r" "settings.json do template identico ao da raiz"

if grep -Fq '{{EXECUTOR_CMD}}' "$TEMPLATE_GATE" && grep -Fq '{{MODELO_CRITICA}}' "$TEMPLATE_GATE"; then _r=0; else _r=1; fi
check S4 CORRETO "$_r" "template preserva placeholders do gate"

if grep -Fq '# src/server/services/agreements.*|src/server/services/ledger.*)    addcat financial ;;' "$TEMPLATE_GATE" \
  && grep -Fq '# src/server/permissions.*|src/server/services/users.*)             addcat rbac ;;' "$TEMPLATE_GATE" \
  && grep -Fq '# src/server/auth.*|src/app/api/*/auth/*)                           addcat auth ;;' "$TEMPLATE_GATE" \
  && grep -Fq '# migrations/*)                                                     addcat schema ;;' "$TEMPLATE_GATE"; then
  _r=0
else
  _r=1
fi
check S5 CORRETO "$_r" "template preserva exemplos de dominio comentados"

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: CORRETO = contrato esperado entre raiz e template."
[ "$FAIL" -eq 0 ] || exit 1
