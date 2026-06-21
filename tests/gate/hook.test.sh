#!/usr/bin/env bash
# Suite do wrapper PreToolUse do critique gate.
# Valida deteccao de git commit, inclusive --no-verify, e fail-closed em
# cenarios de parse ausente/quebrado.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOOK_SRC="$REPO_ROOT/.engrama/scripts/critique-gate-hook.sh"
GATE_SRC="$REPO_ROOT/.engrama/scripts/critique-gate.sh"
DIFF_HASH_SRC="$REPO_ROOT/.engrama/scripts/engrama-diff-hash.sh"
BASH_BIN="$(command -v bash)"
[ -f "$HOOK_SRC" ] || { echo "FATAL: hook nao encontrado em $HOOK_SRC"; exit 1; }
[ -f "$GATE_SRC" ] || { echo "FATAL: gate nao encontrado em $GATE_SRC"; exit 1; }
[ -f "$DIFF_HASH_SRC" ] || { echo "FATAL: helper de hash nao encontrado em $DIFF_HASH_SRC"; exit 1; }
[ -n "$BASH_BIN" ] || { echo "FATAL: bash indisponivel no ambiente"; exit 1; }

_probe="$(mktemp -d 2>/dev/null)" || { echo "FATAL: mktemp indisponivel — abortando"; exit 3; }
git -C "$_probe" init -q 2>/dev/null || { echo "FATAL: git init indisponivel — abortando"; rm -rf "$_probe"; exit 3; }
rm -rf "$_probe"

PASS=0; FAIL=0; HOLES=0
RESULTS=""
TMPDIR_HOOK="$(mktemp -d 2>/dev/null || mktemp -d -t engrama-hook-test)"
trap 'rm -rf "$TMPDIR_HOOK"' EXIT
LAST_OUTPUT="$TMPDIR_HOOK/last-output.txt"
LAST_RC=0

check() {
  local id="$1" tag="$2" ok="$3" desc="$4" mark
  if [ "$ok" -eq 0 ]; then mark="ok"; PASS=$((PASS + 1)); else mark="XX"; FAIL=$((FAIL + 1)); fi
  [ "$tag" = "FURO" ] && HOLES=$((HOLES + 1))
  RESULTS="$RESULTS\n  [$mark] $id  ($tag)  | $desc"
}

new_repo() {
  local d
  d="$(mktemp -d 2>/dev/null || mktemp -d -t engrama-hook-test)"
  git -C "$d" init -q -b main 2>/dev/null || { git -C "$d" init -q; git -C "$d" checkout -q -b main; }
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  mkdir -p "$d/.engrama/scripts" "$d/.engrama/governance"
  cp "$HOOK_SRC" "$d/.engrama/scripts/critique-gate-hook.sh"
  cp "$GATE_SRC" "$d/.engrama/scripts/critique-gate.sh"
  cp "$DIFF_HASH_SRC" "$d/.engrama/scripts/engrama-diff-hash.sh"
  chmod +x "$d/.engrama/scripts/critique-gate-hook.sh" "$d/.engrama/scripts/critique-gate.sh" "$d/.engrama/scripts/engrama-diff-hash.sh"
  printf '%s' "$d"
}

stage_sensitive_change() {
  local repo="$1"
  mkdir -p "$repo/.engrama/governance"
  cat > "$repo/.engrama/governance/p.md" <<'EOF'
---
type: governance
status: active
date: 2026-06-21
---

Mudanca sensivel sem ledger.
EOF
  git -C "$repo" add .engrama/governance/p.md
}

build_path_without_python3() {
  local d cmd hash_cmd
  d="$(mktemp -d 2>/dev/null || mktemp -d -t engrama-hook-path)"
  ln -s "$BASH_BIN" "$d/bash"
  for cmd in git grep cat tr awk; do
    ln -s "$(command -v "$cmd")" "$d/$cmd"
  done

  if command -v shasum >/dev/null 2>&1; then
    hash_cmd="shasum"
  else
    hash_cmd="sha256sum"
  fi
  ln -s "$(command -v "$hash_cmd")" "$d/$hash_cmd"
  printf '%s' "$d"
}

