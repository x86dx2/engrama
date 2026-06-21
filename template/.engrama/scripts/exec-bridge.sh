#!/usr/bin/env bash
# exec-bridge.sh -- invoca codex exec e preserva ordem/resposta em transcripts/.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(git -C "$HERE/.." rev-parse --show-toplevel 2>/dev/null || true)"
TRANSCRIPTS_DIR=""
ORDER_FILE=""
LABEL=""
RUN_DATE=""
SANDBOX="read-only"
CODEX_BIN="${ENGRAMA_CODEX_BIN:-codex}"
TMPDIR_BRIDGE=""
declare -a CODEX_EXTRA_ARGS=()

usage() {
  cat <<'EOF'
Uso:
  bash .engrama/scripts/exec-bridge.sh --order <arquivo> --label <slug> [--sandbox <read-only|workspace-write>] [--date <YYYY-MM-DD>] [-- <flags extras do codex>]

Exemplo:
  bash .engrama/scripts/exec-bridge.sh --order /tmp/ordem.md --label fatia-01 --sandbox workspace-write -- --model gpt-5.4
EOF
}

fail() {
  echo "exec-bridge: $*" >&2
  exit 2
}

cleanup() {
  rm -rf "${TMPDIR_BRIDGE:-}"
}

is_valid_date() {
  [[ "${1:-}" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --order)
        shift
        [ "$#" -gt 0 ] || fail "faltou valor para --order"
        ORDER_FILE="$1"
        ;;
      --label)
        shift
        [ "$#" -gt 0 ] || fail "faltou valor para --label"
        LABEL="$1"
        ;;
      --sandbox)
        shift
        [ "$#" -gt 0 ] || fail "faltou valor para --sandbox"
        SANDBOX="$1"
        ;;
      --date)
        shift
        [ "$#" -gt 0 ] || fail "faltou valor para --date"
        RUN_DATE="$1"
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      --)
        shift
        CODEX_EXTRA_ARGS=("$@")
        break
        ;;
      *)
        CODEX_EXTRA_ARGS+=("$1")
        ;;
    esac
    shift
  done
}

resolve_date() {
  if [ -n "$RUN_DATE" ]; then
    is_valid_date "$RUN_DATE" || fail "data invalida para --date: $RUN_DATE"
    return
  fi

  RUN_DATE="$(git -C "$REPO_ROOT" log -1 --format=%cs 2>/dev/null || true)"
  if is_valid_date "$RUN_DATE"; then
    return
  fi

  RUN_DATE="$(date +%F 2>/dev/null || true)"
  is_valid_date "$RUN_DATE" || fail "nao consegui determinar a data do transcript"
}

validate_inputs() {
  [ -n "$REPO_ROOT" ] || fail "execute dentro de um repo git"
  [ -n "$ORDER_FILE" ] || fail "faltou --order"
  [ -f "$ORDER_FILE" ] || fail "arquivo de ordem nao encontrado: $ORDER_FILE"
  [ -n "$LABEL" ] || fail "faltou --label"

  case "$LABEL" in
    *[!A-Za-z0-9._-]*)
      fail "label invalido: use apenas letras, numeros, ponto, underscore ou hifen"
      ;;
    *)
      ;;
  esac

  case "$SANDBOX" in
    read-only|workspace-write)
      ;;
    *)
      fail "sandbox invalido: $SANDBOX (use read-only ou workspace-write)"
      ;;
  esac

  command -v "$CODEX_BIN" >/dev/null 2>&1 || fail "codex bin nao encontrado: $CODEX_BIN"
  command -v jq >/dev/null 2>&1 || fail "jq obrigatorio para parsear o stream --json"
}

