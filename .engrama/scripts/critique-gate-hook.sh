#!/usr/bin/env bash
# Wrapper do gate de crítica para o PreToolUse hook do harness do Orquestrador
# (ex.: Claude Code, matcher: Bash). Lê o JSON do hook no stdin, extrai o comando,
# e se for um `git commit` (inclusive com --no-verify, que burlaria o hook nativo
# do git), roda o gate. Exit 2 = bloqueia a chamada e devolve o stderr ao agente.
#
# Por que existe: o pre-commit do git pode ser burlado com `--no-verify`. Cabear
# o gate TAMBÉM no harness do Orquestrador fecha esse buraco para o caminho normal
# (o agente comitando). Defesa em profundidade, não substituto do CI.
set -u

INPUT="$(cat 2>/dev/null || true)"

raw_looks_like_git_commit() {
  printf '%s' "$1" | grep -Eq 'git[[:space:]]+commit([[:space:]]|$)'
}

cmd_looks_like_git_commit() {
  case "$1" in
    *"git commit"*|*"git "*"commit"*) return 0 ;;
    *) return 1 ;;
  esac
}

delegate_or_block() {
  local reason="$1"
  ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
  if [ -n "${ROOT:-}" ] && [ -f "$ROOT/.engrama/scripts/critique-gate.sh" ]; then
    echo "critique-gate-hook: $reason; delegando ao gate." >&2
    exec bash "$ROOT/.engrama/scripts/critique-gate.sh"
  fi

  echo "critique-gate-hook: $reason; sem acesso ao gate para validar com segurança." >&2
  exit 2
}

CMD=""
PARSE_OK=0
if command -v python3 >/dev/null 2>&1; then
  if CMD="$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)
command = (data.get("tool_input") or {}).get("command")
if not isinstance(command, str):
    sys.exit(2)
print(command)' 2>/dev/null)"; then
    PARSE_OK=1
  fi
fi

if [ "$PARSE_OK" -ne 1 ]; then
  if raw_looks_like_git_commit "$INPUT"; then
    if command -v python3 >/dev/null 2>&1; then
      delegate_or_block "falha ao parsear o comando de commit"
    fi
    delegate_or_block "python3 ausente para inspecionar o comando de commit"
  fi

  exit 0
fi

# Só age em git commit (ignora status/log/diff/add etc.)
cmd_looks_like_git_commit "$CMD" || exit 0

delegate_or_block "comando de commit detectado"
