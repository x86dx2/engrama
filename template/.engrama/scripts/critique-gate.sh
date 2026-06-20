#!/usr/bin/env bash
# Gate de crítica do Executor — ADR 0006 (item 7) + ADR 0010.
#
# Bloqueia (exit 2) commit que toca SUPERFÍCIE SENSÍVEL sem registro de crítica
# CONCLUÍDA em .engrama/qa/criticas-do-executor.md, por CATEGORIA, referenciando a branch.
#
# A crítica é feita por um agente/modelo INDEPENDENTE do Orquestrador (o Executor
# no papel de crítica, read-only). O gate exige o REGISTRO da crítica antes do
# commit — ele NÃO prova que um modelo independente de fato a produziu, e é um
# freio COOPERATIVO LOCAL (burlável por --no-verify / fora do harness). O
# enforcement vinculante (gate como required check na CI) é pendente — ver ADR 0006.
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
EXECUTOR_CMD="{{EXECUTOR_CMD}}"            # ex.: "codex exec"
CRITIQUE_MODEL="{{MODELO_CRITICA}}"        # ex.: "gpt-5.5"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || exit 0
cd "$REPO_ROOT" || exit 0

git diff --cached --quiet --exit-code -- 2>/dev/null && exit 0

CATS=""
addcat() { case " $CATS " in *" $1 "*) ;; *) CATS="$CATS $1" ;; esac; }

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

extract_branch_from_header() {
  local header="$1"
  if [[ "$header" =~ ^##\ \[[0-9]{4}-[0-9]{2}-[0-9]{2}\]\ (.*)$ ]]; then
    trim "${BASH_REMATCH[1]}"
    return 0
  fi
  return 1
}

is_ok_verdict() {
  local verdict_lc
  verdict_lc="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$verdict_lc" in
    confirmo|confirmo-bug|ressalvas|dispensada|n/a:*|waiver*) return 0 ;;
    *) return 1 ;;
  esac
}

is_blocking_objection() {
  local verdict="$1"
  if printf '%s\n' "$verdict" | grep -qi 'waiver'; then
    return 1
  fi

  if printf '%s\n' "$verdict" | grep -qiE '^(objec|objeç|discordo)'; then
    return 0
  fi

  return 1
}

# ── CONFIG DO PROJETO: arquivo → categoria(s) ─────────────────────────────────
# Categorias OK: financial · rbac · auth · schema · governance · gate · contract.
# governance/gate/contract sao UNIVERSAIS; o resto e ilustrativo — edite a vontade.
classify() {
  local f="$1"
  case "$f" in
    # --- Universais (nao remova) ---
    AGENTS.md|CLAUDE.md) addcat governance ;;
    .engrama/CLAUDE.md|.engrama/index.md|.engrama/log.md) addcat governance ;;
    .engrama/governance/*|.engrama/decisions/*|.engrama/specs/*|.engrama/project/*|.engrama/qa/*) addcat governance ;;
    .engrama/gaps/*|.engrama/roadmap/*|.engrama/domain/*) addcat governance ;;
    .engrama/scripts/critique-gate*|.engrama/githooks/*|.claude/settings.json) addcat gate ;;
    .github/*) addcat gate ;;
    tests/gate/*|*/tests/gate/*) addcat gate ;;
    tests/contract/*|*/tests/contract/*) addcat contract ;;

    # --- TEMPLATE: superficies de dominio (EXEMPLOS — troque pelos seus) ---
    # Fluxo financeiro / invariantes de valor:
    # src/server/services/agreements.*|src/server/services/ledger.*)    addcat financial ;;
    # RBAC / permissoes / multi-tenant:
    # src/server/permissions.*|src/server/services/users.*)             addcat rbac ;;
    # Autenticacao / sessao / rate-limit / rotas de auth:
    # src/server/auth.*|src/app/api/*/auth/*)                           addcat auth ;;
    # Schema / migrations:
    # migrations/*)                                                     addcat schema ;;
    # Rotas de API em geral (fallback de RBAC):
    # src/app/api/*)                                                    addcat rbac ;;
    *) : ;;
  esac
}
while IFS= read -r -d '' f; do
  classify "$f"
done < <(git diff --cached --name-only -z 2>/dev/null)

[ -z "$CATS" ] && exit 0

BRANCH="$(git branch --show-current 2>/dev/null)"
if [ -z "$BRANCH" ]; then
  {
    echo "──────────────────────────────────────────────────────────────"
    echo "🚫 GATE DE CRÍTICA — commit BLOQUEADO"
    echo ""
    echo "HEAD destacado (detached HEAD) em mudança sensível."
    echo "Categorias sensíveis tocadas:$CATS"
    echo "Sem branch nominal, o gate não consegue casar a crítica no ledger com segurança."
    echo "Faça checkout em uma branch antes de comitar esta fatia sensível."
    echo "──────────────────────────────────────────────────────────────"
  } >&2
  exit 2
fi

LEDGER=".engrama/qa/criticas-do-executor.md"
# Versão durável: índice (staged) com fallback p/ HEAD. NÃO usa o working-tree.
LEDGER_CONTENT="$(git show ":$LEDGER" 2>/dev/null || true)"
[ -z "$LEDGER_CONTENT" ] && LEDGER_CONTENT="$(git show "HEAD:$LEDGER" 2>/dev/null || true)"

MISSING=""
BLOCKED_OBJ=""

for cat in $CATS; do
  ok=""
  obj=""

  while IFS= read -r line; do
    case "$line" in
      '## ['*)
        IFS='|' read -r field1 field2 field3 field4 _rest <<< "$line"
        field1="$(trim "${field1:-}")"
        field2="$(trim "${field2:-}")"
        field3="$(trim "${field3:-}")"
        field4="$(trim "${field4:-}")"

        [ -n "$field4" ] || continue

        entry_branch="$(extract_branch_from_header "$field1")" || continue
        [ "$entry_branch" = "$BRANCH" ] || continue

        case "$field2" in
          *"[$cat]"*) ;;
          *) continue ;;
        esac

        if is_blocking_objection "$field3"; then
          obj=1
        fi

        if is_ok_verdict "$field3"; then
          ok=1
        fi
        ;;
      *)
        ;;
    esac
  done < <(printf '%s\n' "$LEDGER_CONTENT")

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

# probe sensivel 335e696
