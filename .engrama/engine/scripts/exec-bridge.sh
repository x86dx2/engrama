#!/usr/bin/env bash
# exec-bridge.sh -- invoca codex exec e preserva ordem/resposta em .engrama/evidence/transcripts/.
set -u

BRIDGE_STABLE_COPY=""
SCRIPT_PATH="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"

cleanup_stable_copy() {
  rm -f "${BRIDGE_STABLE_COPY:-}"
}

# Blindagem contra ambiente contaminado: so honramos o modo reexec quando o
# processo atual e a copia estavel explicitamente apontada por ENGRAMA_BRIDGE_SELF.
if [ -n "${ENGRAMA_BRIDGE_REEXEC:-}" ] && [ "${ENGRAMA_BRIDGE_SELF:-}" != "$SCRIPT_PATH" ]; then
  unset ENGRAMA_BRIDGE_REEXEC ENGRAMA_BRIDGE_HERE ENGRAMA_BRIDGE_SELF
fi

if [ -z "${ENGRAMA_BRIDGE_REEXEC:-}" ]; then
  __orig_here="$(cd "$(dirname "$0")" && pwd)"
  __orig_script="$__orig_here/$(basename "$0")"
  BRIDGE_STABLE_COPY="$(mktemp 2>/dev/null || mktemp -t exec-bridge)" || { echo "exec-bridge: mktemp falhou" >&2; exit 2; }
  trap cleanup_stable_copy EXIT HUP INT TERM
  cat "$__orig_script" > "$BRIDGE_STABLE_COPY" || { echo "exec-bridge: copia falhou" >&2; exit 2; }
  ENGRAMA_BRIDGE_REEXEC=1 ENGRAMA_BRIDGE_HERE="$__orig_here" ENGRAMA_BRIDGE_SELF="$BRIDGE_STABLE_COPY" bash "$BRIDGE_STABLE_COPY" "$@"
  __rc=$?
  exit "$__rc"
fi

HERE="${ENGRAMA_BRIDGE_HERE:-$(cd "$(dirname "$0")" && pwd)}"
REPO_ROOT="$(git -C "$HERE/../../.." rev-parse --show-toplevel 2>/dev/null || true)"
TRANSCRIPTS_DIR=""
USAGE_DIR=""
ORDER_FILE=""
INLINE_ORDER=""
LABEL=""
RUN_DATE=""
SANDBOX="read-only"
ROLE=""
TIER=""
ROUTING_MODE=""
ADAPTER=""
PROVIDER=""
MODEL=""
EFFORT=""
NO_FALLBACK=""
ROUTING_REASON=""
TMPDIR_BRIDGE=""
declare -a CODEX_EXTRA_ARGS=()

usage() {
  cat <<'EOF'
Uso:
  bash .engrama/engine/scripts/exec-bridge.sh --role <role> --tier <tier> --order <arquivo> [--label <slug>] [--sandbox <read-only|workspace-write>] [--date <YYYY-MM-DD>] [-- <flags extras do adapter>]
  bash .engrama/engine/scripts/exec-bridge.sh --role critique --tier T4 --sandbox read-only -- "prompt inline"

Exemplo:
  bash .engrama/engine/scripts/exec-bridge.sh --role execute --tier T2 --order /tmp/ordem.md --label fatia-01 --sandbox workspace-write

Se --role/--tier forem omitidos, o bridge usa execute/T2 e registra routing_mode=default.
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
      --role)
        shift
        [ "$#" -gt 0 ] || fail "faltou valor para --role"
        ROLE="$1"
        ;;
      --tier)
        shift
        [ "$#" -gt 0 ] || fail "faltou valor para --tier"
        TIER="$1"
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
        if [ -z "$ORDER_FILE" ] && [ "$#" -eq 1 ]; then
          INLINE_ORDER="$1"
        else
          CODEX_EXTRA_ARGS=("$@")
        fi
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

ensure_tmpdir() {
  if [ -z "$TMPDIR_BRIDGE" ]; then
    TMPDIR_BRIDGE="$(mktemp -d 2>/dev/null || mktemp -d -t engrama-exec-bridge)"
    trap cleanup EXIT HUP INT TERM
  fi
}

prepare_inline_order() {
  [ -n "$INLINE_ORDER" ] || return 0
  ensure_tmpdir
  ORDER_FILE="$TMPDIR_BRIDGE/inline-order.md"
  printf '%s\n' "$INLINE_ORDER" > "$ORDER_FILE"
}

normalize_routing() {
  if [ -z "$ROLE" ] && [ -z "$TIER" ]; then
    ROLE="execute"
    TIER="T2"
    ROUTING_MODE="default"
    return
  fi

  if [ -n "$ROLE" ] && [ -n "$TIER" ]; then
    ROUTING_MODE="explicit"
    return
  fi

  fail "--role e --tier devem ser informados juntos"
}

