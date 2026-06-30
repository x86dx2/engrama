#!/usr/bin/env bash
# Thin Codex adapter for the Engrama executor bridge.
set -u

MODEL=""
EFFORT=""
SANDBOX=""
PROMPT_FILE=""
EVENTS_FILE=""
STDERR_FILE=""
CODEX_BIN="${ENGRAMA_CODEX_BIN:-codex}"
declare -a EXTRA_ARGS=()

usage() {
  cat <<'EOF'
Uso:
  codex.sh --model <model> --effort <effort> --sandbox <mode> --prompt-file <file> --events-file <file> --stderr-file <file> [-- <extra codex args>]
EOF
}

fail() {
  echo "codex-adapter: $*" >&2
  exit 2
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --model)
        shift
        [ "$#" -gt 0 ] || fail "faltou valor para --model"
        MODEL="$1"
        ;;
      --effort)
        shift
        [ "$#" -gt 0 ] || fail "faltou valor para --effort"
        EFFORT="$1"
        ;;
      --sandbox)
        shift
        [ "$#" -gt 0 ] || fail "faltou valor para --sandbox"
        SANDBOX="$1"
        ;;
      --prompt-file)
        shift
        [ "$#" -gt 0 ] || fail "faltou valor para --prompt-file"
        PROMPT_FILE="$1"
        ;;
      --events-file)
        shift
        [ "$#" -gt 0 ] || fail "faltou valor para --events-file"
        EVENTS_FILE="$1"
        ;;
      --stderr-file)
        shift
        [ "$#" -gt 0 ] || fail "faltou valor para --stderr-file"
        STDERR_FILE="$1"
        ;;
      --)
        shift
        EXTRA_ARGS=("$@")
        break
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

reject_conflicting_args() {
  local idx=0 arg next
  while [ "$idx" -lt "${#EXTRA_ARGS[@]}" ]; do
    arg="${EXTRA_ARGS[$idx]}"
    case "$arg" in
      -m|--model|--model=*)
        fail "modelo deve vir do model-router; remova o arg extra '$arg'"
        ;;
      -c|--config)
        next="${EXTRA_ARGS[$((idx + 1))]:-}"
        case "$next" in
          model=*|model_reasoning_effort=*)
            fail "model/effort devem vir do model-router; remova '-c $next'"
            ;;
        esac
        idx=$((idx + 1))
        ;;
      -cmodel=*|-cmodel_reasoning_effort=*|--config=model=*|--config=model_reasoning_effort=*)
        fail "model/effort devem vir do model-router; remova '$arg'"
        ;;
    esac
    idx=$((idx + 1))
  done
}

main() {
  local -a cmd

  parse_args "$@"
  [ -n "$MODEL" ] || fail "faltou --model"
  [ -n "$EFFORT" ] || fail "faltou --effort"
  [ -n "$SANDBOX" ] || fail "faltou --sandbox"
  [ -f "$PROMPT_FILE" ] || fail "prompt-file ausente: $PROMPT_FILE"
  [ -n "$EVENTS_FILE" ] || fail "faltou --events-file"
  [ -n "$STDERR_FILE" ] || fail "faltou --stderr-file"
  command -v "$CODEX_BIN" >/dev/null 2>&1 || fail "codex bin nao encontrado: $CODEX_BIN"
  reject_conflicting_args

  cmd=("$CODEX_BIN" exec --json -s "$SANDBOX" -m "$MODEL" -c "model_reasoning_effort=$EFFORT")
  if [ "${#EXTRA_ARGS[@]}" -gt 0 ]; then
    cmd+=("${EXTRA_ARGS[@]}")
  fi
  cmd+=(-)

  "${cmd[@]}" < "$PROMPT_FILE" > "$EVENTS_FILE" 2> "$STDERR_FILE"
}

main "$@"
