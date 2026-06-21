#!/usr/bin/env bash
# Reexecuta o critique-gate local contra o diff real de um PR em CI.
#
# Honestidade: o wrapper nao inventa o fingerprint. Ele reconstrui um repo
# sintetico com a base real (`--base-ref`) e os arquivos atuais do PR para que
# o proprio critique-gate local rode sobre um diff equivalente e chame a mesma
# fonte unica de hash (engrama-diff-hash.sh).
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
GATE_REL=".engrama/scripts/critique-gate.sh"
LEDGER_REL=".engrama/qa/criticas-do-executor.md"
DIFF_HASH_REL="engrama-diff-hash.sh"
BRANCH=""
BASE_REF=""
FILES_FROM=""
TMPDIR_CI=""
declare -a CHANGED_FILES=()

usage() {
  cat <<'EOF'
Uso: bash critique-gate-ci.sh --branch <nome-da-branch> --base-ref <gitish> --files-from <arquivo-nul>

Recebe a branch do PR, um gitish da base e um arquivo com a lista NUL-delimited
de paths mudados. Monta um repo sintetico com a base real e reaplica o
critique-gate local contra esse diff.
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

ensure_parent_dir() {
  local rel="$1"
  mkdir -p "$(dirname "$TMPDIR_CI/$rel")"
}

path_exists_in_ref() {
  git cat-file -e "$BASE_REF:$1" 2>/dev/null
}

path_exists_in_worktree() {
  [ -e "$HERE/$1" ] || [ -L "$HERE/$1" ]
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
  cp -p "$HERE/$rel" "$TMPDIR_CI/$rel" || fail "nao consegui copiar $rel da worktree atual"
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
    bash "$GATE_REL"
  )
}

main() {
  parse_args "$@"

  [ -n "$BRANCH" ] || fail "branch do PR obrigatoria (--branch)"
  [ -n "$BASE_REF" ] || fail "base do PR obrigatoria (--base-ref)"
  [ -n "$FILES_FROM" ] || fail "arquivo com lista de arquivos obrigatorio (--files-from)"
  need_file "$HERE/$GATE_REL"
  need_file "$HERE/$DIFF_HASH_REL"
  need_file "$FILES_FROM"
  git rev-parse --verify "$BASE_REF" >/dev/null 2>&1 || fail "base-ref invalida: $BASE_REF"

  load_changed_files

  [ "${#CHANGED_FILES[@]}" -gt 0 ] || exit 0

  init_temp_repo
  seed_base_snapshot
  stage_head_snapshot
  run_gate
}

main "$@"