run_hook() {
  local repo="$1" payload="$2" path_override="${3:-$PATH}"
  : > "$LAST_OUTPUT"
  (
    cd "$repo" || exit 2
    PATH="$path_override" CLAUDE_PROJECT_DIR="$repo" "$BASH_BIN" ./.engrama/scripts/critique-gate-hook.sh <<EOF
$payload
EOF
  ) >"$LAST_OUTPUT" 2>&1
  LAST_RC=$?
}

last_output_contains() {
  grep -Fq "$1" "$LAST_OUTPUT"
}

# H1: git commit simples => delega ao gate e bloqueia sem ledger
R="$(new_repo)"
stage_sensitive_change "$R"
run_hook "$R" '{"tool_input":{"command":"git commit -m x"}}'
if [ "$LAST_RC" -eq 2 ] && last_output_contains 'comando de commit detectado; delegando ao gate.' && last_output_contains 'commit BLOQUEADO'; then _r=0; else _r=1; fi
check H1 CORRETO "$_r" "git commit simples e interceptado pelo wrapper e bloqueado pelo gate sem ledger"

# H2: git commit --no-verify => tambem delega ao gate
R="$(new_repo)"
stage_sensitive_change "$R"
run_hook "$R" '{"tool_input":{"command":"git commit --no-verify -m x"}}'
if [ "$LAST_RC" -eq 2 ] && last_output_contains 'comando de commit detectado; delegando ao gate.' && last_output_contains 'commit BLOQUEADO'; then _r=0; else _r=1; fi
check H2 CORRETO "$_r" "git commit --no-verify continua interceptado pelo wrapper"

# H3: git status => ignora e sai 0
R="$(new_repo)"
stage_sensitive_change "$R"
run_hook "$R" '{"tool_input":{"command":"git status"}}'
if [ "$LAST_RC" -eq 0 ] && ! last_output_contains 'delegando ao gate'; then _r=0; else _r=1; fi
check H3 CORRETO "$_r" "git status e ignorado"

# H4: ls => ignora e sai 0
R="$(new_repo)"
stage_sensitive_change "$R"
run_hook "$R" '{"tool_input":{"command":"ls"}}'
if [ "$LAST_RC" -eq 0 ] && ! last_output_contains 'delegando ao gate'; then _r=0; else _r=1; fi
check H4 CORRETO "$_r" "comando nao-git e ignorado"

# H5: sem python3, mas payload parece commit => FAIL-CLOSED
R="$(new_repo)"
stage_sensitive_change "$R"
PATH_NO_PYTHON3="$(build_path_without_python3)"
run_hook "$R" '{"tool_input":{"command":"git commit -m x"}}' "$PATH_NO_PYTHON3"
if [ "$LAST_RC" -eq 2 ] && last_output_contains 'python3 ausente para inspecionar o comando de commit' && last_output_contains 'commit BLOQUEADO'; then _r=0; else _r=1; fi
check H5 CORRETO "$_r" "ausencia de python3 nao libera commit; wrapper falha fechado"

# H6: JSON malformado, mas payload bruto parece commit => FAIL-CLOSED
R="$(new_repo)"
stage_sensitive_change "$R"
run_hook "$R" '{"tool_input":{"command":"git commit -m x"'
if [ "$LAST_RC" -eq 2 ] && last_output_contains 'falha ao parsear o comando de commit' && last_output_contains 'commit BLOQUEADO'; then _r=0; else _r=1; fi
check H6 CORRETO "$_r" "JSON malformado com commit aparente tambem bloqueia"

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: CORRETO = comportamento esperado do wrapper fail-closed."
[ "$FAIL" -eq 0 ] || exit 1
