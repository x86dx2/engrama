#!/usr/bin/env bash
# Gate de crítica do Executor — ADR 0006 (item 7) + ADR 0010.
#
# Bloqueia (exit 2) commit que toca SUPERFÍCIE SENSÍVEL sem registro de crítica
# CONCLUÍDA em .engrama/qa/criticas-do-executor.md, por CATEGORIA, referenciando a branch.
#
# A crítica é feita por um agente/modelo INDEPENDENTE do Orquestrador (o Executor
# no papel de crítica, read-only). O gate não confia na memória do Orquestrador:
# ele exige a PROVA registrada antes do commit.
#
# ── COMO ADAPTAR AO SEU PROJETO ───────────────────────────────────────────────
# 1. Ajuste as variáveis EXECUTOR_CMD / CRITIQUE_MODEL abaixo.
# 2. No bloco "CONFIG DO PROJETO" (a função classify), mapeie os ARQUIVOS/GLOBS
#    sensíveis do SEU código para as categorias. As categorias universais
#    (governance · gate · contract) já vêm pré-cabeadas; financial/rbac/auth/schema
#    são ILUSTRATIVAS — troque pelos caminhos reais do seu domínio.
# 3. Ative o hook: git config core.hooksPath .engrama/githooks  (e/ou PreToolUse no harness).
# ──────────────────────────────────────────────────────────────────────────────
set -u

# >>> TEMPLATE: preencha com o seu executor/modelo de crítica <<<
EXECUTOR_CMD="codex exec"            # ex.: "codex exec"
CRITIQUE_MODEL="gpt-5.5"        # ex.: "gpt-5.5"

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$REPO_ROOT" || exit 0

STAGED="$(git diff --cached --name-only 2>/dev/null)"
[ -z "$STAGED" ] && exit 0

CATS=""
addcat() { case " $CATS " in *" $1 "*) ;; *) CATS="$CATS $1" ;; esac; }

# ── CONFIG DO PROJETO: arquivo → categoria(s) ─────────────────────────────────
# Engrama central: governance/gate/contract sao as categorias ativas.
# financial/rbac/auth/schema ficam disponiveis para templates/projetos-alvo.
classify() {
  local f="$1"
  case "$f" in
    # Governanca ativa da instancia viva.
    CLAUDE.md|AGENTS.md|README.md|INSTALL.md|INSTANTIATE.md) addcat governance ;;
    .engrama/CLAUDE.md|.engrama/index.md|.engrama/log.md) addcat governance ;;
    .engrama/governance/*|.engrama/decisions/*|.engrama/specs/*|.engrama/project/*|.engrama/qa/*) addcat governance ;;

    # Template distribuivel. Mudancas aqui alteram o que novos projetos recebem.
    template/CLAUDE.md|template/AGENTS.md) addcat governance ;;
    template/.engrama/CLAUDE.md|template/.engrama/index.md|template/.engrama/log.md) addcat governance ;;
    template/.engrama/governance/*|template/.engrama/decisions/*|template/.engrama/specs/*|template/.engrama/project/*|template/.engrama/qa/*) addcat governance ;;

    # Instalador, hook, settings e defaults mecanicos.
    bootstrap.sh|install.sh|sync-template.sh|engrama.values.example) addcat gate ;;
    .engrama/scripts/critique-gate*|.engrama/githooks/*|.claude/settings.json) addcat gate ;;
    template/.engrama/scripts/critique-gate*|template/.engrama/githooks/*|template/.claude/settings.json) addcat gate ;;

    # Contrato verificavel do bootstrap/template.
    tests/contract/*|*/tests/contract/*) addcat contract ;;
    *) : ;;
  esac
}

while IFS= read -r f; do
  [ -z "$f" ] && continue
  classify "$f"
done <<EOF
$STAGED
EOF

[ -z "$CATS" ] && exit 0

BRANCH="$(git branch --show-current 2>/dev/null)"
LEDGER=".engrama/qa/criticas-do-executor.md"
# Versão durável: índice (staged) com fallback p/ HEAD. NÃO usa o working-tree.
LEDGER_CONTENT="$(git show ":$LEDGER" 2>/dev/null || true)"
[ -z "$LEDGER_CONTENT" ] && LEDGER_CONTENT="$(git show "HEAD:$LEDGER" 2>/dev/null || true)"

# NB: 'waiver' é detectado por substring; escreva-o sempre no POSITIVO
# ('waiver <quem/quando>'), nunca a palavra numa negação na mesma linha de
# uma objeção (ex.: evite "objeção sem waiver" na mesma linha) — fail-closed.
OK_TOKENS='confirmo|confirmo-bug|ressalvas|N/A:|waiver|dispensada'
MISSING=""
BLOCKED_OBJ=""

for cat in $CATS; do
  # Branch space-delimitada (evita slice/1 casar slice/10); formato do ledger: "] <branch> | [tags]"
  branchlines="$(printf '%s\n' "$LEDGER_CONTENT" | grep -F " $BRANCH " | grep -F "[$cat]" || true)"
  obj="$(printf '%s\n' "$branchlines" | grep -iE 'objeç|objec' | grep -viE 'waiver' || true)"
  ok="$(printf '%s\n' "$branchlines" | grep -viE 'pendente' | grep -iE "$OK_TOKENS" || true)"
  if [ -n "$obj" ]; then BLOCKED_OBJ="$BLOCKED_OBJ $cat"; fi
  if [ -z "$ok" ] || [ -n "$obj" ]; then MISSING="$MISSING $cat"; fi
done

[ -z "$MISSING" ] && exit 0

{
  echo "──────────────────────────────────────────────────────────────"
  echo "🚫 GATE DE CRÍTICA (ADR 0006 item 7 / ADR 0010) — commit BLOQUEADO"
  echo ""
  echo "Branch: $BRANCH"
  echo "Categorias sensíveis tocadas:$CATS"
  echo "Sem crítica CONCLUÍDA (ou com objeção aberta) para:$MISSING"
  [ -n "$BLOCKED_OBJ" ] && echo "Objeção do Executor SEM waiver registrado:$BLOCKED_OBJ (escale à Autoridade)"
  echo ""
  echo "Para cada categoria acima, em $LEDGER (staged), inclua uma linha com:"
  echo "  a branch '$BRANCH' + a tag [categoria] + veredito (confirmo|ressalvas|N/A:<motivo>|waiver)"
  echo "Rode a crítica (read-only, modelo independente):"
  echo "  $EXECUTOR_CMD -m $CRITIQUE_MODEL \"<ordem de crítica>\"   (sem auto-aplicar)"
  echo "──────────────────────────────────────────────────────────────"
} >&2
exit 2
