#!/usr/bin/env bash
# Contract tests do executor-bridge mecanizado.
# Garante persistencia em .engrama/evidence/transcripts/, extracao de codex-session e fallback derived.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WRAPPER_SRC="$REPO_ROOT/.engrama/engine/scripts/exec-bridge.sh"
[ -f "$WRAPPER_SRC" ] || { echo "FATAL: wrapper nao encontrado em $WRAPPER_SRC"; exit 1; }

_probe="$(mktemp -d 2>/dev/null)" || { echo "FATAL: mktemp indisponivel — abortando"; exit 3; }
git -C "$_probe" init -q 2>/dev/null || { echo "FATAL: git init indisponivel — abortando"; rm -rf "$_probe"; exit 3; }
rm -rf "$_probe"

PASS=0; FAIL=0; HOLES=0; RESULTS=""

check() { # <id> <tag> <cond 0/1> <desc>
  local id="$1" tag="$2" ok="$3" desc="$4" mark
  if [ "$ok" -eq 0 ]; then mark="ok"; PASS=$((PASS + 1)); else mark="XX"; FAIL=$((FAIL + 1)); fi
  [ "$tag" = "FURO" ] && HOLES=$((HOLES + 1))
  RESULTS="$RESULTS\n  [$mark] $id  ($tag)  | $desc"
}

new_repo() {
  local d
  d="$(mktemp -d 2>/dev/null || mktemp -d -t engrama-exec-bridge-test)"
  git -C "$d" init -q -b main 2>/dev/null || { git -C "$d" init -q; git -C "$d" checkout -q -b main; }
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  mkdir -p "$d/.engrama/engine/scripts" "$d/.engrama/engine/config" "$d/.engrama/engine/adapters" "$d/.engrama/evidence/usage"
  cp "$WRAPPER_SRC" "$d/.engrama/engine/scripts/exec-bridge.sh"
  cp "$REPO_ROOT/.engrama/engine/scripts/model-router.sh" "$d/.engrama/engine/scripts/model-router.sh"
  cp "$REPO_ROOT/.engrama/engine/adapters/codex.sh" "$d/.engrama/engine/adapters/codex.sh"
  cp "$REPO_ROOT/.engrama/engine/config/models.conf" "$d/.engrama/engine/config/models.conf"
  cp "$REPO_ROOT/.engrama/engine/config/subscriptions.conf" "$d/.engrama/engine/config/subscriptions.conf"
  cp "$REPO_ROOT/.engrama/engine/config/prices.conf" "$d/.engrama/engine/config/prices.conf"
  chmod +x "$d/.engrama/engine/scripts/exec-bridge.sh" "$d/.engrama/engine/scripts/model-router.sh" "$d/.engrama/engine/adapters/codex.sh"
  printf '%s' "$d"
}

write_real_stream_events() {
  local path="$1"
  cat > "$path" <<'JSON'
{"type":"thread.started","thread_id":"019ef9f3-e493-7a71-a5b2-688716a1281a"}
{"type":"item.completed","item":{"id":"item_0","type":"error","message":"failed to parse plugin hooks config ... unknown field `description`"}}
{"type":"turn.started"}
{"type":"item.completed","item":{"id":"item_1","type":"agent_message","text":"PONG"}}
{"type":"turn.completed","usage":{"input_tokens":1,"output_tokens":1}}
JSON
}

legacy_extract_response_text() {
  local events_file="$1"
  jq -Rr '
    fromjson? |
    select(.type == "response_item" and .payload.type == "message" and .payload.role == "assistant") |
    .payload.content[]? |
    select(.type == "output_text") |
    .text
  ' "$events_file"
}