resolve_route() {
  local router="$REPO_ROOT/.engrama/engine/scripts/model-router.sh"
  local route_output=""
  [ -f "$router" ] || fail "model-router ausente: $router"
  route_output="$(bash "$router" --role "$ROLE" --tier "$TIER")" || fail "model-router falhou para role=$ROLE tier=$TIER"
  eval "$route_output"
}

sanitize_label_part() {
  printf '%s' "$1" | tr '+[:upper:]' 'p[:lower:]' | sed 's/[^a-z0-9._-]/-/g'
}

default_label_if_needed() {
  local stamp tier_part
  [ -z "$LABEL" ] || return 0
  stamp="$(date -u +%H%M%S 2>/dev/null || date +%H%M%S)"
  tier_part="$(sanitize_label_part "$TIER")"
  LABEL="$(sanitize_label_part "$ROLE")-${tier_part}-${stamp}-$$"
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

extract_usage_number() {
  local events_file="$1" field="$2"
  jq -Rr --arg field "$field" '
    fromjson? |
    (.usage? // .payload.usage? // {}) |
    .[$field]? // empty
  ' "$events_file" | awk '
    /^[0-9]+$/ { sum += $1; found = 1 }
    END { if (found) print sum }
  '
}

extract_cached_input_tokens() {
  local events_file="$1"
  jq -Rr '
    fromjson? |
    (.usage? // .payload.usage? // {}) as $u |
    ($u.cached_input_tokens? // $u.input_tokens_details.cached_tokens? // empty)
  ' "$events_file" | awk '
    /^[0-9]+$/ { sum += $1; found = 1 }
    END { if (found) print sum }
  '
}

extract_turns() {
  local events_file="$1" turns
  turns="$(jq -Rr 'fromjson? | select(.type == "turn.completed") | "1"' "$events_file" | wc -l | tr -d ' ')"
  if [ "${turns:-0}" -eq 0 ]; then
    turns=1
  fi
  printf '%s\n' "$turns"
}

extract_response_text() {
  local events_file="$1"
  # Suporta dois schemas do `codex exec --json`:
  #  - antigo: response_item/message/assistant + content[].output_text
  #  - novo (codex-cli >= 0.142.0): item.completed com item.type == agent_message + item.text
  # O item.completed do tipo "error" (ex.: warning de plugin) NAO e a resposta -> excluido.
  jq -Rr '
    fromjson? |
    if (.type == "response_item" and .payload.type == "message" and .payload.role == "assistant") then
      (.payload.content[]? | select(.type == "output_text") | .text)
    elif (.type == "item.completed" and (.item.type? == "agent_message")) then
      .item.text
    else
      empty
    end
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

json_string() {
  jq -Rn --arg v "$1" '$v'
}

json_number_or_null() {
  local value="${1:-}"
  if [ -n "$value" ] && printf '%s\n' "$value" | grep -Eq '^-?[0-9]+([.][0-9]+)?$'; then
    printf '%s' "$value"
  else
    printf 'null'
  fi
}

json_bool() {
  if [ "${1:-0}" = "1" ] || [ "${1:-}" = "true" ]; then
    printf 'true'
  else
    printf 'false'
  fi
}

price_key_for() {
  local provider="$1" model="$2"
  printf '%s_%s' "$provider" "$model" |
    sed 's/[^A-Za-z0-9]/_/g' |
    tr '[:lower:]' '[:upper:]' |
    sed 's/_\{2,\}/_/g; s/^_//; s/_$//'
}

resolve_billing_plan() {
  local subscriptions_conf="$REPO_ROOT/.engrama/engine/config/subscriptions.conf"
  BILLING_MODE="unknown"
  BILLING_PLAN="unknown"

  [ -f "$subscriptions_conf" ] || return 0
  # shellcheck disable=SC1090
  . "$subscriptions_conf"

  if [ "${ENGRAMA_CODEX_PRO_ENABLED:-0}" = "1" ] \
    && [ "$PROVIDER" = "${ENGRAMA_CODEX_PRO_PROVIDER:-}" ]; then
    # shellcheck disable=SC2254 # model pattern is intentionally a glob from subscriptions.conf.
    case "$MODEL" in
      ${ENGRAMA_CODEX_PRO_MODEL_PATTERN:-__never_match__})
        BILLING_MODE="subscription"
        BILLING_PLAN="codex-pro"
        return 0
        ;;
    esac
  fi

  if [ "${ENGRAMA_CLAUDE_MAX_ENABLED:-0}" = "1" ] \
    && [ "$PROVIDER" = "${ENGRAMA_CLAUDE_MAX_PROVIDER:-}" ]; then
    # shellcheck disable=SC2254 # model pattern is intentionally a glob from subscriptions.conf.
    case "$MODEL" in
      ${ENGRAMA_CLAUDE_MAX_MODEL_PATTERN:-__never_match__})
        BILLING_MODE="subscription"
        BILLING_PLAN="claude-max"
        return 0
        ;;
    esac
  fi
}

estimate_api_cost() {
  local input_tokens="${1:-}" output_tokens="${2:-}" prices_conf key in_var out_var in_price out_price
  ESTIMATED_API_COST_USD=""
  [ -n "$input_tokens" ] || return 0
  [ -n "$output_tokens" ] || return 0

  prices_conf="$REPO_ROOT/.engrama/engine/config/prices.conf"
  [ -f "$prices_conf" ] || return 0
  # shellcheck disable=SC1090
  . "$prices_conf"

  key="$(price_key_for "$PROVIDER" "$MODEL")"
  in_var="ENGRAMA_PRICE_${key}_INPUT_PER_1M_USD"
  out_var="ENGRAMA_PRICE_${key}_OUTPUT_PER_1M_USD"
  in_price="${!in_var-}"
  out_price="${!out_var-}"
  [ -n "$in_price" ] || return 0
  [ -n "$out_price" ] || return 0

  ESTIMATED_API_COST_USD="$(awk -v i="$input_tokens" -v o="$output_tokens" -v ip="$in_price" -v op="$out_price" 'BEGIN { printf "%.8f", (i / 1000000 * ip) + (o / 1000000 * op) }')"
}

append_usage_ledger() {
  local started_at="$1" finished_at="$2" started_epoch="$3" finished_epoch="$4"
  local response_rel="$5" codex_session="$6" codex_rc="$7" events_file="$8"
  local usage_month usage_file run_stamp run_id project branch duration_seconds
  local input_tokens output_tokens cached_input_tokens total_tokens turns success
  local billing_mode plan estimated_cost

  input_tokens="$(extract_usage_number "$events_file" input_tokens)"
  output_tokens="$(extract_usage_number "$events_file" output_tokens)"
  cached_input_tokens="$(extract_cached_input_tokens "$events_file")"
  total_tokens="$(extract_usage_number "$events_file" total_tokens)"
  if [ -z "$total_tokens" ] && [ -n "$input_tokens" ] && [ -n "$output_tokens" ]; then
    total_tokens="$((input_tokens + output_tokens))"
  fi
  turns="$(extract_turns "$events_file")"

  BILLING_MODE=""
  BILLING_PLAN=""
  ESTIMATED_API_COST_USD=""
  resolve_billing_plan
  estimate_api_cost "$input_tokens" "$output_tokens"
  billing_mode="$BILLING_MODE"
  plan="$BILLING_PLAN"
  estimated_cost="$ESTIMATED_API_COST_USD"

  duration_seconds=$((finished_epoch - started_epoch))
  [ "$duration_seconds" -ge 0 ] || duration_seconds=0
  project="$(basename "$REPO_ROOT")"
  branch="$(git -C "$REPO_ROOT" branch --show-current 2>/dev/null || true)"
  [ -n "$branch" ] || branch="detached"
  success=0
  [ "$codex_rc" -eq 0 ] && success=1

  usage_month="${started_at%T*}"
  usage_month="${usage_month%-*}"
  USAGE_DIR="$REPO_ROOT/.engrama/evidence/usage"
  usage_file="$USAGE_DIR/usage-$usage_month.jsonl"
  mkdir -p "$USAGE_DIR"

  run_stamp="$(printf '%s' "$started_at" | sed 's/:/-/g')"
  run_id="${run_stamp}-${codex_session:-unknown}"

  {
    printf '{'
    printf '"schema":"engrama.usage.v1",'
    printf '"run_id":%s,' "$(json_string "$run_id")"
    printf '"project":%s,' "$(json_string "$project")"
    printf '"branch":%s,' "$(json_string "$branch")"
    printf '"role":%s,' "$(json_string "$ROLE")"
    printf '"tier":%s,' "$(json_string "$TIER")"
    printf '"adapter":%s,' "$(json_string "$ADAPTER")"
    printf '"provider":%s,' "$(json_string "$PROVIDER")"
    printf '"surface":"exec",'
    printf '"model":%s,' "$(json_string "$MODEL")"
    printf '"effort":%s,' "$(json_string "$EFFORT")"
    printf '"billing_mode":%s,' "$(json_string "$billing_mode")"
    printf '"plan":%s,' "$(json_string "$plan")"
    printf '"started_at":%s,' "$(json_string "$started_at")"
    printf '"finished_at":%s,' "$(json_string "$finished_at")"
    printf '"duration_seconds":%s,' "$(json_number_or_null "$duration_seconds")"
    printf '"input_tokens":%s,' "$(json_number_or_null "$input_tokens")"
    printf '"output_tokens":%s,' "$(json_number_or_null "$output_tokens")"
    printf '"cached_input_tokens":%s,' "$(json_number_or_null "$cached_input_tokens")"
    printf '"total_tokens":%s,' "$(json_number_or_null "$total_tokens")"
    printf '"turns":%s,' "$(json_number_or_null "$turns")"
    printf '"estimated_api_cost_usd":%s,' "$(json_number_or_null "$estimated_cost")"
    printf '"allocated_subscription_cost_usd":null,'
    printf '"routing_reason":%s,' "$(json_string "$ROUTING_REASON")"
    printf '"transcript_path":%s,' "$(json_string "$response_rel")"
    printf '"codex_session":%s,' "$(json_string "$codex_session")"
    printf '"success":%s' "$(json_bool "$success")"
    printf '}\n'
  } >> "$usage_file"

  printf '%s\n' "${usage_file#"$REPO_ROOT"/}"
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
  local stream_model=""
  local session_file=""
  local started_at=""
  local finished_at=""
  local started_epoch=0
  local finished_epoch=0
  local usage_rel=""
  local adapter_script=""
  local -a adapter_cmd=()

  parse_args "$@"
  normalize_routing
  resolve_route
  default_label_if_needed
  prepare_inline_order
  validate_inputs
  resolve_date

  TRANSCRIPTS_DIR="$REPO_ROOT/.engrama/evidence/transcripts"
  order_rel=".engrama/evidence/transcripts/${RUN_DATE}-${LABEL}-order.md"
  order_path="$REPO_ROOT/$order_rel"
  response_rel=".engrama/evidence/transcripts/${RUN_DATE}-${LABEL}-response.md"
  response_path="$REPO_ROOT/$response_rel"

  [ ! -e "$order_path" ] || fail "transcript ja existe: $order_rel"
  [ ! -e "$response_path" ] || fail "transcript ja existe: $response_rel"

  mkdir -p "$TRANSCRIPTS_DIR"
  cp "$ORDER_FILE" "$order_path"

  ensure_tmpdir
  events_file="$TMPDIR_BRIDGE/codex-events.jsonl"
  stderr_file="$TMPDIR_BRIDGE/codex-stderr.log"

  adapter_script="$REPO_ROOT/.engrama/engine/adapters/$ADAPTER.sh"
  [ -f "$adapter_script" ] || fail "adapter ausente: $adapter_script"
  adapter_cmd=(bash "$adapter_script" --model "$MODEL" --effort "$EFFORT" --sandbox "$SANDBOX" --prompt-file "$ORDER_FILE" --events-file "$events_file" --stderr-file "$stderr_file")
  if [ "${#CODEX_EXTRA_ARGS[@]}" -gt 0 ]; then
    adapter_cmd+=(-- "${CODEX_EXTRA_ARGS[@]}")
  fi

  started_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  started_epoch="$(date +%s)"
  if "${adapter_cmd[@]}"; then
    codex_rc=0
  else
    codex_rc=$?
  fi
  finished_epoch="$(date +%s)"
  finished_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

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

  stream_model="$(extract_model_from_stream "$events_file")"
  [ -n "$stream_model" ] || stream_model="$MODEL"

  {
    printf '%s\n' '---'
    printf 'codex-session: %s\n' "$codex_session"
    printf 'codex-session-source: %s\n' "$codex_session_source"
    printf 'role: %s\n' "$ROLE"
    printf 'tier: %s\n' "$TIER"
    printf 'adapter: %s\n' "$ADAPTER"
    printf 'provider: %s\n' "$PROVIDER"
    printf 'model: %s\n' "$stream_model"
    printf 'configured-model: %s\n' "$MODEL"
    printf 'effort: %s\n' "$EFFORT"
    printf 'no-fallback: %s\n' "$NO_FALLBACK"
    printf 'routing-mode: %s\n' "$ROUTING_MODE"
    printf 'routing-reason: %s\n' "$ROUTING_REASON"
    printf 'sandbox: %s\n' "$SANDBOX"
    printf 'label: %s\n' "$LABEL"
    printf '%s\n\n' '---'
    printf '%s' "$response_text"
    printf '\n'
  } > "$response_path"

  usage_rel="$(append_usage_ledger "$started_at" "$finished_at" "$started_epoch" "$finished_epoch" "$response_rel" "$codex_session" "$codex_rc" "$events_file")"

  printf '%s\n' "$order_rel"
  printf '%s\n' "$response_rel"
  printf 'codex-session:%s\n' "$codex_session"
  printf 'usage-ledger:%s\n' "$usage_rel"

  if [ "$codex_rc" -ne 0 ]; then
    echo "exec-bridge: codex exec falhou com exit $codex_rc" >&2
    exit "$codex_rc"
  fi
}

main "$@"
