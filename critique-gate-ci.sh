#!/usr/bin/env bash
# Reexecuta o critique-gate local contra o diff de um PR em CI.
#
# Honestidade: o encanamento GitHub (base_ref/head_ref + env do workflow) e
# validado por revisao do workflow. O nucleo coberto por teste local e: dado
# (branch, lista NUL de arquivos), montar um repo sintetico e reaproveitar o
# gate local inalterado para classificar os paths e validar o ledger por campo.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
GATE_REL=".engrama/scripts/critique-gate.sh"
LEDGER_REL=".engrama/qa/criticas-do-executor.md"
SRC_GATE="$HERE/$GATE_REL"
SRC_LEDGER="$HERE/$LEDGER_REL"
BRANCH=""
FILES_FROM=""
TMPDIR_CI=""
declare -a CHANGED_FILES=()

usage() {
  cat <<'EOF'
Uso: bash critique-gate-ci.sh --branch <nome-da-branch> --files-from <arquivo-nul>

Recebe a branch do PR e um arquivo com a lista NUL-delimited de paths mudados.
Monta um repo sintetico e reusa o critique-gate local contra esse diff.
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

path_is_changed() {
  local needle="$1" path
  for path in "${CHANGED_FILES[@]}"; do
    [ "$path" = "$needle" ] && return 0
  done
  return 1
}

ensure_parent_dir() {
  local rel="$1"
  mkdir -p "$(dirname "$TMPDIR_CI/$rel")"
}

write_placeholder() {
  local rel="$1"
  ensure_parent_dir "$rel"
  printf '# synthetic path for critique-gate-ci\n' > "$TMPDIR_CI/$rel"
}

copy_actual_if_present() {
  local src="$1" rel="$2"
  ensure_parent_dir "$rel"
  if [ -f "$src" ]; then
    cp "$src" "$TMPDIR_CI/$rel"
  else
    : > "$TMPDIR_CI/$rel"
  fi
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

  if path_is_changed "$GATE_REL"; then
    write_placeholder "$GATE_REL"
  else
    copy_actual_if_present "$SRC_GATE" "$GATE_REL"
  fi

  if path_is_changed "$LEDGER_REL"; then
    write_placeholder "$LEDGER_REL"
  else
    copy_actual_if_present "$SRC_LEDGER" "$LEDGER_REL"
  fi

  git -C "$TMPDIR_CI" add -- "$GATE_REL" "$LEDGER_REL"
  git -C "$TMPDIR_CI" commit -qm "base"
}

stage_changed_paths() {
  local rel

  for rel in "${CHANGED_FILES[@]}"; do
    case "$rel" in
      "$GATE_REL")
        copy_actual_if_present "$SRC_GATE" "$GATE_REL"
        ;;
      "$LEDGER_REL")
        copy_actual_if_present "$SRC_LEDGER" "$LEDGER_REL"
        ;;
      *)
        write_placeholder "$rel"
        ;;
    esac
    git -C "$TMPDIR_CI" add -- "$rel"
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
  [ -n "$FILES_FROM" ] || fail "arquivo com lista de arquivos obrigatorio (--files-from)"
  need_file "$SRC_GATE"
  need_file "$FILES_FROM"

  load_changed_files

  [ "${#CHANGED_FILES[@]}" -gt 0 ] || exit 0

  init_temp_repo
  stage_changed_paths
  run_gate
}

main "$@"
