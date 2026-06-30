#!/usr/bin/env bash
# sync-template.sh -- sincroniza artefatos mecanicos do template a partir da
# raiz canonica do Engrama.
#
# Escopo intencional: scripts do harness/gate/bridge e settings mecanicos. Nao faz
# reverse-substituicao cega em prosa de governanca/READMEs, porque valores
# livres podem aparecer em texto e a operacao seria fragil.
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HERE/.." && pwd)"
ROOT_GATE="$REPO_ROOT/.engrama/engine/scripts/critique-gate.sh"
ROOT_HOOK="$REPO_ROOT/.engrama/engine/scripts/critique-gate-hook.sh"
ROOT_SESSION_CONTEXT="$REPO_ROOT/.engrama/engine/scripts/session-context.sh"
ROOT_LINT="$REPO_ROOT/.engrama/engine/scripts/lint.sh"
ROOT_DIFF_HASH="$REPO_ROOT/.engrama/engine/scripts/engrama-diff-hash.sh"
ROOT_EXEC_BRIDGE="$REPO_ROOT/.engrama/engine/scripts/exec-bridge.sh"
ROOT_MODEL_ROUTER="$REPO_ROOT/.engrama/engine/scripts/model-router.sh"
ROOT_USAGE_REPORT="$REPO_ROOT/.engrama/engine/scripts/usage-report.sh"
ROOT_CI_GATE="$REPO_ROOT/.engrama/engine/scripts/critique-gate-ci.sh"
ROOT_CODEX_ADAPTER="$REPO_ROOT/.engrama/engine/adapters/codex.sh"
ROOT_MODELS_CONF="$REPO_ROOT/.engrama/engine/config/models.conf"
ROOT_SUBSCRIPTIONS_CONF="$REPO_ROOT/.engrama/engine/config/subscriptions.conf"
ROOT_PRICES_CONF="$REPO_ROOT/.engrama/engine/config/prices.conf"
ROOT_MARKDOWNLINT="$REPO_ROOT/.markdownlint-cli2.yaml"
ROOT_SETTINGS="$REPO_ROOT/.claude/settings.json"
TEMPLATE_GATE="$REPO_ROOT/template/.engrama/engine/scripts/critique-gate.sh"
TEMPLATE_HOOK="$REPO_ROOT/template/.engrama/engine/scripts/critique-gate-hook.sh"
TEMPLATE_SESSION_CONTEXT="$REPO_ROOT/template/.engrama/engine/scripts/session-context.sh"
TEMPLATE_LINT="$REPO_ROOT/template/.engrama/engine/scripts/lint.sh"
TEMPLATE_DIFF_HASH="$REPO_ROOT/template/.engrama/engine/scripts/engrama-diff-hash.sh"
TEMPLATE_EXEC_BRIDGE="$REPO_ROOT/template/.engrama/engine/scripts/exec-bridge.sh"
TEMPLATE_MODEL_ROUTER="$REPO_ROOT/template/.engrama/engine/scripts/model-router.sh"
TEMPLATE_USAGE_REPORT="$REPO_ROOT/template/.engrama/engine/scripts/usage-report.sh"
TEMPLATE_CI_GATE="$REPO_ROOT/template/.engrama/engine/scripts/critique-gate-ci.sh"
TEMPLATE_CODEX_ADAPTER="$REPO_ROOT/template/.engrama/engine/adapters/codex.sh"
TEMPLATE_MODELS_CONF="$REPO_ROOT/template/.engrama/engine/config/models.conf"
TEMPLATE_SUBSCRIPTIONS_CONF="$REPO_ROOT/template/.engrama/engine/config/subscriptions.conf"
TEMPLATE_PRICES_CONF="$REPO_ROOT/template/.engrama/engine/config/prices.conf"
TEMPLATE_MARKDOWNLINT="$REPO_ROOT/template/.markdownlint-cli2.yaml"
TEMPLATE_SETTINGS="$REPO_ROOT/template/.claude/settings.json"
TMPDIR_SYNC=""

fail() {
  echo "ERRO: $*" >&2
  exit 1
}

need_file() {
  [ -f "$1" ] || fail "arquivo obrigatorio ausente: $1"
}

section_before_critique_route() {
  awk '
    /^CRITIQUE_ROLE=/{ exit }
    { print }
  ' "$1"
}

section_between_repo_root_and_classify_comment() {
  awk '
    BEGIN { emit = 0 }
    /^REPO_ROOT=/{ emit = 1 }
    /CONFIG DO PROJETO:/{ exit }
    emit { print }
  ' "$1"
}

section_after_classify() {
  awk '
    BEGIN { emit = 0 }
    /^while IFS= read -r /{ emit = 1 }
    emit { print }
  ' "$1"
}

emit_template_gate_vars() {
  cat <<'EOF'
CRITIQUE_ROLE="critique"
CRITIQUE_TIER="T4"
EOF
}

