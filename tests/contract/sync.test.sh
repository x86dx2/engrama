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
ROOT_LINT="$REPO_ROOT/.engrama/scripts/lint.sh"
TEMPLATE_LINT="$REPO_ROOT/template/.engrama/scripts/lint.sh"
ROOT_DIFF_HASH="$REPO_ROOT/.engrama/scripts/engrama-diff-hash.sh"
TEMPLATE_DIFF_HASH="$REPO_ROOT/template/.engrama/scripts/engrama-diff-hash.sh"
ROOT_EXEC_BRIDGE="$REPO_ROOT/.engrama/scripts/exec-bridge.sh"
TEMPLATE_EXEC_BRIDGE="$REPO_ROOT/template/.engrama/scripts/exec-bridge.sh"
ROOT_CI_GATE="$REPO_ROOT/bin/critique-gate-ci.sh"
TEMPLATE_CI_GATE="$REPO_ROOT/template/bin/critique-gate-ci.sh"
ROOT_MARKDOWNLINT="$REPO_ROOT/.markdownlint-cli2.yaml"
TEMPLATE_MARKDOWNLINT="$REPO_ROOT/template/.markdownlint-cli2.yaml"
ROOT_SETTINGS="$REPO_ROOT/.claude/settings.json"
TEMPLATE_SETTINGS="$REPO_ROOT/template/.claude/settings.json"
ROOT_CI="$REPO_ROOT/.github/workflows/ci.yml"
TEMPLATE_CI="$REPO_ROOT/template/.github/workflows/ci.yml"
SYNC_SCRIPT="$REPO_ROOT/bin/sync-template.sh"

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

yaml_has_expected_jobs() {
  local file="$1"
  if command -v ruby >/dev/null 2>&1; then
    ruby -e '
      require "yaml"
      data = YAML.load_file(ARGV[0])
      jobs = data["jobs"]
      exit(jobs.is_a?(Hash) && %w[gate gitleaks markdown].all? { |job| jobs.key?(job) } ? 0 : 1)
    ' "$file"
    return $?
  fi

  grep -Eq '^jobs:$' "$file" &&
    grep -Eq '^  gate:$' "$file" &&
    grep -Eq '^  gitleaks:$' "$file" &&
    grep -Eq '^  markdown:$' "$file"
}