write_real_stream_stub() {
  local path="$1"
  cat > "$path" <<'EOF'
#!/usr/bin/env bash
set -u

[ "${1:-}" = "exec" ] || { echo "stub recebeu comando inesperado: ${1:-<vazio>}" >&2; exit 9; }
cat >/dev/null
cat <<'JSON'
{"type":"thread.started","thread_id":"019ef9f3-e493-7a71-a5b2-688716a1281a"}
{"type":"item.completed","item":{"id":"item_0","type":"error","message":"failed to parse plugin hooks config ... unknown field `description`"}}
{"type":"turn.started"}
{"type":"item.completed","item":{"id":"item_1","type":"agent_message","text":"PONG"}}
{"type":"turn.completed","usage":{"input_tokens":1,"output_tokens":1}}
JSON
EOF
  chmod +x "$path"
}

write_legacy_stream_stub() {
  local path="$1"
  cat > "$path" <<'EOF'
#!/usr/bin/env bash
set -u

[ "${1:-}" = "exec" ] || { echo "stub recebeu comando inesperado: ${1:-<vazio>}" >&2; exit 9; }
cat >/dev/null
cat <<'JSON'
{"type":"session_meta","payload":{"id":"sessao-legacy-321"}}
{"type":"turn_context","payload":{"model":"gpt-5.4-mini"}}
{"type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"RESPOSTA-LEGACY-CAPTURADA"}],"phase":"final_answer"}}
JSON
EOF
  chmod +x "$path"
}

write_derived_stub() {
  local path="$1"
  cat > "$path" <<'EOF'
#!/usr/bin/env bash
set -u

[ "${1:-}" = "exec" ] || { echo "stub recebeu comando inesperado: ${1:-<vazio>}" >&2; exit 9; }
cat >/dev/null
cat <<'JSON'
{"type":"turn_context","payload":{"model":"gpt-5.4"}}
{"type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"Resposta sem session id no stream"}],"phase":"final_answer"}}
JSON
EOF
  chmod +x "$path"
}

# E1/E2/E3: contrato do schema REAL do codex-cli 0.142.0.
R="$(new_repo)"
ORDER="$R/ordem.md"
STUB="$R/codex-stub.sh"
printf 'ORDEM VERBATIM\n- item 1\n' > "$ORDER"
write_real_stream_stub "$STUB"
OUT="$(
  cd "$R" || exit 2
  ENGRAMA_CODEX_BIN="$STUB" bash ./.engrama/engine/scripts/exec-bridge.sh --order "$ORDER" --label demo --date 2026-06-21
)"
RC=$?
ORDER_OUT="$R/.engrama/evidence/transcripts/2026-06-21-demo-order.md"
RESPONSE_OUT="$R/.engrama/evidence/transcripts/2026-06-21-demo-response.md"
if [ "$RC" -eq 0 ] && [ -f "$ORDER_OUT" ] && [ -f "$RESPONSE_OUT" ] && cmp -s "$ORDER" "$ORDER_OUT"; then
  _r=0
else
  _r=1
fi
check E1 CORRETO "$_r" "salva order+response em .engrama/evidence/transcripts/ com data fixa e copia verbatim da ordem"

LEDGER_OUT="$(find "$R/.engrama/evidence/usage" -type f -name 'usage-*.jsonl' | sort | tail -1)"
if grep -Fq 'codex-session: 019ef9f3-e493-7a71-a5b2-688716a1281a' "$RESPONSE_OUT" \
  && grep -Fq 'codex-session-source: stream' "$RESPONSE_OUT" \
  && grep -Fq 'role: execute' "$RESPONSE_OUT" \
  && grep -Fq 'tier: T2' "$RESPONSE_OUT" \
  && grep -Fq 'adapter: codex' "$RESPONSE_OUT" \
  && grep -Fq 'model: gpt-5.4' "$RESPONSE_OUT" \
  && grep -Fq 'configured-model: gpt-5.4' "$RESPONSE_OUT" \
  && grep -Fq 'observed-model: null' "$RESPONSE_OUT" \
  && grep -Fq 'effort: medium' "$RESPONSE_OUT" \
  && grep -Fq 'routing-mode: default' "$RESPONSE_OUT" \
  && grep -Fq 'sandbox: read-only' "$RESPONSE_OUT" \
  && grep -Fq 'label: demo' "$RESPONSE_OUT" \
  && grep -Fq 'PONG' "$RESPONSE_OUT" \
  && ! grep -Fq "unknown field \`description\`" "$RESPONSE_OUT" \
  && [ -f "$LEDGER_OUT" ] \
  && grep -Fq '"schema":"engrama.usage.v1"' "$LEDGER_OUT" \
  && grep -Fq '"role":"execute"' "$LEDGER_OUT" \
  && grep -Fq '"tier":"T2"' "$LEDGER_OUT" \
  && grep -Fq '"model":"gpt-5.4"' "$LEDGER_OUT" \
  && grep -Fq '"configured_model":"gpt-5.4"' "$LEDGER_OUT" \
  && grep -Fq '"observed_model":null' "$LEDGER_OUT" \
  && grep -Fq '"total_tokens":2' "$LEDGER_OUT"; then
  _r=0
else
  _r=1
fi
check E2 CORRETO "$_r" "schema real 0.142.0: transcript captura agent_message, registra rota execute/T2 e grava usage ledger"

if printf '%s\n' "$OUT" | grep -Fqx '.engrama/evidence/transcripts/2026-06-21-demo-order.md' \
  && printf '%s\n' "$OUT" | grep -Fqx '.engrama/evidence/transcripts/2026-06-21-demo-response.md' \
  && printf '%s\n' "$OUT" | grep -Fqx 'codex-session:019ef9f3-e493-7a71-a5b2-688716a1281a' \
  && printf '%s\n' "$OUT" | grep -Eq '^usage-ledger:.engrama/evidence/usage/usage-[0-9]{4}-[0-9]{2}[.]jsonl$'; then
  _r=0
else
  _r=1
fi
check E3 CORRETO "$_r" "stdout imprime os dois caminhos salvos, codex-session:<id> e usage-ledger:<path>"

REAL_EVENTS="$R/codex-real-0.142.0.jsonl"
write_real_stream_events "$REAL_EVENTS"
REAL_RESPONSE_BODY="$(awk 'BEGIN { sep = 0 } /^---$/ { sep++; next } sep >= 2 { print }' "$RESPONSE_OUT")"
LEGACY_ON_REAL="$(legacy_extract_response_text "$REAL_EVENTS")"
if [ -n "$REAL_RESPONSE_BODY" ] && [ -z "$LEGACY_ON_REAL" ]; then
  _r=0
else
  _r=1
fi
check E3A CORRETO "$_r" "nao-vacuo: o mesmo stream real fica vazio no parser legado (so response_item) e so passa com o fix break-glass"

RLEG="$(new_repo)"
ORDERLEG="$RLEG/ordem.md"
STUBLEG="$RLEG/codex-legacy-stub.sh"
printf 'ORDEM LEGACY\n' > "$ORDERLEG"
write_legacy_stream_stub "$STUBLEG"
(
  cd "$RLEG" || exit 2
  ENGRAMA_CODEX_BIN="$STUBLEG" bash ./.engrama/engine/scripts/exec-bridge.sh --order "$ORDERLEG" --label legacy --date 2026-06-21 >/dev/null 2>&1
)
RESPONSE_OUT_LEG="$RLEG/.engrama/evidence/transcripts/2026-06-21-legacy-response.md"
LEDGER_OUT_LEG="$(find "$RLEG/.engrama/evidence/usage" -type f -name 'usage-*.jsonl' | sort | tail -1)"
if grep -Fq 'codex-session: sessao-legacy-321' "$RESPONSE_OUT_LEG" \
  && grep -Fq 'model: gpt-5.4-mini' "$RESPONSE_OUT_LEG" \
  && grep -Fq 'configured-model: gpt-5.4' "$RESPONSE_OUT_LEG" \
  && grep -Fq 'observed-model: gpt-5.4-mini' "$RESPONSE_OUT_LEG" \
  && grep -Fq 'RESPOSTA-LEGACY-CAPTURADA' "$RESPONSE_OUT_LEG" \
  && [ -f "$LEDGER_OUT_LEG" ] \
  && grep -Fq '"model":"gpt-5.4-mini"' "$LEDGER_OUT_LEG" \
  && grep -Fq '"configured_model":"gpt-5.4"' "$LEDGER_OUT_LEG" \
  && grep -Fq '"observed_model":"gpt-5.4-mini"' "$LEDGER_OUT_LEG"; then
  _r=0
else
  _r=1
fi
check E3B CORRETO "$_r" "compat retroativa: schema antigo continua capturando a resposta"

# E4: fallback derived quando o stream nao expoe sessao.
R2="$(new_repo)"
ORDER2="$R2/ordem.md"
STUB2="$R2/codex-derived-stub.sh"
printf 'ORDEM DERIVED\n' > "$ORDER2"
write_derived_stub "$STUB2"
OUT2="$(
  cd "$R2" || exit 2
  ENGRAMA_CODEX_BIN="$STUB2" bash ./.engrama/engine/scripts/exec-bridge.sh --order "$ORDER2" --label derived --date 2026-06-21
)"
RESPONSE_OUT2="$R2/.engrama/evidence/transcripts/2026-06-21-derived-response.md"
DERIVED_LINE="$(printf '%s\n' "$OUT2" | awk -F: '/^codex-session:/ { print $2 }')"
if grep -Fq 'codex-session-source: derived' "$RESPONSE_OUT2" && [ -n "$DERIVED_LINE" ]; then
  _r=0