emit_template_gate_classify() {
  cat <<'EOF'
# ── CONFIG DO PROJETO: arquivo → categoria(s) ─────────────────────────────────
# Categorias OK: financial · rbac · auth · schema · governance · gate · contract.
# Mapear as superficies sensiveis do SEU dominio neste `case` e OBRIGATORIO
# antes do 1o commit de codigo de dominio. O que NAO entrar aqui passa SEM
# revisao por este gate. governance/gate/contract sao universais; o resto e
# ilustrativo e deve ser trocado pelos caminhos reais do seu projeto.
classify() {
  local f="$1"
  case "$f" in
    # --- Universais (nao remova) ---
    AGENTS.md|CLAUDE.md) addcat governance ;;
    .engrama/CLAUDE.md|.engrama/index.md|.engrama/log.md) addcat governance ;;
    .engrama/memory/governance/*|.engrama/memory/decisions/*|.engrama/memory/specs/*|.engrama/memory/project/*|.engrama/evidence/qa/*) addcat governance ;;
    .engrama/memory/gaps/*|.engrama/memory/roadmap/*|.engrama/memory/domain/*|.engrama/memory/workflows/*) addcat governance ;;
    .engrama/VERSION|.engrama/engine/scripts/*.sh|.engrama/engine/adapters/*.sh|.engrama/engine/config/*.conf|.engrama/engine/githooks/*|.claude/settings.json) addcat gate ;;
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
EOF
}

write_if_changed() {
  local tmp="$1" dest="$2"
  mkdir -p "$(dirname "$dest")"
  if [ -f "$dest" ] && cmp -s "$tmp" "$dest"; then
    rm -f "$tmp"
    echo "unchanged: ${dest#"$REPO_ROOT"/}"
    return 0
  fi

  mv "$tmp" "$dest"
  echo "synced: ${dest#"$REPO_ROOT"/}"
}

compose_template_gate() {
  local tmpdir="$1" out="$2"

  section_before_critique_route "$ROOT_GATE" > "$tmpdir/prefix"
  section_between_repo_root_and_classify_comment "$ROOT_GATE" > "$tmpdir/middle"
  section_after_classify "$ROOT_GATE" > "$tmpdir/tail"

  [ -s "$tmpdir/prefix" ] || fail "nao consegui extrair o prefixo do gate da raiz"
  [ -s "$tmpdir/middle" ] || fail "nao consegui extrair a logica intermediaria do gate da raiz"
  [ -s "$tmpdir/tail" ] || fail "nao consegui extrair a cauda do gate da raiz"

  {
    cat "$tmpdir/prefix"
    emit_template_gate_vars
    cat "$tmpdir/middle"
    emit_template_gate_classify
    cat "$tmpdir/tail"
  } > "$out"
}

compose_template_models_conf() {
  local out="$1"
  sed \
    -e 's/^ENGRAMA_T1_MODEL=.*/ENGRAMA_T1_MODEL={{MODELO_EXECUTOR_LEVE}}/' \
    -e 's/^ENGRAMA_T2_MODEL=.*/ENGRAMA_T2_MODEL={{MODELO_EXECUTOR_PESADO}}/' \
    -e 's/^ENGRAMA_T3_MODEL=.*/ENGRAMA_T3_MODEL={{MODELO_EXECUTOR_PESADO}}/' \
    -e 's/^ENGRAMA_T4_MODEL=.*/ENGRAMA_T4_MODEL={{MODELO_CRITICA}}/' \
    -e 's/^ENGRAMA_T4_PLUS_MODEL=.*/ENGRAMA_T4_PLUS_MODEL={{MODELO_CRITICA}}/' \
    "$ROOT_MODELS_CONF" > "$out"
}

compose_template_subscriptions_conf() {
  local out="$1"
  sed \
    -e 's/^ENGRAMA_CODEX_PRO_ENABLED=.*/ENGRAMA_CODEX_PRO_ENABLED=0/' \
    -e 's/^ENGRAMA_CODEX_PRO_MONTHLY_USD=.*/ENGRAMA_CODEX_PRO_MONTHLY_USD=/' \
    -e 's/^ENGRAMA_CLAUDE_MAX_ENABLED=.*/ENGRAMA_CLAUDE_MAX_ENABLED=0/' \
    -e 's/^ENGRAMA_CLAUDE_MAX_MONTHLY_USD=.*/ENGRAMA_CLAUDE_MAX_MONTHLY_USD=/' \
    "$ROOT_SUBSCRIPTIONS_CONF" > "$out"
}

