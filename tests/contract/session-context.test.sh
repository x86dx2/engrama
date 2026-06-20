#!/usr/bin/env bash
# Contract tests do session-context.sh.
# Garante auto-surface defensivo do checkpoint e lembrete honesto sem auto-write.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SESSION_CONTEXT_SRC="$REPO_ROOT/.engrama/scripts/session-context.sh"
[ -f "$SESSION_CONTEXT_SRC" ] || { echo "FATAL: session-context nao encontrado em $SESSION_CONTEXT_SRC"; exit 1; }

PASS=0; FAIL=0; HOLES=0; RESULTS=""

check() { # <id> <tag> <cond 0/1> <desc>
  local id="$1" tag="$2" ok="$3" desc="$4" mark
  if [ "$ok" -eq 0 ]; then mark="ok"; PASS=$((PASS + 1)); else mark="XX"; FAIL=$((FAIL + 1)); fi
  [ "$tag" = "FURO" ] && HOLES=$((HOLES + 1))
  RESULTS="$RESULTS\n  [$mark] $id  ($tag)  | $desc"
}

new_fixture_root() {
  local d
  d="$(mktemp -d 2>/dev/null || mktemp -d -t engrama-session-context)"
  mkdir -p "$d/.engrama/scripts" "$d/.engrama/project"
  cp "$SESSION_CONTEXT_SRC" "$d/.engrama/scripts/session-context.sh"
  chmod +x "$d/.engrama/scripts/session-context.sh" 2>/dev/null || true
  printf '%s' "$d"
}

run_script() {
  local root="$1" out="$2"
  (
    cd "$root" || exit 2
    bash "$root/.engrama/scripts/session-context.sh" >"$out" 2>&1
    echo $?
  )
}

# SC1: imprime o bloco mais recente do topo e nao vaza o bloco anterior.
R1="$(new_fixture_root)"
cat > "$R1/.engrama/log.md" <<'EOF'
# Log

Texto introdutorio.

## [2026-06-20] fix | checkpoint atual
- estado atual
- proximo passo seguro

## [2026-06-19] fix | checkpoint antigo
- nao deveria aparecer
EOF
cat > "$R1/.engrama/project/bootstrap-do-projeto.md" <<'EOF'
---
status: active
---
EOF
O1="$(mktemp)"
rc1="$(run_script "$R1" "$O1")"
if [ "$rc1" -eq 0 ] \
  && grep -Fq '## [2026-06-20] fix | checkpoint atual' "$O1" \
  && grep -Fq -- '- estado atual' "$O1" \
  && ! grep -Fq '## [2026-06-19] fix | checkpoint antigo' "$O1"; then
  _r=0
else
  _r=1
fi
check SC1 CORRETO "$_r" "imprime so o bloco mais recente do checkpoint vivo"

# SC2: sem log/bootstrap, degrada sem quebrar e ainda lembra o handshake.
R2="$(new_fixture_root)"
O2="$(mktemp)"
rc2="$(run_script "$R2" "$O2")"
if [ "$rc2" -eq 0 ] && grep -Fq 'Handshake:' "$O2" && grep -Fq 'auto-surface + lembrete' "$O2"; then
  _r=0
else
  _r=1
fi
check SC2 CORRETO "$_r" "degrada sem quebrar quando log/bootstrap faltam"

# SC3: bootstrap proposed avisa explicitamente que a abertura ainda nao concluiu.
R3="$(new_fixture_root)"
cat > "$R3/.engrama/project/bootstrap-do-projeto.md" <<'EOF'
---
status: proposed
---
EOF
O3="$(mktemp)"
rc3="$(run_script "$R3" "$O3")"
if [ "$rc3" -eq 0 ] && grep -Fq 'BOOTSTRAP PENDENTE:' "$O3" && grep -Fq 'status proposed' "$O3"; then
  _r=0
else
  _r=1
fi
check SC3 CORRETO "$_r" "avisa quando o bootstrap esta proposed"

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: CORRETO = contrato esperado do session-context."
[ "$FAIL" -eq 0 ] || exit 1