else
  _r=1
fi
check E4 CORRETO "$_r" "se o stream nao expoe sessao, deriva um id deterministico e marca como derived"

# E5/E6: args obrigatorios faltando degradam com erro claro.
R3="$(new_repo)"
STUB3="$R3/codex-stub.sh"
write_real_stream_stub "$STUB3"
OUT3="$(
  cd "$R3" || exit 2
  ENGRAMA_CODEX_BIN="$STUB3" bash ./.engrama/engine/scripts/exec-bridge.sh --label sem-ordem --date 2026-06-21 2>&1
)"
RC3=$?
if [ "$RC3" -ne 0 ] && printf '%s\n' "$OUT3" | grep -Fq 'faltou --order'; then
  _r=0
else
  _r=1
fi
check E5 CORRETO "$_r" "falta de --order falha com mensagem clara"

printf 'ORDEM\n' > "$R3/ordem.md"
OUT4="$(
  cd "$R3" || exit 2
  ENGRAMA_CODEX_BIN="$STUB3" bash ./.engrama/engine/scripts/exec-bridge.sh --role critique --order "$R3/ordem.md" --date 2026-06-21 2>&1
)"
RC4=$?
if [ "$RC4" -ne 0 ] && printf '%s\n' "$OUT4" | grep -Fq -- '--role e --tier devem ser informados juntos'; then
  _r=0
