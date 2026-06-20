#!/usr/bin/env bash
# sync-template.sh -- sincroniza apenas artefatos mecanicos do template a partir
# da raiz canonica do Engrama.
#
# Escopo intencional: scripts do gate/hook. Nao faz reverse-substituicao cega em
# prosa de governanca/READMEs, porque valores livres podem aparecer em texto e a
# operacao seria fragil.
set -eu

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT_GATE="$HERE/.engrama/scripts/critique-gate.sh"
ROOT_HOOK="$HERE/.engrama/scripts/critique-gate-hook.sh"
ROOT_LINT="$HERE/lint.sh"
TEMPLATE_GATE="$HERE/template/.engrama/scripts/critique-gate.sh"
TEMPLATE_HOOK="$HERE/template/.engrama/scripts/critique-gate-hook.sh"
TEMPLATE_LINT="$HERE/template/lint.sh"
TMPDIR_SYNC=""

fail() {
  echo "ERRO: $*" >&2
  exit 1
}

need_file() {
  [ -f "$1" ] || fail "arquivo obrigatorio ausente: $1"
}

section_before_executor_cmd() {
  awk '
    /^EXECUTOR_CMD=/{ exit }
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
EXECUTOR_CMD="{{EXECUTOR_CMD}}"            # ex.: "codex exec"
CRITIQUE_MODEL="{{MODELO_CRITICA}}"        # ex.: "gpt-5.5"
EOF
}

emit_template_gate_classify() {
  cat <<'EOF'
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
    lint.sh) addcat gate ;;
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
EOF
}

write_if_changed() {
  local tmp="$1" dest="$2"
  if [ -f "$dest" ] && cmp -s "$tmp" "$dest"; then
    rm -f "$tmp"
    echo "unchanged: ${dest#"$HERE"/}"
    return 0
  fi

  mv "$tmp" "$dest"
  echo "synced: ${dest#"$HERE"/}"
}

compose_template_gate() {
  local tmpdir="$1" out="$2"

  section_before_executor_cmd "$ROOT_GATE" > "$tmpdir/prefix"
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

main() {
  need_file "$ROOT_GATE"
  need_file "$ROOT_HOOK"
  need_file "$ROOT_LINT"
  need_file "$TEMPLATE_GATE"
  need_file "$TEMPLATE_HOOK"

  TMPDIR_SYNC="$(mktemp -d 2>/dev/null || mktemp -d -t engrama-sync)"
  trap 'rm -rf "${TMPDIR_SYNC:-}"' EXIT

  compose_template_gate "$TMPDIR_SYNC" "$TMPDIR_SYNC/critique-gate.sh"
  cp "$ROOT_HOOK" "$TMPDIR_SYNC/critique-gate-hook.sh"
  cp "$ROOT_LINT" "$TMPDIR_SYNC/lint.sh"

  write_if_changed "$TMPDIR_SYNC/critique-gate.sh" "$TEMPLATE_GATE"
  write_if_changed "$TMPDIR_SYNC/critique-gate-hook.sh" "$TEMPLATE_HOOK"
  write_if_changed "$TMPDIR_SYNC/lint.sh" "$TEMPLATE_LINT"

  chmod +x "$TEMPLATE_GATE" "$TEMPLATE_HOOK" "$TEMPLATE_LINT" 2>/dev/null || true
}

main "$@"
