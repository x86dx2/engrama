#!/usr/bin/env bash
# Contract tests do executor-bridge mecanizado.
# Garante persistencia em transcripts/, extracao de codex-session e fallback derived.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
WRAPPER_SRC="$REPO_ROOT/.engrama/scripts/exec-bridge.sh"
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
  mkdir -p "$d/.engrama/scripts" "$d/transcripts"
  cp "$WRAPPER_SRC" "$d/.engrama/scripts/exec-bridge.sh"
  chmod +x "$d/.engrama/scripts/exec-bridge.sh"
  printf '%s' "$d"
}

write_stream_stub() {
  local path="$1"
  cat > "$path" <<'EOF'
#!/usr/bin/env bash
set -u

[ "${1:-}" = "exec" ] || { echo "stub recebeu comando inesperado: ${1:-<vazio>}" >&2; exit 9; }
cat >/dev/null
cat <<'JSON'
{"type":"session_meta","payload":{"id":"sessao-fake-123"}}
{"type":"turn_context","payload":{"model":"gpt-5.4-mini"}}
{"type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"Leitura da ordem\nCritica tecnica\nVeredito: concordo"}],"phase":"final_answer"}}
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

# E1/E2/E3: salva os dois arquivos, response com cabecalho e imprime codex-session.
R="$(new_repo)"
ORDER="$R/ordem.md"
STUB="$R/codex-stub.sh"
printf 'ORDEM VERBATIM\n- item 1\n' > "$ORDER"
write_stream_stub "$STUB"
OUT="$(
  cd "$R" || exit 2
  ENGRAMA_CODEX_BIN="$STUB" bash ./.engrama/scripts/exec-bridge.sh --order "$ORDER" --label demo --date 2026-06-21
)"
RC=$?
ORDER_OUT="$R/transcripts/2026-06-21-demo-order.md"
RESPONSE_OUT="$R/transcripts/2026-06-21-demo-response.md"
if [ "$RC" -eq 0 ] && [ -f "$ORDER_OUT" ] && [ -f "$RESPONSE_OUT" ] && cmp -s "$ORDER" "$ORDER_OUT"; then
  _r=0
else
  _r=1
fi
check E1 CORRETO "$_r" "salva order+response em transcripts/ com data fixa e copia verbatim da ordem"

if grep -Fq 'codex-session: sessao-fake-123' "$RESPONSE_OUT" \
  && grep -Fq 'model: gpt-5.4-mini' "$RESPONSE_OUT" \
  && grep -Fq 'sandbox: read-only' "$RESPONSE_OUT" \
  && grep -Fq 'label: demo' "$RESPONSE_OUT"; then
  _r=0
else
  _r=1
fi
check E2 CORRETO "$_r" "response.md carrega cabecalho YAML com codex-session/model/sandbox/label"

if printf '%s\n' "$OUT" | grep -Fqx 'transcripts/2026-06-21-demo-order.md' \
  && printf '%s\n' "$OUT" | grep -Fqx 'transcripts/2026-06-21-demo-response.md' \
  && printf '%s\n' "$OUT" | grep -Fqx 'codex-session:sessao-fake-123'; then
  _r=0
else
  _r=1
fi
check E3 CORRETO "$_r" "stdout imprime os dois caminhos salvos e a linha codex-session:<id>"

# E4: fallback derived quando o stream nao expoe sessao.
R2="$(new_repo)"
ORDER2="$R2/ordem.md"
STUB2="$R2/codex-derived-stub.sh"
printf 'ORDEM DERIVED\n' > "$ORDER2"
write_derived_stub "$STUB2"
OUT2="$(
  cd "$R2" || exit 2
  ENGRAMA_CODEX_BIN="$STUB2" bash ./.engrama/scripts/exec-bridge.sh --order "$ORDER2" --label derived --date 2026-06-21
)"
RESPONSE_OUT2="$R2/transcripts/2026-06-21-derived-response.md"
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
write_stream_stub "$STUB3"
OUT3="$(
  cd "$R3" || exit 2
  ENGRAMA_CODEX_BIN="$STUB3" bash ./.engrama/scripts/exec-bridge.sh --label sem-ordem --date 2026-06-21 2>&1
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
  ENGRAMA_CODEX_BIN="$STUB3" bash ./.engrama/scripts/exec-bridge.sh --order "$R3/ordem.md" --date 2026-06-21 2>&1
)"
RC4=$?
if [ "$RC4" -ne 0 ] && printf '%s\n' "$OUT4" | grep -Fq 'faltou --label'; then
  _r=0
else
  _r=1
fi
check E6 CORRETO "$_r" "falta de --label falha com mensagem clara"

# E7: FALLBACK do session file — replica o codex REAL (o output_text final do
# assistant NAO vem no stream --json; so no ~/.codex/sessions/.../<id>.jsonl).
# Stub emite session_meta SEM response_item; o wrapper deve achar o session file
# (via CODEX_HOME) e extrair a resposta de la. (Regressao que o bug de PR-A passou.)
R7="$(new_repo)"
STUB7="$R7/codex-stub.sh"
cat > "$STUB7" <<'EOF'
#!/usr/bin/env bash
set -u
[ "${1:-}" = "exec" ] || { echo "stub recebeu comando inesperado" >&2; exit 9; }
cat >/dev/null
# stream com session_meta mas SEM o output_text do assistant (como o codex real)
printf '%s\n' '{"type":"session_meta","payload":{"id":"sessao-fb-777"}}'
printf '%s\n' '{"type":"turn_context","payload":{"model":"gpt-5.4"}}'
EOF
chmod +x "$STUB7"
HOME7="$(mktemp -d 2>/dev/null || mktemp -d -t eg-home)"
mkdir -p "$HOME7/sessions/2026/06/21"
printf '%s\n' '{"type":"response_item","payload":{"type":"message","role":"assistant","content":[{"type":"output_text","text":"RESPOSTA-DO-SESSION-FILE-FALLBACK"}]}}' \
  > "$HOME7/sessions/2026/06/21/rollout-2026-06-21-sessao-fb-777.jsonl"
printf 'ORDEM\n' > "$R7/ordem.md"
(
  cd "$R7" || exit 2
  CODEX_HOME="$HOME7" ENGRAMA_CODEX_BIN="$STUB7" bash ./.engrama/scripts/exec-bridge.sh --order "$R7/ordem.md" --label fallback --date 2026-06-21 >/dev/null 2>&1
)
RESP7="$R7/transcripts/2026-06-21-fallback-response.md"
if [ -f "$RESP7" ] && grep -Fq 'RESPOSTA-DO-SESSION-FILE-FALLBACK' "$RESP7"; then _r=0; else _r=1; fi
rm -rf "$HOME7"
check E7 CORRETO "$_r" "fallback: extrai a resposta do session file quando o stream nao a traz (codex real)"

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: CORRETO = contrato esperado do wrapper do executor-bridge."
[ "$FAIL" -eq 0 ] || exit 1
