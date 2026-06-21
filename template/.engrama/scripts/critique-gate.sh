#!/usr/bin/env bash
# Gate de crítica do Executor — ADR 0006 (item 7) + ADR 0010.
#
# Bloqueia (exit 2) commit que toca SUPERFÍCIE SENSÍVEL sem registro de crítica
# CONCLUÍDA em .engrama/qa/criticas-do-executor.md, por CATEGORIA, referenciando
# a branch. O campo 4 (ref) pode carregar opcionalmente um `sha256:<hex>` que
# vincula a crítica ao diff alvo atual (via engrama-diff-hash.sh no local, ou
# via ENGRAMA_DIFF_HASH quando a CI injeta o fingerprint do diff real do PR).
#
# A crítica é feita por um agente/modelo INDEPENDENTE do Orquestrador (o Executor
# no papel de crítica, read-only). O gate exige o REGISTRO da crítica antes do
# commit — ele NÃO prova que um modelo independente de fato a produziu, e é um
# freio COOPERATIVO LOCAL (burlável por --no-verify / fora do harness). A CI
# reexecuta este gate contra o PR (critique-gate-ci.sh), calculando o
# fingerprint sobre o diff real do PR e reusando o repo sintético só para
# classify() + parsing do ledger — ver ADR 0006.
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

