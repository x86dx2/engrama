#!/usr/bin/env bash
# Contract tests do runtime model router.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ROUTER="$REPO_ROOT/.engrama/engine/scripts/model-router.sh"
[ -f "$ROUTER" ] || { echo "FATAL: router nao encontrado em $ROUTER"; exit 1; }

PASS=0; FAIL=0; HOLES=0; RESULTS=""

check() {
  local id="$1" tag="$2" ok="$3" desc="$4" mark
  if [ "$ok" -eq 0 ]; then mark="ok"; PASS=$((PASS + 1)); else mark="XX"; FAIL=$((FAIL + 1)); fi
  [ "$tag" = "FURO" ] && HOLES=$((HOLES + 1))
  RESULTS="$RESULTS\n  [$mark] $id  ($tag)  | $desc"
}

run_router() {
  (cd "$REPO_ROOT" && bash "$ROUTER" "$@")
}

OUT="$(run_router --role execute --tier T2)"
RC=$?
if [ "$RC" -eq 0 ] && eval "$OUT" && [ "$ADAPTER" = "codex" ] && [ "$MODEL" = "gpt-5.4" ] && [ "$EFFORT" = "medium" ] && [ "$ROLE" = "execute" ] && [ "$TIER" = "T2" ]; then
  _r=0
else
  _r=1
fi
check MR1 CORRETO "$_r" "resolve execute/T2 para adapter/model/effort configurados"

OUT="$(run_router --role critique --tier T4)"
RC=$?
if [ "$RC" -eq 0 ] && eval "$OUT" && [ "$MODEL" = "gpt-5.5" ] && [ "$EFFORT" = "high" ] && [ "$NO_FALLBACK" = "1" ]; then
  _r=0
else
  _r=1
fi
check MR2 CORRETO "$_r" "resolve critique/T4 no modelo maximo configurado e marca no_fallback"

OUT="$(run_router --role authority --tier T4+ --json)"
RC=$?
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -Fq '"tier": "T4+"' && printf '%s\n' "$OUT" | grep -Fq '"effort": "xhigh"' && printf '%s\n' "$OUT" | grep -Fq '"no_fallback": true'; then
  _r=0
else
  _r=1
fi
check MR3 CORRETO "$_r" "resolve authority/T4+ e serializa JSON parseavel"

OUT="$(run_router --role invalido --tier T2 2>&1)"
RC=$?
if [ "$RC" -ne 0 ] && printf '%s\n' "$OUT" | grep -Fq 'role invalido'; then _r=0; else _r=1; fi
check MR4 CORRETO "$_r" "rejeita role invalido com erro claro"

OUT="$(run_router --role execute --tier T9 2>&1)"
RC=$?
if [ "$RC" -ne 0 ] && printf '%s\n' "$OUT" | grep -Fq 'tier invalido'; then _r=0; else _r=1; fi
check MR5 CORRETO "$_r" "rejeita tier invalido com erro claro"

OUT="$(run_router --role critique --tier T3 2>&1)"
RC=$?
if [ "$RC" -ne 0 ] && printf '%s\n' "$OUT" | grep -Fq 'exige tier >= T4'; then _r=0; else _r=1; fi
check MR6 CORRETO "$_r" "critique nao pode descer para T3"

TMP_CONF="$(mktemp 2>/dev/null || mktemp -t engrama-router-conf)"
cat > "$TMP_CONF" <<'EOF'
ENGRAMA_DEFAULT_ADAPTER=codex
ENGRAMA_DEFAULT_PROVIDER=openai
ENGRAMA_CRITIQUE_NO_FALLBACK=1
ENGRAMA_T4_ADAPTER=codex
ENGRAMA_T4_PROVIDER=openai
ENGRAMA_T4_MODEL=
ENGRAMA_T4_EFFORT=high
EOF
OUT="$(
  cd "$REPO_ROOT" || exit 2
  ENGRAMA_MODELS_CONF="$TMP_CONF" bash "$ROUTER" --role critique --tier T4 2>&1
)"
RC=$?
rm -f "$TMP_CONF"
if [ "$RC" -ne 0 ] && printf '%s\n' "$OUT" | grep -Fq 'model ausente para T4'; then _r=0; else _r=1; fi
check MR7 CORRETO "$_r" "critique/T4 sem modelo configurado falha alto e nao faz fallback silencioso"

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: CORRETO = contrato esperado do model-router."
[ "$FAIL" -eq 0 ] || exit 1
