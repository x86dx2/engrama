#!/usr/bin/env bash
# Fuzz deterministico do parser/casamento do critique-gate.
# Gera cenarios pseudo-aleatorios e prova invariantes do gate por categoria/campo.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GATE_SRC="$REPO_ROOT/.engrama/engine/scripts/critique-gate.sh"
DIFF_HASH_SRC="$REPO_ROOT/.engrama/engine/scripts/engrama-diff-hash.sh"
[ -f "$GATE_SRC" ] || { echo "FATAL: gate nao encontrado em $GATE_SRC"; exit 1; }
[ -f "$DIFF_HASH_SRC" ] || { echo "FATAL: helper de hash nao encontrado em $DIFF_HASH_SRC"; exit 1; }

_probe="$(mktemp -d 2>/dev/null)" || { echo "FATAL: mktemp indisponivel — abortando"; exit 3; }
git -C "$_probe" init -q 2>/dev/null || { echo "FATAL: git init indisponivel — abortando"; rm -rf "$_probe"; exit 3; }
rm -rf "$_probe"

PASS=0; FAIL=0; HOLES=0; RESULTS=""
SEED=1729
RAND_VALUE=0
RAND_MOD=0
CASES=200

check() { # <id> <tag> <cond 0/1> <desc>
  local id="$1" tag="$2" ok="$3" desc="$4" mark
  if [ "$ok" -eq 0 ]; then mark="ok"; PASS=$((PASS + 1)); else mark="XX"; FAIL=$((FAIL + 1)); fi
  [ "$tag" = "FURO" ] && HOLES=$((HOLES + 1))
  RESULTS="$RESULTS\n  [$mark] $id  ($tag)  | $desc"
}

next_rand() {
  SEED=$(( (SEED * 1103515245 + 12345) % 2147483648 ))
  RAND_VALUE="$SEED"
}

rand_mod() {
  local n="$1"
  next_rand
  RAND_MOD=$(((RAND_VALUE / 65536) % n))
}

pick_from() {
  local idx="$1"
  shift
  eval "printf '%s' \"\${$((idx + 1))}\""
}

new_repo() {
  local branch="$1" d
  d="$(mktemp -d 2>/dev/null || mktemp -d -t engrama-gate-fuzz)"
  git -C "$d" init -q -b "$branch" 2>/dev/null || { git -C "$d" init -q; git -C "$d" checkout -q -b "$branch"; }
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  mkdir -p "$d/.engrama/engine/scripts" "$d/.engrama/evidence/qa" "$d/.engrama/memory/governance" "$d/tests/contract"
  cp "$GATE_SRC" "$d/.engrama/engine/scripts/critique-gate.sh"
  cp "$DIFF_HASH_SRC" "$d/.engrama/engine/scripts/engrama-diff-hash.sh"
  printf '# ledger\n' > "$d/.engrama/evidence/qa/criticas-do-executor.md"
  git -C "$d" add .engrama/engine/scripts/critique-gate.sh .engrama/evidence/qa/criticas-do-executor.md
  git -C "$d" commit -qm base
  printf '%s' "$d"
}

write_ledger() {
  printf '%s' "$2" > "$1/.engrama/evidence/qa/criticas-do-executor.md"
}

stage_changed_files() {
  local repo="$1" cats="$2"
  if printf '%s\n' "$cats" | grep -q ' governance '; then
    printf 'x\n' > "$repo/.engrama/memory/governance/p.md"
    git -C "$repo" add .engrama/memory/governance/p.md
  fi
  if printf '%s\n' "$cats" | grep -q ' gate '; then
    printf '#!/usr/bin/env bash\n' > "$repo/.engrama/engine/scripts/lint.sh"
    git -C "$repo" add .engrama/engine/scripts/lint.sh
  fi
  if printf '%s\n' "$cats" | grep -q ' contract '; then
    printf '#!/usr/bin/env bash\n' > "$repo/tests/contract/p.test.sh"
    git -C "$repo" add tests/contract/p.test.sh
  fi
  if [ "$cats" = " " ]; then
    printf 'x\n' > "$repo/README-do-produto.txt"
    git -C "$repo" add README-do-produto.txt
  fi
}

run_gate() {
  (
    cd "$1" || exit 2
    bash .engrama/engine/scripts/critique-gate.sh >/dev/null 2>&1
    echo $?
  )
}

verdict_is_ok() {
  local verdict_lc
  verdict_lc="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$verdict_lc" in
    confirmo|confirmo-bug|ressalvas|dispensada|n/a:*|waiver*) return 0 ;;
    *) return 1 ;;
  esac
}

verdict_is_blocking() {
  local verdict_lc
  verdict_lc="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$verdict_lc" in
    *waiver*) return 1 ;;
  esac
  case "$verdict_lc" in
    objec*|objeç*|discordo*) return 0 ;;
    *) return 1 ;;
  esac
}

