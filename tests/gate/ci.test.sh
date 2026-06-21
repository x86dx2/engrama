#!/usr/bin/env bash
# Suite do modo CI do critique gate.
# Valida o wrapper server-side com a mesma prova de hash do gate local: dado um
# base-ref real, uma branch e os arquivos mudados, ele reconstrui um repo
# sintetico equivalente e reaplica o critique-gate local.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GATE_SRC="$REPO_ROOT/.engrama/scripts/critique-gate.sh"
CI_GATE_SRC="$REPO_ROOT/critique-gate-ci.sh"
DIFF_HASH_SRC="$REPO_ROOT/engrama-diff-hash.sh"
[ -f "$GATE_SRC" ] || { echo "FATAL: gate nao encontrado em $GATE_SRC"; exit 1; }
[ -f "$CI_GATE_SRC" ] || { echo "FATAL: wrapper CI nao encontrado em $CI_GATE_SRC"; exit 1; }
[ -f "$DIFF_HASH_SRC" ] || { echo "FATAL: helper de hash nao encontrado em $DIFF_HASH_SRC"; exit 1; }

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
  mkdir -p "$d/.engrama/scripts" "$d/.engrama/qa" "$d/.engrama/governance"
  cp "$GATE_SRC" "$d/.engrama/scripts/critique-gate.sh"
  cp "$CI_GATE_SRC" "$d/critique-gate-ci.sh"
  cp "$DIFF_HASH_SRC" "$d/engrama-diff-hash.sh"
  printf '# ledger\n' > "$d/.engrama/qa/criticas-do-executor.md"
  git -C "$d" add .engrama/scripts/critique-gate.sh critique-gate-ci.sh engrama-diff-hash.sh .engrama/qa/criticas-do-executor.md
  git -C "$d" commit -qm base
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
  local repo="$1" branch="$2" base_ref="$3" files="$4" strict="${5:-0}"
  (
    cd "$repo" || exit 2
    if [ "$strict" = "1" ]; then
      ENGRAMA_REQUIRE_DIFF_BIND=1 \
        bash ./critique-gate-ci.sh --branch "$branch" --base-ref "$base_ref" --files-from "$files" >/dev/null 2>&1
    else
      bash ./critique-gate-ci.sh --branch "$branch" --base-ref "$base_ref" --files-from "$files" >/dev/null 2>&1
    fi
    echo $?
  )
}

run_diff_hash() {
  (
    cd "$1" || exit 2
    bash ./engrama-diff-hash.sh
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
printf 'x\n' > "$r/.engrama/governance/p.md"
files="$(write_files_list "$r" ".engrama/governance/p.md")"
check C1 CORRETO 2 "$(run_ci_gate "$r" "pr/ci-1" "HEAD" "$files")" "governanca do PR sem critica registrada bloqueia"

# C2: modo estrito na CI exige hash e libera quando o diff bate
r="$(new_repo pr/ci-2)"
printf 'x\n' > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md
hash="$(run_diff_hash "$r")"
write_ledger "$r" "## [2026-06-20] pr/ci-2 | [governance] x | confirmo | ref $hash"
files="$(write_files_list "$r" ".engrama/governance/p.md" ".engrama/qa/criticas-do-executor.md")"
check C2 CORRETO 0 "$(run_ci_gate "$r" "pr/ci-2" "HEAD" "$files" 1)" "modo estrito da CI libera quando sha256 bate o diff do PR"

# C3: arquivo alterado depois da critica => hash obsoleto => BLOQUEIA em modo estrito
r="$(new_repo pr/ci-3)"
printf 'v1\n' > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md
hash="$(run_diff_hash "$r")"
write_ledger "$r" "## [2026-06-20] pr/ci-3 | [governance] x | confirmo | ref $hash"
printf 'v2\n' > "$r/.engrama/governance/p.md"
files="$(write_files_list "$r" ".engrama/governance/p.md" ".engrama/qa/criticas-do-executor.md")"
check C3 CORRETO 2 "$(run_ci_gate "$r" "pr/ci-3" "HEAD" "$files" 1)" "modo estrito da CI bloqueia critica vinculada a diff antigo"

# C4: arquivo fora da superficie sensivel => LIBERA
r="$(new_repo pr/ci-4)"
printf 'x\n' > "$r/README-do-produto.txt"
files="$(write_files_list "$r" "README-do-produto.txt")"
check C4 CORRETO 0 "$(run_ci_gate "$r" "pr/ci-4" "HEAD" "$files" 1)" "diff nao sensivel nao vira burocracia na CI"

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: 'ok' = gate fez o esperado neste teste; CORRETO = comportamento bom; FURO = comportamento atual inseguro."
[ "$FAIL" -eq 0 ] || exit 1
