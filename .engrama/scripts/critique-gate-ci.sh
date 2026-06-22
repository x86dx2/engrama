#!/usr/bin/env bash
# Reexecuta o critique-gate local contra o diff real de um PR em CI.
#
# Honestidade: o wrapper calcula o fingerprint sobre o diff REAL do PR via
# engrama-diff-hash.sh --range "<base-ref>...HEAD". O repo sintetico segue
# existindo apenas para reusar classify() + parsing do ledger/staging do gate
# local sem duplicar logica.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/../.." && pwd)"
GATE_REL=".engrama/scripts/critique-gate.sh"
LEDGER_REL=".engrama/qa/criticas-do-executor.md"
DIFF_HASH_REL=".engrama/scripts/engrama-diff-hash.sh"
BRANCH=""
BASE_REF=""
FILES_FROM=""
TMPDIR_CI=""
PR_DIFF_HASH=""
declare -a CHANGED_FILES=()

usage() {
  cat <<'EOF'
Uso: bash .engrama/scripts/critique-gate-ci.sh --branch <nome-da-branch> --base-ref <gitish> --files-from <arquivo-nul>

Recebe a branch do PR, um gitish da base e um arquivo com a lista NUL-delimited
de paths mudados. Calcula o fingerprint do diff REAL do PR e reaplica o
critique-gate local num repo sintetico equivalente.
EOF
}

fail() {
  echo "critique-gate-ci: $*" >&2
  exit 2
}

cleanup() {
  rm -rf "${TMPDIR_CI:-}"
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --branch)
        shift
        [ "$#" -gt 0 ] || fail "faltou valor para --branch"
        BRANCH="$1"
        ;;
      --base-ref)
        shift
        [ "$#" -gt 0 ] || fail "faltou valor para --base-ref"
        BASE_REF="$1"
        ;;
      --files-from)
        shift
        [ "$#" -gt 0 ] || fail "faltou valor para --files-from"
        FILES_FROM="$1"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        fail "argumento desconhecido: $1"
        ;;
    esac
    shift
  done
}

need_file() {
  [ -f "$1" ] || fail "arquivo obrigatorio ausente: $1"
}

load_changed_files() {
  local path
  while IFS= read -r -d '' path; do
    CHANGED_FILES+=("$path")
  done < "$FILES_FROM"
}

compute_pr_diff_hash() {
  PR_DIFF_HASH="$(
    cd "$REPO_ROOT" &&
      bash "$REPO_ROOT/$DIFF_HASH_REL" --range "$BASE_REF...HEAD"
  )" || fail "nao consegui calcular o fingerprint do diff real do PR"

  [[ "$PR_DIFF_HASH" =~ ^sha256:[0-9a-f]{64}$ ]] || {
    fail "fingerprint invalido retornado por $DIFF_HASH_REL: ${PR_DIFF_HASH:-<vazio>}"
  }
}

ensure_parent_dir() {
  local rel="$1"
  mkdir -p "$(dirname "$TMPDIR_CI/$rel")"
}

path_exists_in_ref() {
  git cat-file -e "$BASE_REF:$1" 2>/dev/null
}

path_exists_in_worktree() {
  [ -e "$REPO_ROOT/$1" ] || [ -L "$REPO_ROOT/$1" ]
}

set_mode_from_ref() {
  local ref="$1" rel="$2" mode
  mode="$(git ls-tree "$ref" -- "$rel" | awk 'NR == 1 { print $1 }')"
  case "$mode" in
    100755) chmod 755 "$TMPDIR_CI/$rel" 2>/dev/null || true ;;
    100644|100664|120000) chmod 644 "$TMPDIR_CI/$rel" 2>/dev/null || true ;;
    *) : ;;
  esac
}

materialize_from_ref() {
  local rel="$1"
  ensure_parent_dir "$rel"
  git show "$BASE_REF:$rel" > "$TMPDIR_CI/$rel" || fail "nao consegui materializar $rel a partir de $BASE_REF"
  set_mode_from_ref "$BASE_REF" "$rel"
}

materialize_from_worktree() {
  local rel="$1"
  ensure_parent_dir "$rel"
  cp -p "$REPO_ROOT/$rel" "$TMPDIR_CI/$rel" || fail "nao consegui copiar $rel da worktree atual"
}

init_temp_repo() {
  TMPDIR_CI="$(mktemp -d 2>/dev/null || mktemp -d -t engrama-ci-gate)"
  trap cleanup EXIT HUP INT TERM

  git -C "$TMPDIR_CI" init -q -b "$BRANCH" 2>/dev/null || {
    git -C "$TMPDIR_CI" init -q
    git -C "$TMPDIR_CI" checkout -q -b "$BRANCH"
  }
  git -C "$TMPDIR_CI" config user.email ci@local
  git -C "$TMPDIR_CI" config user.name "CI Gate"
}

seed_base_snapshot() {
  local rel

  for rel in "$GATE_REL" "$LEDGER_REL" "$DIFF_HASH_REL"; do
    if path_exists_in_ref "$rel"; then
      materialize_from_ref "$rel"
    fi
  done

  for rel in "${CHANGED_FILES[@]}"; do
    if path_exists_in_ref "$rel"; then
      materialize_from_ref "$rel"
    fi
  done

  git -C "$TMPDIR_CI" add -A
  git -C "$TMPDIR_CI" commit -qm "base"
}

stage_head_snapshot() {
  local rel

  for rel in "${CHANGED_FILES[@]}"; do
    if path_exists_in_worktree "$rel"; then
      materialize_from_worktree "$rel"
      git -C "$TMPDIR_CI" add -- "$rel"
      continue
    fi

    if git -C "$TMPDIR_CI" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1; then
      rm -f "$TMPDIR_CI/$rel"
      git -C "$TMPDIR_CI" rm -q -- "$rel"
    fi
  done
}

run_gate() {
  (
    cd "$TMPDIR_CI" || exit 2
    ENGRAMA_DIFF_HASH="$PR_DIFF_HASH" bash "$GATE_REL"
  )
}

main() {
  parse_args "$@"

  [ -n "$BRANCH" ] || fail "branch do PR obrigatoria (--branch)"
  [ -n "$BASE_REF" ] || fail "base do PR obrigatoria (--base-ref)"
  [ -n "$FILES_FROM" ] || fail "arquivo com lista de arquivos obrigatorio (--files-from)"
  need_file "$REPO_ROOT/$GATE_REL"
  need_file "$REPO_ROOT/$DIFF_HASH_REL"
  need_file "$FILES_FROM"
  git rev-parse --verify "$BASE_REF" >/dev/null 2>&1 || fail "base-ref invalida: $BASE_REF"

  load_changed_files

  [ "${#CHANGED_FILES[@]}" -gt 0 ] || exit 0

  compute_pr_diff_hash
  init_temp_repo
  seed_base_snapshot
  stage_head_snapshot
  run_gate
}

main "$@"
