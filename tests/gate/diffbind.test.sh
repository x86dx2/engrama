#!/usr/bin/env bash
# Suite do diff-binding do critique-gate.
# Prova o caminho forte por sha256, o fallback legado e o modo estrito.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GATE_SRC="$REPO_ROOT/.engrama/engine/scripts/critique-gate.sh"
DIFF_HASH_SRC="$REPO_ROOT/.engrama/engine/scripts/engrama-diff-hash.sh"
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
  mkdir -p "$d/.engrama/engine/scripts" "$d/.engrama/evidence/qa" "$d/.engrama/memory/governance"
  cp "$GATE_SRC" "$d/.engrama/engine/scripts/critique-gate.sh"
  cp "$DIFF_HASH_SRC" "$d/.engrama/engine/scripts/engrama-diff-hash.sh"
  printf '# ledger\n' > "$d/.engrama/evidence/qa/criticas-do-executor.md"
  printf '%s' "$d"
}

write_ledger() {
  printf '%s\n' "$2" > "$1/.engrama/evidence/qa/criticas-do-executor.md"
}

run_gate() {
  local repo="$1" strict="${2:-0}" override_hash="${3:-}"
  (
    cd "$repo" || exit 2
    if [ -n "$override_hash" ]; then
      export ENGRAMA_DIFF_HASH="$override_hash"
    fi
    if [ "$strict" = "1" ]; then
      ENGRAMA_REQUIRE_DIFF_BIND=1 bash ./.engrama/engine/scripts/critique-gate.sh >/dev/null 2>&1
    else
      bash ./.engrama/engine/scripts/critique-gate.sh >/dev/null 2>&1
    fi
    echo $?
  )
}

run_diff_hash_cached() {
  (
    cd "$1" || exit 2
    bash ./.engrama/engine/scripts/engrama-diff-hash.sh --cached
  )
}

run_diff_hash_range() {
  (
    cd "$1" || exit 2
    bash ./.engrama/engine/scripts/engrama-diff-hash.sh --range "$2"
  )
}

manual_legacy_hash() {
  local repo="$1" mode="$2" range="${3:-}"
  (
    cd "$repo" || exit 2
    case "$mode" in
      cached)
        git diff --cached --raw -z -- . ':(exclude).engrama/evidence/qa/criticas-do-executor.md'
        ;;
      range)
        git diff --raw -z "$range" -- . ':(exclude).engrama/evidence/qa/criticas-do-executor.md'
        ;;
      *)
        exit 2
        ;;
    esac |
      if command -v sha256sum >/dev/null 2>&1; then
        sha256sum
      else
        shasum -a 256
      fi | awk 'NR == 1 { print "sha256:" $1 }'
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
printf 'x\n' > "$r/.engrama/memory/governance/p.md"
git -C "$r" add .engrama/memory/governance/p.md
hash="$(run_diff_hash_cached "$r")"
write_ledger "$r" "## [2026-06-20] main | [governance] x | confirmo | ref $hash"
git -C "$r" add .engrama/evidence/qa/criticas-do-executor.md
check D1 CORRETO 0 "$(run_gate "$r")" "sha256 correspondente ao diff staged libera"

# D2: arquivo alterado depois da critica => hash obsoleto => BLOQUEIA
r="$(new_repo main)"
printf 'v1\n' > "$r/.engrama/memory/governance/p.md"
git -C "$r" add .engrama/memory/governance/p.md
hash="$(run_diff_hash_cached "$r")"
write_ledger "$r" "## [2026-06-20] main | [governance] x | confirmo | ref $hash"
git -C "$r" add .engrama/evidence/qa/criticas-do-executor.md
printf 'v2\n' > "$r/.engrama/memory/governance/p.md"
git -C "$r" add .engrama/memory/governance/p.md
check D2 CORRETO 2 "$(run_gate "$r")" "editar o arquivo apos a critica invalida o binding"

# D3: entrada sem hash preserva o legado => LIBERA
r="$(new_repo main)"
write_ledger "$r" "## [2026-06-20] main | [governance] x | confirmo | ref"
printf 'x\n' > "$r/.engrama/memory/governance/p.md"
git -C "$r" add .engrama/memory/governance/p.md .engrama/evidence/qa/criticas-do-executor.md
check D3 CORRETO 0 "$(run_gate "$r")" "sem sha256 o comportamento legado continua liberando"

# D4: modo estrito exige hash => entrada legada nao satisfaz
r="$(new_repo main)"
write_ledger "$r" "## [2026-06-20] main | [governance] x | confirmo | ref"
printf 'x\n' > "$r/.engrama/memory/governance/p.md"
git -C "$r" add .engrama/memory/governance/p.md .engrama/evidence/qa/criticas-do-executor.md
check D4 CORRETO 2 "$(run_gate "$r" 1)" "ENGRAMA_REQUIRE_DIFF_BIND=1 rejeita entrada sem sha256"