else
  _r=1
fi
check E6 CORRETO "$_r" "role sem tier falha com mensagem clara"

# E7: fallback do session file com session id no schema NOVO do stream.
R7="$(new_repo)"
STUB7="$R7/codex-stub.sh"
cat > "$STUB7" <<'EOF'
#!/usr/bin/env bash
set -u
[ "${1:-}" = "exec" ] || { echo "stub recebeu comando inesperado" >&2; exit 9; }
cat >/dev/null
# stream no schema 0.142.0 com thread.started, mas SEM agent_message.
printf '%s\n' '{"type":"thread.started","thread_id":"sessao-fb-777"}'
printf '%s\n' '{"type":"turn.started"}'
printf '%s\n' '{"type":"turn.completed","usage":{"input_tokens":1,"output_tokens":1}}'
EOF
chmod +x "$STUB7"
HOME7="$(mktemp -d 2>/dev/null || mktemp -d -t eg-home)"
mkdir -p "$HOME7/sessions/2026/06/21"
printf '%s\n' '{"type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"RESPOSTA-DO-SESSION-FILE-FALLBACK"}]}}' \
  > "$HOME7/sessions/2026/06/21/rollout-2026-06-21-sessao-fb-777.jsonl"
printf 'ORDEM\n' > "$R7/ordem.md"
(
  cd "$R7" || exit 2
  CODEX_HOME="$HOME7" ENGRAMA_CODEX_BIN="$STUB7" bash ./.engrama/engine/scripts/exec-bridge.sh --order "$R7/ordem.md" --label fallback --date 2026-06-21 >/dev/null 2>&1
)
RESP7="$R7/.engrama/evidence/transcripts/2026-06-21-fallback-response.md"
if [ -f "$RESP7" ] && grep -Fq 'RESPOSTA-DO-SESSION-FILE-FALLBACK' "$RESP7"; then _r=0; else _r=1; fi
rm -rf "$HOME7"
check E7 CORRETO "$_r" "fallback: extrai a resposta do session file quando o stream nao a traz (codex real)"