extract_sha256_token() {
  local ref_lc="$1"
  ref_lc="$(printf '%s' "$ref_lc" | tr '[:upper:]' '[:lower:]')"
  if [[ "$ref_lc" =~ (^|[[:space:]])(sha256:[0-9a-f]{64})($|[[:space:]]) ]]; then
    printf '%s' "${BASH_REMATCH[2]}"
    return 0
  fi
  return 1
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
    .engrama/VERSION|.engrama/scripts/*.sh|.engrama/githooks/*|.claude/settings.json) addcat gate ;;
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

DIFF_HASH_SCRIPT="$REPO_ROOT/.engrama/scripts/engrama-diff-hash.sh"
if [ ! -f "$DIFF_HASH_SCRIPT" ]; then
  {
    echo "──────────────────────────────────────────────────────────────"
    echo "🚫 GATE DE CRÍTICA — commit BLOQUEADO"
    echo ""
    echo "Script obrigatorio ausente: $DIFF_HASH_SCRIPT"
    echo "Sem a fonte unica do fingerprint do diff, o diff-binding nao e verificavel."
    echo "──────────────────────────────────────────────────────────────"
  } >&2
  exit 2
fi

CURRENT_DIFF_HASH="${ENGRAMA_DIFF_HASH:-}"
if [[ ! "$CURRENT_DIFF_HASH" =~ ^sha256:[0-9a-f]{64}$ ]]; then
  CURRENT_DIFF_HASH="$(bash "$DIFF_HASH_SCRIPT" 2>/dev/null || true)"
fi

if [[ ! "$CURRENT_DIFF_HASH" =~ ^sha256:[0-9a-f]{64}$ ]]; then
  {
    echo "──────────────────────────────────────────────────────────────"
    echo "🚫 GATE DE CRÍTICA — commit BLOQUEADO"
    echo ""
    echo "Fingerprint invalido retornado por engrama-diff-hash.sh:"
    echo "  ${CURRENT_DIFF_HASH:-<vazio>}"
    echo "Esperado: sha256:<64 hex>"
    echo "──────────────────────────────────────────────────────────────"
  } >&2
  exit 2
fi

LEDGER=".engrama/qa/criticas-do-executor.md"
# Versão durável: índice (staged) com fallback p/ HEAD. NÃO usa o working-tree.
LEDGER_CONTENT="$(git show ":$LEDGER" 2>/dev/null || true)"
[ -z "$LEDGER_CONTENT" ] && LEDGER_CONTENT="$(git show "HEAD:$LEDGER" 2>/dev/null || true)"

REQUIRE_DIFF_BIND="${ENGRAMA_REQUIRE_DIFF_BIND:-0}"
MISSING=""
BLOCKED_OBJ=""
STALE_BINDINGS=""
LEGACY_ONLY=""

for cat in $CATS; do
  legacy_ok=""
  legacy_obj=""
  strong_ok=""
  strong_obj=""
  saw_hash=""
  stale_hash=""

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

        entry_hash=""
        if entry_hash="$(extract_sha256_token "$field4")"; then
          saw_hash=1
          if [ "$entry_hash" != "$CURRENT_DIFF_HASH" ]; then
            stale_hash=1
            continue
          fi

          if is_blocking_objection "$field3"; then
            strong_obj=1
          fi

          if is_ok_verdict "$field3"; then
            strong_ok=1
          fi
          continue
        fi

        if is_blocking_objection "$field3"; then
          legacy_obj=1
        fi

        if is_ok_verdict "$field3"; then
          legacy_ok=1
        fi
        ;;
      *)
        ;;
    esac
  done < <(printf '%s\n' "$LEDGER_CONTENT")

  cat_ok=""
  cat_obj=""

  if [ -n "$saw_hash" ]; then
    cat_ok="$strong_ok"
    cat_obj="$strong_obj"
    if [ -n "$stale_hash" ] && [ -z "$strong_ok" ] && [ -z "$strong_obj" ]; then
      STALE_BINDINGS="$STALE_BINDINGS $cat"
    fi
  else
    cat_ok="$legacy_ok"
    cat_obj="$legacy_obj"
    if [ "$REQUIRE_DIFF_BIND" = "1" ] && [ -n "$legacy_ok" ]; then
      LEGACY_ONLY="$LEGACY_ONLY $cat"
    fi
  fi

  if [ "$REQUIRE_DIFF_BIND" = "1" ]; then
    cat_ok="$strong_ok"
    cat_obj="$strong_obj"
  fi

  if [ -n "$cat_obj" ]; then
    BLOCKED_OBJ="$BLOCKED_OBJ $cat"
  fi

  if [ -z "$cat_ok" ] || [ -n "$cat_obj" ]; then
    MISSING="$MISSING $cat"
  fi
done

[ -z "$MISSING" ] && exit 0

{
  echo "──────────────────────────────────────────────────────────────"
  echo "🚫 GATE DE CRÍTICA (ADR 0006 item 7 / ADR 0010) — commit BLOQUEADO"
  echo ""
  echo "Branch: $BRANCH"
  echo "Categorias sensíveis tocadas:$CATS"
  echo "Fingerprint atual: $CURRENT_DIFF_HASH"
  echo "Sem crítica CONCLUÍDA (ou com objeção aberta) para:$MISSING"
  [ -n "$BLOCKED_OBJ" ] && echo "Objeção do Executor SEM waiver registrado:$BLOCKED_OBJ (escale à Autoridade)"
  [ -n "$STALE_BINDINGS" ] && echo "Crítica vinculada a outro diff (sha256 obsoleto):$STALE_BINDINGS"
  if [ "$REQUIRE_DIFF_BIND" = "1" ] && [ -n "$LEGACY_ONLY" ]; then
    echo "Modo estrito ativo: entradas legadas sem sha256 nao satisfazem:$LEGACY_ONLY"
  fi
  [ "$REQUIRE_DIFF_BIND" = "1" ] && echo "Modo estrito ativo: ENGRAMA_REQUIRE_DIFF_BIND=1"
  echo ""
  echo "Para cada categoria acima, em $LEDGER (staged), inclua uma linha com:"
  echo "  a branch '$BRANCH' + a tag [categoria] + veredito (confirmo|ressalvas|N/A:<motivo>|waiver)"
  echo "  e, quando quiser vincular a crítica a ESTE diff, acrescente o token:"
  echo "    $CURRENT_DIFF_HASH"
  echo "Fonte unica do fingerprint:"
  echo "  bash ./.engrama/scripts/engrama-diff-hash.sh"
  echo "Rode a crítica (read-only, modelo independente):"
  echo "  $EXECUTOR_CMD -m $CRITIQUE_MODEL \"<ordem de crítica>\"   (sem auto-aplicar)"
  echo "──────────────────────────────────────────────────────────────"
} >&2
exit 2

# probe sensivel 335e696
