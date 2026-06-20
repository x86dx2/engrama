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

INPUT="$(cat 2>/dev/null)"
CMD="$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
    print((d.get("tool_input") or {}).get("command", ""))
except Exception:
    print("")' 2>/dev/null)"

# Só age em git commit (ignora status/log/diff/add etc.)
case "$CMD" in
  *"git commit"*|*"git "*"commit"*) ;;
  *) exit 0 ;;
esac

# CLAUDE_PROJECT_DIR é o env do harness; troque pela var do seu se for outro.
ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2>/dev/null)}"
[ -z "$ROOT" ] && exit 0
exec bash "$ROOT/.engrama/scripts/critique-gate.sh"