# E8: auto-editar o bridge do working tree durante a run nao pode mais
# corromper a execucao em curso; o wrapper deve rodar de uma copia estavel.
R8="$(new_repo)"
STUB8="$R8/codex-self-edit-stub.sh"
cat > "$STUB8" <<'EOF'
#!/usr/bin/env bash
set -u

[ "${1:-}" = "exec" ] || { echo "stub recebeu comando inesperado" >&2; exit 9; }
cat >/dev/null
cat > "./.engrama/engine/scripts/exec-bridge.sh" <<'BROKEN'
#!/usr/bin/env bash
set -u
# mutated during contract test
BROKEN
cat <<'JSON'
{"type":"thread.started","thread_id":"019ef9f3-e493-7a71-a5b2-688716a1288"}
{"type":"item.completed","item":{"id":"item_0","type":"error","message":"failed to parse plugin hooks config ... unknown field `description`"}}
{"type":"turn.started"}
{"type":"item.completed","item":{"id":"item_1","type":"agent_message","text":"RUN IMUNE A AUTO-EDICAO"}}
{"type":"turn.completed","usage":{"input_tokens":1,"output_tokens":1}}
JSON
EOF
chmod +x "$STUB8"
printf 'ORDEM AUTO-EDICAO\n' > "$R8/ordem.md"
OUT8="$(
  cd "$R8" || exit 2
  ENGRAMA_CODEX_BIN="$STUB8" bash ./.engrama/engine/scripts/exec-bridge.sh --order "$R8/ordem.md" --label self-edit --date 2026-06-21
)"
RC8=$?
ORDER_OUT8="$R8/.engrama/evidence/transcripts/2026-06-21-self-edit-order.md"
RESPONSE_OUT8="$R8/.engrama/evidence/transcripts/2026-06-21-self-edit-response.md"
if [ "$RC8" -eq 0 ] \
  && [ -f "$ORDER_OUT8" ] \
  && [ -f "$RESPONSE_OUT8" ] \
  && grep -Fq 'RUN IMUNE A AUTO-EDICAO' "$RESPONSE_OUT8" \
  && ! grep -Fq "unknown field \`description\`" "$RESPONSE_OUT8" \
  && grep -Fq 'mutated during contract test' "$R8/.engrama/engine/scripts/exec-bridge.sh" \
  && printf '%s\n' "$OUT8" | grep -Fqx 'codex-session:019ef9f3-e493-7a71-a5b2-688716a1288'; then
  _r=0
else
  _r=1
fi
check E8 CORRETO "$_r" "auto-edicao do exec-bridge em runtime nao quebra a run; bridge sai 0 e preserva transcripts"

