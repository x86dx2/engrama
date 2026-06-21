#!/usr/bin/env bash
# Suite do diff-binding do critique-gate.
# Prova o caminho forte por sha256, o fallback legado e o modo estrito.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GATE_SRC="$REPO_ROOT/.engrama/scripts/critique-gate.sh"
DIFF_HASH_SRC="$REPO_ROOT/.engrama/scripts/engrama-diff-hash.sh"
[ -f "$GATE_SRC" ] || { echo "FATAL: gate nao encontrado em $GATE_SRC"; exit 1; }
[ -f "$DIFF_HASH_SRC" ] || { echo "FATAL: helper de hash nao encontrado em $DIFF_HASH_SRC"; exit 1; }

_probe="$(mktemp -d 2>/dev/null)" || { echo "FATAL: mktemp indisponivel — abortando"; exit 3; }
git -C "$_probe" init -q 2>/dev/null || { echo "FATAL: git init indisponivel — abortando"; rm -rf "$_probe"; exit 3; }
rm -rf "$_probe"

PASS=0; FAIL=0; HOLES=0
RESULTS=""

new_repo() {
  local branch="$1" d
  d="$(mktemp -d 2>/dev/null || mktemp -d -t engrama-diffbind)"
  git -C "$d" init -q -b "$branch" 2>/dev/null || { git -C "$d" init -q; git -C "$d" checkout -q -b "$branch"; }
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  mkdir -p "$d/.engrama/scripts" "$d/.engrama/qa" "$d/.engrama/governance"
  cp "$GATE_SRC" "$d/.engrama/scripts/critique-gate.sh"
  cp "$DIFF_HASH_SRC" "$d/.engrama/scripts/engrama-diff-hash.sh"
  printf '# ledger\n' > "$d/.engrama/qa/criticas-do-executor.md"
  printf '%s' "$d"
}

write_ledger() {
  printf '%s\n' "$2" > "$1/.engrama/qa/criticas-do-executor.md"
}

run_gate() {
  local repo="$1" strict="${2:-0}"
  (
    cd "$repo" || exit 2
    if [ "$strict" = "1" ]; then
      ENGRAMA_REQUIRE_DIFF_BIND=1 bash ./.engrama/scripts/critique-gate.sh >/dev/null 2>&1
    else
      bash ./.engrama/scripts/critique-gate.sh >/dev/null 2>&1
    fi
    echo $?
  )
}

run_diff_hash() {
  (
    cd "$1" || exit 2
    bash ./.engrama/scripts/engrama-diff-hash.sh
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

# D1: hash que bate o diff staged => LIBERA
r="$(new_repo main)"
printf 'x\n' > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md
hash="$(run_diff_hash "$r")"
write_ledger "$r" "## [2026-06-20] main | [governance] x | confirmo | ref $hash"
git -C "$r" add .engrama/qa/criticas-do-executor.md
check D1 CORRETO 0 "$(run_gate "$r")" "sha256 correspondente ao diff staged libera"

# D2: arquivo alterado depois da critica => hash obsoleto => BLOQUEIA
r="$(new_repo main)"
printf 'v1\n' > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md
hash="$(run_diff_hash "$r")"
write_ledger "$r" "## [2026-06-20] main | [governance] x | confirmo | ref $hash"
git -C "$r" add .engrama/qa/criticas-do-executor.md
printf 'v2\n' > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md
check D2 CORRETO 2 "$(run_gate "$r")" "editar o arquivo apos a critica invalida o binding"

# D3: entrada sem hash preserva o legado => LIBERA
r="$(new_repo main)"
write_ledger "$r" "## [2026-06-20] main | [governance] x | confirmo | ref"
printf 'x\n' > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md .engrama/qa/criticas-do-executor.md
check D3 CORRETO 0 "$(run_gate "$r")" "sem sha256 o comportamento legado continua liberando"

# D4: modo estrito exige hash => entrada legada nao satisfaz
r="$(new_repo main)"
write_ledger "$r" "## [2026-06-20] main | [governance] x | confirmo | ref"
printf 'x\n' > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md .engrama/qa/criticas-do-executor.md
check D4 CORRETO 2 "$(run_gate "$r" 1)" "ENGRAMA_REQUIRE_DIFF_BIND=1 rejeita entrada sem sha256"

# D5: fingerprint estavel no mesmo staged e muda quando arquivo nao-ledger muda
r="$(new_repo main)"
printf 'v1\n' > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md
hash1="$(run_diff_hash "$r")"
hash2="$(run_diff_hash "$r")"
printf 'v2\n' > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md
hash3="$(run_diff_hash "$r")"
if [ "$hash1" = "$hash2" ] && [ "$hash1" != "$hash3" ]; then
  ok=0
else
  ok=1
fi
check D5 CORRETO 0 "$ok" "fingerprint repete no mesmo staged e muda ao alterar arquivo nao-ledger"

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: CORRETO = diff-binding verificado."
[ "$FAIL" -eq 0 ] || exit 1
