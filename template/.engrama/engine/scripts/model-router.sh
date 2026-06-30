#!/usr/bin/env bash
# Resolve Engrama role+tier into an adapter/provider/model/effort route.
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(git -C "$HERE/../../.." rev-parse --show-toplevel 2>/dev/null || true)"
ROLE=""
TIER=""
JSON_OUTPUT=0
MODELS_CONF="${ENGRAMA_MODELS_CONF:-}"

usage() {
  cat <<'EOF'
Uso:
  bash .engrama/engine/scripts/model-router.sh --role <role> --tier <T1|T2|T3|T4|T4+> [--json]

Roles aceitos:
  orchestrate execute critique review audit authority
EOF
}

fail() {
  echo "model-router: $*" >&2
  exit 2
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
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
      --json)
        JSON_OUTPUT=1
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

rank_tier() {
  case "$1" in
    T1) printf '1\n' ;;
    T2) printf '2\n' ;;
    T3) printf '3\n' ;;
    T4) printf '4\n' ;;
    T4+) printf '5\n' ;;
    *) return 1 ;;
  esac
}

tier_var_prefix() {
  case "$1" in
    T1) printf 'ENGRAMA_T1' ;;
    T2) printf 'ENGRAMA_T2' ;;
    T3) printf 'ENGRAMA_T3' ;;
    T4) printf 'ENGRAMA_T4' ;;
    T4+) printf 'ENGRAMA_T4_PLUS' ;;
    *) return 1 ;;
  esac
}

validate_role() {
  case "$1" in
    orchestrate|execute|critique|review|audit|authority) return 0 ;;
    *) fail "role invalido: $1" ;;
  esac
}

validate_tier() {
  rank_tier "$1" >/dev/null 2>&1 || fail "tier invalido: $1"
}

require_min_tier() {
  local role="$1" tier="$2" min="$3" got_rank min_rank
  got_rank="$(rank_tier "$tier")" || fail "tier invalido: $tier"
  min_rank="$(rank_tier "$min")" || fail "tier minimo invalido: $min"
  [ "$got_rank" -ge "$min_rank" ] || fail "role $role exige tier >= $min (recebido $tier)"
}

validate_role_policy() {
  case "$ROLE" in
    authority)
      require_min_tier "$ROLE" "$TIER" "T4+"
      ;;
    critique|audit)
      require_min_tier "$ROLE" "$TIER" "T4"
      ;;
    review|orchestrate)
      require_min_tier "$ROLE" "$TIER" "T3"
      ;;
    execute)
      ;;
  esac
}

load_config() {
  [ -n "$REPO_ROOT" ] || fail "execute dentro de um repo git"
  if [ -z "$MODELS_CONF" ]; then
    MODELS_CONF="$REPO_ROOT/.engrama/engine/config/models.conf"
  fi
  [ -f "$MODELS_CONF" ] || fail "config de modelos ausente: $MODELS_CONF"
  # shellcheck disable=SC1090
  . "$MODELS_CONF"
}

get_var() {
  local name="$1"
  printf '%s' "${!name-}"
}

shell_quote() {
  local value="$1"
  printf "'%s'" "$(printf '%s' "$value" | sed "s/'/'\\\\''/g")"
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/\\r}"
  value="${value//$'\t'/\\t}"
  printf '%s' "$value"
}

main() {
  local prefix adapter provider model effort no_fallback routing_reason

  parse_args "$@"
  [ -n "$ROLE" ] || fail "faltou --role"
  [ -n "$TIER" ] || fail "faltou --tier"
  validate_role "$ROLE"
  validate_tier "$TIER"
  validate_role_policy
  load_config

  prefix="$(tier_var_prefix "$TIER")"
  adapter="$(get_var "${prefix}_ADAPTER")"
  provider="$(get_var "${prefix}_PROVIDER")"
  model="$(get_var "${prefix}_MODEL")"
  effort="$(get_var "${prefix}_EFFORT")"

  [ -n "$adapter" ] || adapter="${ENGRAMA_DEFAULT_ADAPTER:-}"
  [ -n "$provider" ] || provider="${ENGRAMA_DEFAULT_PROVIDER:-}"

  [ -n "$adapter" ] || fail "adapter ausente para $TIER (${prefix}_ADAPTER)"
  [ -n "$provider" ] || fail "provider ausente para $TIER (${prefix}_PROVIDER)"
  [ -n "$model" ] || fail "model ausente para $TIER (${prefix}_MODEL)"
  [ -n "$effort" ] || fail "effort ausente para $TIER (${prefix}_EFFORT)"

  no_fallback=0
  case "$ROLE" in
    critique|audit|authority)
      no_fallback="${ENGRAMA_CRITIQUE_NO_FALLBACK:-1}"
      ;;
    *)
      ;;
  esac

  routing_reason="role=$ROLE tier=$TIER resolved via ${prefix}_*"

  if [ "$JSON_OUTPUT" -eq 1 ]; then
    cat <<EOF
{
  "adapter": "$(json_escape "$adapter")",
  "provider": "$(json_escape "$provider")",
  "model": "$(json_escape "$model")",
  "effort": "$(json_escape "$effort")",
  "role": "$(json_escape "$ROLE")",
  "tier": "$(json_escape "$TIER")",
  "no_fallback": $([ "$no_fallback" = "1" ] && printf 'true' || printf 'false'),
  "routing_reason": "$(json_escape "$routing_reason")"
}
EOF
    return
  fi

  printf 'ADAPTER=%s\n' "$(shell_quote "$adapter")"
  printf 'PROVIDER=%s\n' "$(shell_quote "$provider")"
  printf 'MODEL=%s\n' "$(shell_quote "$model")"
  printf 'EFFORT=%s\n' "$(shell_quote "$effort")"
  printf 'ROLE=%s\n' "$(shell_quote "$ROLE")"
  printf 'TIER=%s\n' "$(shell_quote "$TIER")"
  printf 'NO_FALLBACK=%s\n' "$(shell_quote "$no_fallback")"
  printf 'ROUTING_REASON=%s\n' "$(shell_quote "$routing_reason")"
}

main "$@"