# E9: chamada nova do PRD — role/tier explicitos + prompt inline + label automatico.
R9="$(new_repo)"
STUB9="$R9/codex-stub.sh"
write_real_stream_stub "$STUB9"
OUT9="$(
  cd "$R9" || exit 2
  ENGRAMA_CODEX_BIN="$STUB9" bash ./.engrama/engine/scripts/exec-bridge.sh --role critique --tier T4 --sandbox read-only -- "ORDEM INLINE CRITICA"
)"
RC9=$?
ORDER_REL9="$(printf '%s\n' "$OUT9" | sed -n '1p')"
RESP_REL9="$(printf '%s\n' "$OUT9" | sed -n '2p')"
ORDER_OUT9="$R9/$ORDER_REL9"
RESP_OUT9="$R9/$RESP_REL9"
LEDGER_OUT9="$(find "$R9/.engrama/evidence/usage" -type f -name 'usage-*.jsonl' | sort | tail -1)"
if [ "$RC9" -eq 0 ] \
  && [ -f "$ORDER_OUT9" ] \
  && [ -f "$RESP_OUT9" ] \
  && grep -Fq 'ORDEM INLINE CRITICA' "$ORDER_OUT9" \
  && grep -Fq 'role: critique' "$RESP_OUT9" \
  && grep -Fq 'tier: T4' "$RESP_OUT9" \
  && grep -Fq 'model: gpt-5.5' "$RESP_OUT9" \
  && grep -Fq 'effort: high' "$RESP_OUT9" \
  && grep -Fq 'routing-mode: explicit' "$RESP_OUT9" \
  && [ -f "$LEDGER_OUT9" ] \
  && grep -Fq '"role":"critique"' "$LEDGER_OUT9" \
  && grep -Fq '"tier":"T4"' "$LEDGER_OUT9" \
  && grep -Fq '"model":"gpt-5.5"' "$LEDGER_OUT9" \
  && grep -Fq '"configured_model":"gpt-5.5"' "$LEDGER_OUT9" \
  && grep -Fq '"observed_model":null' "$LEDGER_OUT9"; then
  _r=0
else
  _r=1
fi
check E9 CORRETO "$_r" "role/tier explicitos com prompt inline geram auto-label, transcript roteado e usage ledger"

# E10: se o adapter falha antes de produzir events JSONL, o bridge nao pode
# chamar jq em arquivo inexistente nem gravar response/usage artificiais.
R10="$(new_repo)"
ORDER10="$R10/ordem.md"
printf 'ORDEM BIN AUSENTE\n' > "$ORDER10"
OUT10="$(
  cd "$R10" || exit 2
  ENGRAMA_CODEX_BIN="$R10/binario-inexistente" bash ./.engrama/engine/scripts/exec-bridge.sh --order "$ORDER10" --label missing-bin --date 2026-06-21 2>&1
)"
RC10=$?
ORDER_OUT10="$R10/.engrama/evidence/transcripts/2026-06-21-missing-bin-order.md"
RESPONSE_OUT10="$R10/.engrama/evidence/transcripts/2026-06-21-missing-bin-response.md"
LEDGER_COUNT10="$(find "$R10/.engrama/evidence/usage" -type f -name 'usage-*.jsonl' | wc -l | tr -d ' ')"
if [ "$RC10" -ne 0 ] \
  && printf '%s\n' "$OUT10" | grep -Fq 'codex bin nao encontrado' \
  && printf '%s\n' "$OUT10" | grep -Fq 'adapter nao produziu eventos JSONL' \
  && ! printf '%s\n' "$OUT10" | grep -Fq 'jq: Could not open file' \
  && ! printf '%s\n' "$OUT10" | grep -Fq 'usage-ledger:' \
  && [ ! -e "$ORDER_OUT10" ] \
  && [ ! -e "$RESPONSE_OUT10" ] \
  && [ "$LEDGER_COUNT10" -eq 0 ]; then
  _r=0
else
  _r=1
fi
check E10 CORRETO "$_r" "falha inicial do adapter sem events JSONL aborta sem jq noise, transcript de resposta ou usage ledger"

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: CORRETO = contrato esperado do wrapper do executor-bridge."
[ "$FAIL" -eq 0 ] || exit 1