# D5: fingerprint estavel no mesmo staged e muda quando arquivo nao-ledger muda
r="$(new_repo main)"
printf 'v1\n' > "$r/.engrama/memory/governance/p.md"
git -C "$r" add .engrama/memory/governance/p.md
hash1="$(run_diff_hash_cached "$r")"
hash2="$(run_diff_hash_cached "$r")"
printf 'v2\n' > "$r/.engrama/memory/governance/p.md"
git -C "$r" add .engrama/memory/governance/p.md
hash3="$(run_diff_hash_cached "$r")"
if [ "$hash1" = "$hash2" ] && [ "$hash1" != "$hash3" ]; then
  ok=0
else
  ok=1
fi
check D5 CORRETO 0 "$ok" "fingerprint repete no mesmo staged e muda ao alterar arquivo nao-ledger"

# D6: num PR de 1 commit, --cached (antes do commit) == --range base...HEAD (apos commit)
r="$(new_repo main)"
git -C "$r" add .engrama/engine/scripts/critique-gate.sh .engrama/engine/scripts/engrama-diff-hash.sh .engrama/evidence/qa/criticas-do-executor.md
git -C "$r" commit -qm base
git -C "$r" branch base
git -C "$r" checkout -q -b pr/d6
printf 'x\n' > "$r/.engrama/memory/governance/p.md"
git -C "$r" add .engrama/memory/governance/p.md
cached_hash="$(run_diff_hash_cached "$r")"
git -C "$r" commit -qm pr
range_hash="$(run_diff_hash_range "$r" "base...HEAD")"
if [ "$cached_hash" = "$range_hash" ]; then
  ok=0
else
  ok=1
fi
check D6 CORRETO 0 "$ok" "--cached e --range base...HEAD batem no mesmo conteudo (PR de 1 commit)"

# D7: override valido domina a recomputacao do hash atual
r="$(new_repo main)"
override_hash="sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
printf 'x\n' > "$r/.engrama/memory/governance/p.md"
git -C "$r" add .engrama/memory/governance/p.md
write_ledger "$r" "## [2026-06-20] main | [governance] x | confirmo | ref $override_hash"
git -C "$r" add .engrama/evidence/qa/criticas-do-executor.md
check D7 CORRETO 0 "$(run_gate "$r" 1 "$override_hash")" "ENGRAMA_DIFF_HASH override e usado em vez de recomputar o hash local"

# D8: modo estrito libera quando o sha256 do ledger bate o override
r="$(new_repo main)"
override_hash="sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
printf 'x\n' > "$r/.engrama/memory/governance/p.md"
git -C "$r" add .engrama/memory/governance/p.md
write_ledger "$r" "## [2026-06-20] main | [governance] x | confirmo | ref $override_hash"
git -C "$r" add .engrama/evidence/qa/criticas-do-executor.md
check D8 CORRETO 0 "$(run_gate "$r" 1 "$override_hash")" "modo estrito libera quando o hash do ledger bate o override"

# D9: modo estrito bloqueia quando o sha256 do ledger NAO bate o override
r="$(new_repo main)"
printf 'x\n' > "$r/.engrama/memory/governance/p.md"
git -C "$r" add .engrama/memory/governance/p.md
write_ledger "$r" "## [2026-06-20] main | [governance] x | confirmo | ref sha256:cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"
git -C "$r" add .engrama/evidence/qa/criticas-do-executor.md
check D9 CORRETO 2 "$(run_gate "$r" 1 "sha256:dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd")" "modo estrito bloqueia quando o override diverge do sha256 registrado"

# D10: caminho default --cached segue bit-a-bit o pipeline legado
r="$(new_repo main)"
printf 'x\n' > "$r/.engrama/memory/governance/p.md"
git -C "$r" add .engrama/memory/governance/p.md
hash_default="$(run_diff_hash_cached "$r")"
hash_legacy="$(manual_legacy_hash "$r" cached)"
if [ "$hash_default" = "$hash_legacy" ]; then
  ok=0
else
  ok=1
fi
check D10 CORRETO 0 "$ok" "--cached preserva exatamente o fingerprint legado do critique-gate"

# D11: caminho default --range segue bit-a-bit o pipeline legado
r="$(new_repo main)"
git -C "$r" add .engrama/engine/scripts/critique-gate.sh .engrama/engine/scripts/engrama-diff-hash.sh .engrama/evidence/qa/criticas-do-executor.md
git -C "$r" commit -qm base
git -C "$r" branch base
git -C "$r" checkout -q -b pr/d11
printf 'x\n' > "$r/.engrama/memory/governance/p.md"
git -C "$r" add .engrama/memory/governance/p.md
git -C "$r" commit -qm pr
hash_default="$(run_diff_hash_range "$r" "base...HEAD")"
hash_legacy="$(manual_legacy_hash "$r" range "base...HEAD")"
if [ "$hash_default" = "$hash_legacy" ]; then
  ok=0
else
  ok=1
fi
check D11 CORRETO 0 "$ok" "--range preserva exatamente o fingerprint legado do critique-gate"

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: CORRETO = diff-binding verificado."
[ "$FAIL" -eq 0 ] || exit 1
