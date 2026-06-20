#!/usr/bin/env bash
# Suite do modo CI do critique gate.
# Valida o nucleo localmente: dado (branch, lista de arquivos), o wrapper monta
# um repo sintetico e reaproveita o gate local para classificar paths e ler o
# ledger por campo. O encanamento especifico do GitHub fica validado por revisao
# do workflow, nao por esta suite.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GATE_SRC="$REPO_ROOT/.engrama/scripts/critique-gate.sh"
CI_GATE_SRC="$REPO_ROOT/critique-gate-ci.sh"
[ -f "$GATE_SRC" ] || { echo "FATAL: gate nao encontrado em $GATE_SRC"; exit 1; }
[ -f "$CI_GATE_SRC" ] || { echo "FATAL: wrapper CI nao encontrado em $CI_GATE_SRC"; exit 1; }

_probe="$(mktemp -d 2>/dev/null)" || { echo "FATAL: mktemp indisponivel — abortando"; exit 3; }
git -C "$_probe" init -q 2>/dev/null || { echo "FATAL: git init indisponivel — abortando"; rm -rf "$_probe"; exit 3; }
rm -rf "$_probe"

PASS=0; FAIL=0; HOLES=0
RESULTS=""

new_repo() {
  local branch="$1" d
  d="$(mktemp -d 2>/dev/null || mktemp -d -t engrama-ci-test)"
  git -C "$d" init -q -b "$branch" 2>/dev/null || { git -C "$d" init -q; git -C "$d" checkout -q -b "$branch"; }
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  mkdir -p "$d/.engrama/scripts" "$d/.engrama/qa"
  cp "$GATE_SRC" "$d/.engrama/scripts/critique-gate.sh"
  cp "$CI_GATE_SRC" "$d/critique-gate-ci.sh"
  printf '# ledger\n' > "$d/.engrama/qa/criticas-do-executor.md"
  printf '%s' "$d"
}

write_ledger() {
  printf '%s\n' "$2" > "$1/.engrama/qa/criticas-do-executor.md"
}

write_files_list() {
  local repo="$1"
  local out="$repo/pr-files.zlist"
  shift
  printf '%s\0' "$@" > "$out"
  printf '%s' "$out"
}

run_ci_gate() {
  (
    cd "$1" || exit 2
    bash ./critique-gate-ci.sh --branch "$2" --files-from "$3" >/dev/null 2>&1
    echo $?
  )
}

check() {
  local id="$1" tag="$2" exp="$3" got="$4" desc="$5" mark
  if [ "$exp" = "$got" ]; then mark="ok"; PASS=$((PASS+1)); else mark="XX"; FAIL=$((FAIL+1)); fi
  [ "$tag" = "FURO" ] && HOLES=$((HOLES+1))
  local label
  case "$got" in
    0) label="LIBERA" ;;
    2) label="BLOQUEIA" ;;
    *) label="exit:$got" ;;
  esac
  RESULTS="$RESULTS\n  [$mark] $id  ($tag)  -> gate $label  | $desc"
}

# C1: governanca sem entrada no ledger => BLOQUEIA
r="$(new_repo pr/ci-1)"
files="$(write_files_list "$r" ".engrama/governance/p.md")"
check C1 CORRETO 2 "$(run_ci_gate "$r" "pr/ci-1" "$files")" "governanca do PR sem critica registrada bloqueia"

# C2: governanca com confirmo da branch exata => LIBERA
r="$(new_repo pr/ci-2)"
write_ledger "$r" "## [2026-06-20] pr/ci-2 | [governance] x | confirmo | ref"
files="$(write_files_list "$r" ".engrama/governance/p.md")"
check C2 CORRETO 0 "$(run_ci_gate "$r" "pr/ci-2" "$files")" "branch do PR com confirmo libera"

# C3: outra branch que cita o nome da branch no texto livre => BLOQUEIA
r="$(new_repo main)"
write_ledger "$r" "## [2026-06-20] outra | [governance] menciona a branch main no texto | confirmo | ref"
files="$(write_files_list "$r" ".engrama/governance/p.md")"
check C3 CORRETO 2 "$(run_ci_gate "$r" "main" "$files")" "parsing continua por campo; citacao em texto livre nao libera"

# C4: arquivo fora da superficie sensivel => LIBERA
r="$(new_repo pr/ci-4)"
files="$(write_files_list "$r" "README-do-produto.txt")"
check C4 CORRETO 0 "$(run_ci_gate "$r" "pr/ci-4" "$files")" "diff nao sensivel nao vira burocracia na CI"

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: 'ok' = gate fez o esperado neste teste; CORRETO = comportamento bom; FURO = comportamento atual inseguro."
[ "$FAIL" -eq 0 ] || exit 1
