#!/usr/bin/env bash
# Summarize local Engrama usage JSONL ledgers.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(git -C "$HERE/../../.." rev-parse --show-toplevel 2>/dev/null || true)"
MONTH="current"
BY=""
USAGE_DIR="${ENGRAMA_USAGE_DIR:-}"

usage() {
  cat <<'EOF'
Uso:
  bash .engrama/engine/scripts/usage-report.sh [--month YYYY-MM|current] [--by model|role|tier|adapter]
EOF
}

fail() {
  echo "usage-report: $*" >&2
  exit 2
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --month)
        shift
        [ "$#" -gt 0 ] || fail "faltou valor para --month"
        MONTH="$1"
        ;;
      --by)
        shift
        [ "$#" -gt 0 ] || fail "faltou valor para --by"
        BY="$1"
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

resolve_month() {
  if [ "$MONTH" = "current" ]; then
    MONTH="$(date -u +%Y-%m)"
    return
  fi

  case "$MONTH" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9])
      ;;
    *)
      fail "mes invalido: $MONTH (use YYYY-MM ou current)"
      ;;
  esac
}

validate_by() {
  case "$BY" in
    ""|model|role|tier|adapter)
      ;;
    *)
      fail "agrupamento invalido: $BY"
      ;;
  esac
}

money() {
  awk -v n="${1:-0}" 'BEGIN { printf "US$%.2f", n + 0 }'
}

print_group() {
  local title="$1" field="$2" file="$3"
  echo "$title:"
  jq -r --arg field "$field" '(.[$field] // "unknown")' "$file" |
    sort |
    uniq -c |
    awk '{
      count=$1
      $1=""
      sub(/^ /, "")
      printf "- %s: %s runs\n", $0, count
    }'
  echo ""
}

main() {
  local file total_runs total_turns known_tokens unknown_token_runs api_known api_total
  local subscriptions_conf codex_runs codex_turns cost_per_run cost_per_turn

  parse_args "$@"
  resolve_month
  validate_by

  [ -n "$REPO_ROOT" ] || fail "execute dentro de um repo git"
  command -v jq >/dev/null 2>&1 || fail "jq obrigatorio para sumarizar JSONL"

  if [ -z "$USAGE_DIR" ]; then
    USAGE_DIR="$REPO_ROOT/.engrama/evidence/usage"
  fi
  file="$USAGE_DIR/usage-$MONTH.jsonl"

  echo "Engrama Usage Report — $MONTH"
  echo ""

  if [ ! -s "$file" ]; then
    echo "no usage found"
    return 0
  fi

  total_runs="$(jq -s 'length' "$file")"
  total_turns="$(jq -s '[.[].turns // 0] | add // 0' "$file")"
  known_tokens="$(jq -s '[.[].total_tokens | select(. != null)] | add // null' "$file")"
  unknown_token_runs="$(jq -s '[.[] | select(.total_tokens == null)] | length' "$file")"

  echo "Total runs: $total_runs"
  echo "Total turns: $total_turns"
  if [ "$known_tokens" = "null" ]; then
    echo "Known tokens: unknown"
  else
    echo "Known tokens: $known_tokens"
  fi
  echo "Unknown-token runs: $unknown_token_runs"
  echo ""

  if [ -n "$BY" ]; then
    print_group "By $BY" "$BY" "$file"
  else
    print_group "By model" "model" "$file"
    print_group "By role" "role" "$file"
    print_group "By tier" "tier" "$file"
    print_group "By adapter" "adapter" "$file"
  fi

  subscriptions_conf="$REPO_ROOT/.engrama/engine/config/subscriptions.conf"
  if [ -f "$subscriptions_conf" ]; then
    # shellcheck disable=SC1090
    . "$subscriptions_conf"
  fi

  echo "Subscription allocation:"
  if [ "${ENGRAMA_CODEX_PRO_ENABLED:-0}" = "1" ]; then
    codex_runs="$(jq -s '[.[] | select(.plan == "codex-pro")] | length' "$file")"
    codex_turns="$(jq -s '[.[] | select(.plan == "codex-pro") | .turns // 0] | add // 0' "$file")"
    echo "- Codex Pro: $(money "${ENGRAMA_CODEX_PRO_MONTHLY_USD:-0}")/month"
    if [ "$codex_runs" -gt 0 ]; then
      cost_per_run="$(awk -v m="${ENGRAMA_CODEX_PRO_MONTHLY_USD:-0}" -v r="$codex_runs" 'BEGIN { printf "%.6f", m / r }')"
      echo "- Effective cost per run: $(money "$cost_per_run")"
    else
      echo "- Effective cost per run: unknown"
    fi
    if [ "$codex_turns" -gt 0 ]; then
      cost_per_turn="$(awk -v m="${ENGRAMA_CODEX_PRO_MONTHLY_USD:-0}" -v t="$codex_turns" 'BEGIN { printf "%.6f", m / t }')"
      echo "- Effective cost per turn: $(money "$cost_per_turn")"
    else
      echo "- Effective cost per turn: unknown"
    fi
  else
    echo "- unavailable: no enabled subscription config"
  fi
  echo ""

  api_known="$(jq -s '[.[].estimated_api_cost_usd | select(. != null)] | length' "$file")"
  api_total="$(jq -s '[.[].estimated_api_cost_usd | select(. != null)] | add // null' "$file")"
  echo "API estimate:"
  if [ "$api_known" -gt 0 ] && [ "$api_total" != "null" ]; then
    echo "- estimated total: $(money "$api_total")"
  else
    echo "- unavailable: prices/tokens missing"
  fi
}

main "$@"