extract_gitleaks_version() {
  sed -n 's/.*version="\([0-9][0-9.]*\)".*/\1/p' "$1" | head -n 1
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

if grep -Fq 'bin/*) addcat gate ;;' "$ROOT_GATE" && [ -f "$SYNC_SCRIPT" ]; then _r=0; else _r=1; fi
check S3 CORRETO "$_r" "gate reconhece bin/* como tooling sensivel e o sync existe"

if grep -Fq 'VERSION|template/.engrama/VERSION|bin/*) addcat gate ;;' "$ROOT_GATE"; then _r=0; else _r=1; fi
check S3A CORRETO "$_r" "gate da raiz classifica VERSION e template/.engrama/VERSION como gate"

if cmp -s "$ROOT_LINT" "$TEMPLATE_LINT"; then _r=0; else _r=1; fi
check S3B CORRETO "$_r" "lint.sh do template identico ao da raiz"

if cmp -s "$ROOT_DIFF_HASH" "$TEMPLATE_DIFF_HASH"; then _r=0; else _r=1; fi
check S3C CORRETO "$_r" "engrama-diff-hash.sh do template identico ao da raiz"

if cmp -s "$ROOT_EXEC_BRIDGE" "$TEMPLATE_EXEC_BRIDGE"; then _r=0; else _r=1; fi
check S3CA CORRETO "$_r" "exec-bridge.sh do template identico ao da raiz"

if cmp -s "$ROOT_CI_GATE" "$TEMPLATE_CI_GATE"; then _r=0; else _r=1; fi
check S3CB CORRETO "$_r" "template/bin/critique-gate-ci.sh identico ao da raiz"

if cmp -s "$ROOT_MARKDOWNLINT" "$TEMPLATE_MARKDOWNLINT"; then _r=0; else _r=1; fi
check S3CC CORRETO "$_r" "template/.markdownlint-cli2.yaml identico ao da raiz"

if cmp -s "$ROOT_SETTINGS" "$TEMPLATE_SETTINGS"; then _r=0; else _r=1; fi
check S3D CORRETO "$_r" "settings.json do template identico ao da raiz"

if grep -Fq 'ROOT_CI_GATE=' "$SYNC_SCRIPT" && grep -Fq 'TEMPLATE_CI_GATE=' "$SYNC_SCRIPT" && grep -Fq 'ROOT_MARKDOWNLINT=' "$SYNC_SCRIPT" && grep -Fq 'TEMPLATE_MARKDOWNLINT=' "$SYNC_SCRIPT"; then
  _r=0
else
  _r=1
fi
check S3E CORRETO "$_r" "sync-template sincroniza critique-gate-ci.sh e .markdownlint-cli2.yaml"

if grep -Fq '{{EXECUTOR_CMD}}' "$TEMPLATE_GATE" && grep -Fq '{{MODELO_CRITICA}}' "$TEMPLATE_GATE"; then _r=0; else _r=1; fi
check S4 CORRETO "$_r" "template preserva placeholders do gate"

if grep -Fq '.engrama/VERSION' "$TEMPLATE_GATE"; then
  _r=0
else
  _r=1
fi
check S4A CORRETO "$_r" "gate do template classifica .engrama/VERSION como gate"

if grep -Fq '.engrama/VERSION|.engrama/scripts/*.sh|.engrama/githooks/*|.claude/settings.json|.engrama/scripts/exec-bridge.sh) addcat gate ;;' "$TEMPLATE_GATE"; then
  _r=0
else
  _r=1
fi
check S4B CORRETO "$_r" "gate do template classifica .engrama/scripts/exec-bridge.sh como gate"

if grep -Fq '# src/server/services/agreements.*|src/server/services/ledger.*)    addcat financial ;;' "$TEMPLATE_GATE" \
  && grep -Fq '# src/server/permissions.*|src/server/services/users.*)             addcat rbac ;;' "$TEMPLATE_GATE" \
  && grep -Fq '# src/server/auth.*|src/app/api/*/auth/*)                           addcat auth ;;' "$TEMPLATE_GATE" \
  && grep -Fq '# migrations/*)                                                     addcat schema ;;' "$TEMPLATE_GATE"; then
  _r=0
else
  _r=1
fi
check S5 CORRETO "$_r" "template preserva exemplos de dominio comentados"

if [ -f "$TEMPLATE_CI" ]; then
  _r=0
else
  _r=1
fi
check S6 CORRETO "$_r" "template/.github/workflows/ci.yml existe"

if yaml_has_expected_jobs "$TEMPLATE_CI"; then
  _r=0
else
  _r=1
fi
check S6A CORRETO "$_r" "ci do template e YAML valido (ou, sem parser, declara gate/gitleaks/markdown)"

if grep -Fq 'bin/critique-gate-ci.sh' "$TEMPLATE_CI"; then
  _r=0
else
  _r=1
fi
check S6B CORRETO "$_r" "ci do template referencia bin/critique-gate-ci.sh"

root_gitleaks_version="$(extract_gitleaks_version "$ROOT_CI")"
template_gitleaks_version="$(extract_gitleaks_version "$TEMPLATE_CI")"
if [ "$root_gitleaks_version" = "8.30.1" ] && [ "$template_gitleaks_version" = "$root_gitleaks_version" ]; then
  _r=0
else
  _r=1
fi
check S6C CORRETO "$_r" "pin do gitleaks no ci do template bate com a raiz (v8.30.1)"

if cmp -s "$ROOT_CI" "$TEMPLATE_CI"; then
  _r=1
else
  _r=0
fi
check S6D CORRETO "$_r" "ci do template nao e identico ao da raiz (por design)"

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: CORRETO = contrato esperado entre raiz e template."
[ "$FAIL" -eq 0 ] || exit 1
