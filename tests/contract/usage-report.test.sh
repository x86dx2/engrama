#!/usr/bin/env bash
# Contract tests do usage-report local.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
REPORT="$REPO_ROOT/.engrama/engine/scripts/usage-report.sh"
[ -f "$REPORT" ] || { echo "FATAL: usage-report nao encontrado em $REPORT"; exit 1; }

PASS=0; FAIL=0; HOLES=0; RESULTS=""

check() {
  local id="$1" tag="$2" ok="$3" desc="$4" mark
  if [ "$ok" -eq 0 ]; then mark="ok"; PASS=$((PASS + 1)); else mark="XX"; FAIL=$((FAIL + 1)); fi
  [ "$tag" = "FURO" ] && HOLES=$((HOLES + 1))
  RESULTS="$RESULTS\n  [$mark] $id  ($tag)  | $desc"
}

TMP_USAGE="$(mktemp -d 2>/dev/null || mktemp -d -t engrama-usage-report)"
trap 'rm -rf "$TMP_USAGE"' EXIT

cat > "$TMP_USAGE/usage-2026-06.jsonl" <<'JSONL'
{"schema":"engrama.usage.v1","run_id":"r1","project":"engrama","branch":"b","role":"critique","tier":"T4","adapter":"codex","provider":"openai","surface":"exec","model":"gpt-5.5","effort":"high","billing_mode":"subscription","plan":"codex-pro","started_at":"2026-06-30T10:00:00Z","finished_at":"2026-06-30T10:01:00Z","duration_seconds":60,"input_tokens":null,"output_tokens":null,"cached_input_tokens":null,"total_tokens":null,"turns":1,"estimated_api_cost_usd":null,"allocated_subscription_cost_usd":null,"routing_reason":"x","transcript_path":".engrama/evidence/transcripts/a.md","codex_session":"s1","success":true}
{"schema":"engrama.usage.v1","run_id":"r2","project":"engrama","branch":"b","role":"execute","tier":"T2","adapter":"codex","provider":"openai","surface":"exec","model":"gpt-5.4","effort":"medium","billing_mode":"subscription","plan":"codex-pro","started_at":"2026-06-30T11:00:00Z","finished_at":"2026-06-30T11:02:00Z","duration_seconds":120,"input_tokens":10,"output_tokens":5,"cached_input_tokens":0,"total_tokens":15,"turns":1,"estimated_api_cost_usd":0.001,"allocated_subscription_cost_usd":null,"routing_reason":"x","transcript_path":".engrama/evidence/transcripts/b.md","codex_session":"s2","success":true}
{"schema":"engrama.usage.v1","run_id":"r3","project":"engrama","branch":"b","role":"review","tier":"T3","adapter":"codex","provider":"openai","surface":"exec","model":"gpt-5.4","effort":"high","billing_mode":"subscription","plan":"codex-pro","started_at":"2026-06-30T12:00:00Z","finished_at":"2026-06-30T12:03:00Z","duration_seconds":180,"input_tokens":null,"output_tokens":null,"cached_input_tokens":null,"total_tokens":null,"turns":1,"estimated_api_cost_usd":null,"allocated_subscription_cost_usd":null,"routing_reason":"x","transcript_path":".engrama/evidence/transcripts/c.md","codex_session":"s3","success":false}
JSONL

OUT="$(
  cd "$REPO_ROOT" || exit 2
  ENGRAMA_USAGE_DIR="$TMP_USAGE" bash "$REPORT" --month 2026-06
)"
RC=$?
if [ "$RC" -eq 0 ] \
  && printf '%s\n' "$OUT" | grep -Fq 'Total runs: 3' \
  && printf '%s\n' "$OUT" | grep -Fq 'Unknown-token runs: 2' \
  && printf '%s\n' "$OUT" | grep -Fq -- '- gpt-5.4: 2 runs' \
  && printf '%s\n' "$OUT" | grep -Fq -- '- critique: 1 runs' \
  && printf '%s\n' "$OUT" | grep -Fq 'Effective cost per run: US$33.33'; then
  _r=0
else
  _r=1
fi
check UR1 CORRETO "$_r" "relatorio completo sumariza runs, tokens nulos, grupos e alocacao de assinatura"

OUT="$(
  cd "$REPO_ROOT" || exit 2
  ENGRAMA_USAGE_DIR="$TMP_USAGE" bash "$REPORT" --month 2026-06 --by role
)"
RC=$?
if [ "$RC" -eq 0 ] \
  && printf '%s\n' "$OUT" | grep -Fq 'By role:' \
  && printf '%s\n' "$OUT" | grep -Fq -- '- execute: 1 runs' \
  && ! printf '%s\n' "$OUT" | grep -Fq 'By model:'; then
  _r=0
else
  _r=1
fi
check UR2 CORRETO "$_r" "--by role limita o agrupamento principal"

OUT="$(
  cd "$REPO_ROOT" || exit 2
  ENGRAMA_USAGE_DIR="$TMP_USAGE" bash "$REPORT" --month 2026-07
)"
RC=$?
if [ "$RC" -eq 0 ] && printf '%s\n' "$OUT" | grep -Fq 'no usage found'; then _r=0; else _r=1; fi
check UR3 CORRETO "$_r" "mes sem arquivo informa no usage found sem falhar"

OUT="$(
  cd "$REPO_ROOT" || exit 2
  ENGRAMA_USAGE_DIR="$TMP_USAGE" bash "$REPORT" --month 2026-06 --by provider 2>&1
)"
RC=$?
if [ "$RC" -ne 0 ] && printf '%s\n' "$OUT" | grep -Fq 'agrupamento invalido'; then _r=0; else _r=1; fi
check UR4 CORRETO "$_r" "agrupamento fora do contrato falha alto"

TMP_BIN="$TMP_USAGE/bin"
mkdir -p "$TMP_BIN"
cat > "$TMP_BIN/date" <<'EOF'
#!/usr/bin/env bash
if [ "$#" -eq 2 ] && [ "$1" = "-u" ] && [ "$2" = "+%Y-%m" ]; then
  printf '%s\n' "2026-06"
  exit 0
fi
printf 'date stub esperava -u +%%Y-%%m, recebeu: %s\n' "$*" >&2
exit 7
EOF
chmod +x "$TMP_BIN/date"

OUT="$(
  cd "$REPO_ROOT" || exit 2
  PATH="$TMP_BIN:$PATH" ENGRAMA_USAGE_DIR="$TMP_USAGE" bash "$REPORT" --month current 2>&1
)"
RC=$?
if [ "$RC" -eq 0 ] \
  && printf '%s\n' "$OUT" | grep -Fq 'Engrama Usage Report — 2026-06' \
  && printf '%s\n' "$OUT" | grep -Fq 'Total runs: 3'; then
  _r=0
else
  _r=1
fi
check UR5 CORRETO "$_r" "--month current usa mes UTC, mesma convencao do writer do ledger"

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: CORRETO = contrato esperado do usage-report."
[ "$FAIL" -eq 0 ] || exit 1