extract_session_id() {
  local events_file="$1"
  jq -Rr '
    fromjson? |
    if (.type == "session_meta" and (.payload.id? // "") != "") then
      .payload.id
    elif (.payload.session_id? // "") != "" then
      .payload.session_id
    elif (.session_id? // "") != "" then
      .session_id
    elif (.payload.thread_id? // "") != "" then
      .payload.thread_id
    elif (.thread_id? // "") != "" then
      .thread_id
    elif (.payload.conversation_id? // "") != "" then
      .payload.conversation_id
    elif (.conversation_id? // "") != "" then
      .conversation_id
    else
      empty
    end
  ' "$events_file" | sed -n '1p'
}

extract_model_from_stream() {
  local events_file="$1"
  jq -Rr '
    fromjson? |
    if (.type == "turn_context" and (.payload.model? // "") != "") then
      .payload.model
    elif (.payload.model? // "") != "" then
      .payload.model
    elif (.model? // "") != "" then
      .model
    else
      empty
    end
  ' "$events_file" | sed -n '1p'
}

extract_model_from_args() {
  local idx=0
  local arg=""

  while [ "$idx" -lt "${#CODEX_EXTRA_ARGS[@]}" ]; do
    arg="${CODEX_EXTRA_ARGS[$idx]}"
    case "$arg" in
      --model=*)
        printf '%s\n' "${arg#--model=}"
        return 0
        ;;
      --model|-m)
        idx=$((idx + 1))
        if [ "$idx" -lt "${#CODEX_EXTRA_ARGS[@]}" ]; then
          printf '%s\n' "${CODEX_EXTRA_ARGS[$idx]}"
          return 0
        fi
        ;;
      *)
        ;;
    esac
    idx=$((idx + 1))
  done

  return 1
}

extract_response_text() {
  local events_file="$1"
  jq -Rr '
    fromjson? |
    select(.type == "response_item" and .payload.type == "message" and .payload.role == "assistant") |
    .payload.content[]? |
    select(.type == "output_text") |
    .text, ""
  ' "$events_file"
}

# Fallback: o stdout --json do codex nem sempre carrega o output_text final do
# assistant; o session file (~/.codex/sessions/.../<id>.jsonl) sempre carrega.
find_session_file() {
  local sid="$1"
  local home="${CODEX_HOME:-$HOME/.codex}"
  [ -n "$sid" ] || return 1
  find "$home/sessions" -type f -name "*${sid}*.jsonl" 2>/dev/null | sort | tail -1
}

extract_response_from_session() {
  local sf="$1"
  [ -f "$sf" ] || return 1
  jq -Rr '
    fromjson? |
    select((.payload.type? == "message") and (.payload.role? == "assistant")) |
    .payload.content[]? |
    select(.type == "output_text") |
    .text
  ' "$sf"
}

sha256_short() {
  local input="$1"

  if command -v shasum >/dev/null 2>&1; then
    printf '%s' "$input" | shasum -a 256 | awk '{print substr($1, 1, 16)}'
    return
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    printf '%s' "$input" | sha256sum | awk '{print substr($1, 1, 16)}'
    return
  fi

  if command -v openssl >/dev/null 2>&1; then
    printf '%s' "$input" | openssl dgst -sha256 -r | awk '{print substr($1, 1, 16)}'
    return
  fi

  fail "nao encontrei shasum, sha256sum ou openssl para derivar o codex-session"
}

main() {
  local order_rel=""
  local order_path=""
  local response_rel=""
  local response_path=""
  local events_file=""
  local stderr_file=""
  local response_text=""
  local codex_rc=0
  local codex_session=""
  local codex_session_source="stream"
  local model=""
  local -a codex_cmd=()

  parse_args "$@"
  validate_inputs
  resolve_date

  TRANSCRIPTS_DIR="$REPO_ROOT/transcripts"
  order_rel="transcripts/${RUN_DATE}-${LABEL}-order.md"
  order_path="$REPO_ROOT/$order_rel"
  response_rel="transcripts/${RUN_DATE}-${LABEL}-response.md"
  response_path="$REPO_ROOT/$response_rel"

  [ ! -e "$order_path" ] || fail "transcript ja existe: $order_rel"
  [ ! -e "$response_path" ] || fail "transcript ja existe: $response_rel"

  mkdir -p "$TRANSCRIPTS_DIR"
  cp "$ORDER_FILE" "$order_path"

  TMPDIR_BRIDGE="$(mktemp -d 2>/dev/null || mktemp -d -t engrama-exec-bridge)"
  trap cleanup EXIT HUP INT TERM
  events_file="$TMPDIR_BRIDGE/codex-events.jsonl"
  stderr_file="$TMPDIR_BRIDGE/codex-stderr.log"

  codex_cmd=("$CODEX_BIN" exec --json -s "$SANDBOX")
  if [ "${#CODEX_EXTRA_ARGS[@]}" -gt 0 ]; then
    codex_cmd+=("${CODEX_EXTRA_ARGS[@]}")
  fi
  codex_cmd+=(-)

  if "${codex_cmd[@]}" < "$ORDER_FILE" > "$events_file" 2> "$stderr_file"; then
    codex_rc=0
  else
    codex_rc=$?
  fi

  codex_session="$(extract_session_id "$events_file")"

  response_text="$(extract_response_text "$events_file")"
  # Fallback robusto: se o stream nao trouxe a resposta, le do session file.
  if [ -z "$response_text" ] && [ -n "$codex_session" ]; then
    session_file="$(find_session_file "$codex_session" 2>/dev/null || true)"
    if [ -n "$session_file" ]; then
      response_text="$(extract_response_from_session "$session_file" 2>/dev/null || true)"
    fi
  fi
  if [ -z "$response_text" ] && [ -s "$stderr_file" ]; then
    response_text="(sem output_text do assistant)

$(cat "$stderr_file")"
  fi

  if [ -z "$codex_session" ]; then
    codex_session_source="derived"
    codex_session="$(sha256_short "$response_text")"
  fi

  model="$(extract_model_from_stream "$events_file")"
  if [ -z "$model" ]; then
    model="$(extract_model_from_args 2>/dev/null || true)"
  fi
  [ -n "$model" ] || model="unknown"

  {
    printf '%s\n' '---'
    printf 'codex-session: %s\n' "$codex_session"
    printf 'codex-session-source: %s\n' "$codex_session_source"
    printf 'model: %s\n' "$model"
    printf 'sandbox: %s\n' "$SANDBOX"
    printf 'label: %s\n' "$LABEL"
    printf '%s\n\n' '---'
    printf '%s' "$response_text"
    printf '\n'
  } > "$response_path"

  printf '%s\n' "$order_rel"
  printf '%s\n' "$response_rel"
  printf 'codex-session:%s\n' "$codex_session"

  if [ "$codex_rc" -ne 0 ]; then
    echo "exec-bridge: codex exec falhou com exit $codex_rc" >&2
    exit "$codex_rc"
  fi
}

main "$@"