entry_has_cat() {
  local tags="$1" cat="$2"
  case "$tags" in
    *"[$cat]"*) return 0 ;;
    *) return 1 ;;
  esac
}

expected_exit_for_cat() {
  local branch="$1" cat="$2" ledger="$3" ok=1 blocked=1 line field1 field2 field3 field4 entry_branch
  ok=1
  blocked=1
  while IFS= read -r line; do
    case "$line" in
      '## ['*)
        IFS='|' read -r field1 field2 field3 field4 _rest <<EOF
$line
EOF
        field1="$(trim_field "$field1")"
        field2="$(trim_field "$field2")"
        field3="$(trim_field "$field3")"
        field4="$(trim_field "$field4")"
        [ -n "$field4" ] || continue
        entry_branch="${field1#*] }"
        [ "$entry_branch" = "$branch" ] || continue
        entry_has_cat "$field2" "$cat" || continue
        if verdict_is_ok "$field3"; then
          ok=0
        fi
        if verdict_is_blocking "$field3"; then
          blocked=0
        fi
        ;;
      *)
        ;;
    esac
  done <<EOF
$ledger
EOF

  if [ "$blocked" -eq 0 ]; then
    return 2
  fi

  if [ "$ok" -eq 0 ]; then
    return 0
  fi

  return 2
}

trim_field() {
  local s="${1-}"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

expected_exit() {
  local branch="$1" cats="$2" ledger="$3" cat
  for cat in governance gate contract; do
    if ! printf '%s\n' "$cats" | grep -q " $cat "; then
      continue
    fi
    expected_exit_for_cat "$branch" "$cat" "$ledger"
    case "$?" in
      0) ;;
      2) return 2 ;;
      *) return 2 ;;
    esac
  done
  return 0
}

build_entry() {
  local branch_field="$1" tags="$2" verdict="$3" ref="$4" text="$5"
  printf '## [2026-06-20] %s | %s %s | %s | %s\n' "$branch_field" "$tags" "$text" "$verdict" "$ref"
}

case_no=1
while [ "$case_no" -le "$CASES" ]; do
  branch="slice/$case_no"
  repo="$(new_repo "$branch")"
  cats=" "
  ledger="# fuzz ledger"$'\n'

  rand_mod 2
  if [ "$RAND_MOD" -eq 0 ]; then cats="$cats governance "; fi
  rand_mod 2
  if [ "$RAND_MOD" -eq 0 ]; then cats="$cats gate "; fi
  rand_mod 2
  if [ "$RAND_MOD" -eq 0 ]; then cats="$cats contract "; fi
  rand_mod 6
  entries="$RAND_MOD"
  idx=0
  while [ "$idx" -lt "$entries" ]; do
    rand_mod 4
    branch_pick="$RAND_MOD"
    case "$branch_pick" in
      0) entry_branch="$branch" ;;
      1) entry_branch="slice/$((case_no + 1000))" ;;
      2) entry_branch="main" ;;
      *) entry_branch="topic/$case_no" ;;
    esac

    rand_mod 8
    tag_mask="$RAND_MOD"
    tags=""
    [ $((tag_mask & 1)) -ne 0 ] && tags="${tags}[governance]"
    [ $((tag_mask & 2)) -ne 0 ] && tags="${tags}[gate]"
    [ $((tag_mask & 4)) -ne 0 ] && tags="${tags}[contract]"
    [ -n "$tags" ] || tags="[governance]"

    rand_mod 10
    verdict_idx="$RAND_MOD"
    verdict="$(pick_from "$verdict_idx" \
      "confirmo" \
      "ressalvas" \
      "dispensada" \
      "N/A: fora de escopo" \
      "waiver autoridade" \
      "discordo: risco material" \
      "objecao: bloqueia sem waiver" \
      "nao confirmo" \
      "pendente" \
      "confirmo-bug")"

    text_branch=""
    rand_mod 3
    if [ "$RAND_MOD" -eq 0 ]; then
      text_branch="menciona a branch $branch no texto livre"
    else
      text_branch="texto livre $idx"
    fi

    ledger="${ledger}$(build_entry "$entry_branch" "$tags" "$verdict" "ref-$case_no-$idx" "$text_branch")"
    idx=$((idx + 1))
  done

  write_ledger "$repo" "$ledger"
  git -C "$repo" add .engrama/evidence/qa/criticas-do-executor.md
  git -C "$repo" commit -qm "ledger-$case_no"
  stage_changed_files "$repo" "$cats"

  expected_exit "$branch" "$cats" "$ledger"
  exp="$?"
  got="$(run_gate "$repo")"

  if [ "$exp" -eq "$got" ]; then
    ok=0
  else
    ok=1
  fi

  check "F$(printf '%03d' "$case_no")" CORRETO "$ok" "branch exata + campo 3 governam a liberacao (cats:${cats})"
  case_no=$((case_no + 1))
done

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: CORRETO = invariante preservada pelo gate."
[ "$FAIL" -eq 0 ] || exit 1