main() {
  need_file "$ROOT_GATE"
  need_file "$ROOT_HOOK"
  need_file "$ROOT_SESSION_CONTEXT"
  need_file "$ROOT_LINT"
  need_file "$ROOT_DIFF_HASH"
  need_file "$ROOT_EXEC_BRIDGE"
  need_file "$ROOT_MODEL_ROUTER"
  need_file "$ROOT_USAGE_REPORT"
  need_file "$ROOT_CI_GATE"
  need_file "$ROOT_CODEX_ADAPTER"
  need_file "$ROOT_MODELS_CONF"
  need_file "$ROOT_SUBSCRIPTIONS_CONF"
  need_file "$ROOT_PRICES_CONF"
  need_file "$ROOT_MARKDOWNLINT"
  need_file "$ROOT_SETTINGS"
  need_file "$TEMPLATE_GATE"
  need_file "$TEMPLATE_HOOK"
  need_file "$TEMPLATE_SESSION_CONTEXT"
  need_file "$TEMPLATE_LINT"
  need_file "$TEMPLATE_DIFF_HASH"
  need_file "$TEMPLATE_EXEC_BRIDGE"
  need_file "$TEMPLATE_CI_GATE"
  need_file "$TEMPLATE_MARKDOWNLINT"
  need_file "$TEMPLATE_SETTINGS"

  TMPDIR_SYNC="$(mktemp -d 2>/dev/null || mktemp -d -t engrama-sync)"
  trap 'rm -rf "${TMPDIR_SYNC:-}"' EXIT

  compose_template_gate "$TMPDIR_SYNC" "$TMPDIR_SYNC/critique-gate.sh"
  cp "$ROOT_HOOK" "$TMPDIR_SYNC/critique-gate-hook.sh"
  cp "$ROOT_SESSION_CONTEXT" "$TMPDIR_SYNC/session-context.sh"
  cp "$ROOT_LINT" "$TMPDIR_SYNC/lint.sh"
  cp "$ROOT_DIFF_HASH" "$TMPDIR_SYNC/engrama-diff-hash.sh"
  cp "$ROOT_EXEC_BRIDGE" "$TMPDIR_SYNC/exec-bridge.sh"
  cp "$ROOT_MODEL_ROUTER" "$TMPDIR_SYNC/model-router.sh"
  cp "$ROOT_USAGE_REPORT" "$TMPDIR_SYNC/usage-report.sh"
  cp "$ROOT_CI_GATE" "$TMPDIR_SYNC/critique-gate-ci.sh"
  cp "$ROOT_CODEX_ADAPTER" "$TMPDIR_SYNC/codex.sh"
  compose_template_models_conf "$TMPDIR_SYNC/models.conf"
  compose_template_subscriptions_conf "$TMPDIR_SYNC/subscriptions.conf"
  cp "$ROOT_PRICES_CONF" "$TMPDIR_SYNC/prices.conf"
  cp "$ROOT_MARKDOWNLINT" "$TMPDIR_SYNC/markdownlint-cli2.yaml"
  cp "$ROOT_SETTINGS" "$TMPDIR_SYNC/settings.json"

  write_if_changed "$TMPDIR_SYNC/critique-gate.sh" "$TEMPLATE_GATE"
  write_if_changed "$TMPDIR_SYNC/critique-gate-hook.sh" "$TEMPLATE_HOOK"
  write_if_changed "$TMPDIR_SYNC/session-context.sh" "$TEMPLATE_SESSION_CONTEXT"
  write_if_changed "$TMPDIR_SYNC/lint.sh" "$TEMPLATE_LINT"
  write_if_changed "$TMPDIR_SYNC/engrama-diff-hash.sh" "$TEMPLATE_DIFF_HASH"
  write_if_changed "$TMPDIR_SYNC/exec-bridge.sh" "$TEMPLATE_EXEC_BRIDGE"
  write_if_changed "$TMPDIR_SYNC/model-router.sh" "$TEMPLATE_MODEL_ROUTER"
  write_if_changed "$TMPDIR_SYNC/usage-report.sh" "$TEMPLATE_USAGE_REPORT"
  write_if_changed "$TMPDIR_SYNC/critique-gate-ci.sh" "$TEMPLATE_CI_GATE"
  write_if_changed "$TMPDIR_SYNC/codex.sh" "$TEMPLATE_CODEX_ADAPTER"
  write_if_changed "$TMPDIR_SYNC/models.conf" "$TEMPLATE_MODELS_CONF"
  write_if_changed "$TMPDIR_SYNC/subscriptions.conf" "$TEMPLATE_SUBSCRIPTIONS_CONF"
  write_if_changed "$TMPDIR_SYNC/prices.conf" "$TEMPLATE_PRICES_CONF"
  write_if_changed "$TMPDIR_SYNC/markdownlint-cli2.yaml" "$TEMPLATE_MARKDOWNLINT"
  write_if_changed "$TMPDIR_SYNC/settings.json" "$TEMPLATE_SETTINGS"

  chmod +x "$TEMPLATE_GATE" "$TEMPLATE_HOOK" "$TEMPLATE_SESSION_CONTEXT" "$TEMPLATE_LINT" "$TEMPLATE_DIFF_HASH" "$TEMPLATE_EXEC_BRIDGE" "$TEMPLATE_MODEL_ROUTER" "$TEMPLATE_USAGE_REPORT" "$TEMPLATE_CI_GATE" "$TEMPLATE_CODEX_ADAPTER" 2>/dev/null || true
}

main "$@"
