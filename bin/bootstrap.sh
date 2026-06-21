#!/usr/bin/env bash
# bootstrap.sh — instala o Engrama diretamente em um repo-alvo.
# Cria/inicializa o repo se necessário, infere defaults e delega a cópia
# mecânica ao bin/install.sh.
set -eu

usage() {
  cat <<'EOF'
Uso:
  bash ./bin/bootstrap.sh /caminho/do/projeto [/caminho/do/override.values]

Fluxo:
  1. cria o diretório-alvo se não existir;
  2. inicializa git se o repo ainda não existir;
  3. infere defaults do Engrama a partir do projeto;
  4. instala CLAUDE.md, AGENTS.md e .engrama/ na raiz do projeto.

O arquivo override.values é opcional e serve apenas para sobrescrever defaults.
EOF
}

HERE="$(cd "$(dirname "$0")" && pwd)"
INSTALLER="$HERE/install.sh"

case "${1:-}" in
  -h|--help|"")
    usage
    exit 0
    ;;
esac

TARGET_DIR="$1"
OVERRIDES="${2:-}"

mkdir -p "$TARGET_DIR"

if ! git -C "$TARGET_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
  git -C "$TARGET_DIR" init -b main >/dev/null
fi

ROOT="$(git -C "$TARGET_DIR" rev-parse --show-toplevel)"

infer_project() {
  basename "$ROOT"
}

infer_stack() {
  if [ -f "$ROOT/package.json" ]; then
    echo "Node.js (confirmar stack concreta)"
    return
  fi
  if [ -f "$ROOT/go.mod" ]; then
    echo "Go (confirmar stack concreta)"
    return
  fi
  if [ -f "$ROOT/pyproject.toml" ] || [ -f "$ROOT/requirements.txt" ]; then
    echo "Python (confirmar stack concreta)"
    return
  fi
  if [ -f "$ROOT/Cargo.toml" ]; then
    echo "Rust (confirmar stack concreta)"
    return
  fi
  if [ -f "$ROOT/pom.xml" ] || [ -f "$ROOT/build.gradle" ] || [ -f "$ROOT/build.gradle.kts" ]; then
    echo "JVM (confirmar stack concreta)"
    return
  fi
  if find "$ROOT" -maxdepth 1 -type f \( -name '*.xlsx' -o -name '*.xls' -o -name '*.csv' -o -name '*.tsv' \) | grep -q .; then
    echo "Spreadsheet (.xlsx/.xls/.csv/.tsv)"
    return
  fi
  echo "preencher (inferir stack do projeto)"
}

infer_authority() {
  local email
  email="$(git -C "$ROOT" config user.email 2>/dev/null || git config --global user.email 2>/dev/null || true)"
  if [ -n "$email" ]; then
    echo "Humano ($email)"
    return
  fi
  echo "Humano (preencher)"
}

infer_dev_url() {
  local guess
  guess="$(rg -o --no-filename --max-count 1 'localhost:[0-9]+' "$ROOT" \
    -g 'package.json' -g '*.md' -g '.env*' -g '*.json' 2>/dev/null || true)"
  if [ -n "$guess" ]; then
    echo "$guess"
    return
  fi
  if [ -f "$ROOT/package.json" ]; then
    echo "localhost:3000 (confirmar)"
    return
  fi
  echo "N/A (sem servidor local)"
}

infer_script_runner() {
  if [ -f "$ROOT/pnpm-lock.yaml" ]; then
    echo "pnpm"
    return
  fi
  if [ -f "$ROOT/yarn.lock" ]; then
    echo "yarn"
    return
  fi
  if [ -f "$ROOT/bun.lockb" ] || [ -f "$ROOT/bun.lock" ]; then
    echo "bun"
    return
  fi
  echo "npm run"
}

infer_package_script() {
  local script_name="$1"
  local runner="$2"
  [ -f "$ROOT/package.json" ] || { echo "N/A"; return; }

  if jq -e --arg s "$script_name" '.scripts[$s] != null' "$ROOT/package.json" >/dev/null 2>&1; then
    case "$runner" in
      "npm run") echo "npm run $script_name" ;;
      *) echo "$runner $script_name" ;;
    esac
    return
  fi

  echo "N/A"
}

apply_overrides() {
  local values_file="$1"
  [ -f "$values_file" ] || { echo "ERRO: override não encontrado: $values_file"; exit 1; }

  while IFS='=' read -r key val || [ -n "${key:-}" ]; do
    key="$(printf '%s' "${key:-}" | tr -d '[:space:]')"
    case "$key" in ''|\#*) continue;; esac
    val="${val%$'\r'}"
    case "$key" in
      PROJETO) PROJETO="$val" ;;
      REPO_PATH) REPO_PATH="$val" ;;
      ORQUESTRADOR) ORQUESTRADOR="$val" ;;
      AUTORIDADE) AUTORIDADE="$val" ;;
      DATA) DATA="$val" ;;
      FINALIDADE_DO_PROJETO) FINALIDADE_DO_PROJETO="$val" ;;
      STACK) STACK="$val" ;;
      DEV_URL) DEV_URL="$val" ;;
      CMD_DEV) CMD_DEV="$val" ;;
      CMD_BUILD) CMD_BUILD="$val" ;;
      CMD_TEST) CMD_TEST="$val" ;;
      CMD_E2E) CMD_E2E="$val" ;;
      EXECUTOR) EXECUTOR="$val" ;;
      EXECUTOR_CMD) EXECUTOR_CMD="$val" ;;
      MODELO_CRITICA) MODELO_CRITICA="$val" ;;
      MODELO_EXECUTOR_PESADO) MODELO_EXECUTOR_PESADO="$val" ;;
      MODELO_EXECUTOR_LEVE) MODELO_EXECUTOR_LEVE="$val" ;;
      *) : ;;
    esac
  done < "$values_file"
}

PROJETO="$(infer_project)"
REPO_PATH="$ROOT"
ORQUESTRADOR="${ENGRAMA_ORQUESTRADOR:-Claude (Claude Code)}"
AUTORIDADE="$(infer_authority)"
DATA="${ENGRAMA_DATA:-$(date +%F)}"
FINALIDADE_DO_PROJETO="${ENGRAMA_FINALIDADE_DO_PROJETO:-TODO: confirmar com a Autoridade na primeira abertura}"
STACK="$(infer_stack)"
DEV_URL="$(infer_dev_url)"
SCRIPT_RUNNER="$(infer_script_runner)"
CMD_DEV="${ENGRAMA_CMD_DEV:-$(infer_package_script dev "$SCRIPT_RUNNER")}"
CMD_BUILD="${ENGRAMA_CMD_BUILD:-$(infer_package_script build "$SCRIPT_RUNNER")}"
CMD_TEST="${ENGRAMA_CMD_TEST:-$(infer_package_script test "$SCRIPT_RUNNER")}"
CMD_E2E="${ENGRAMA_CMD_E2E:-$(infer_package_script e2e "$SCRIPT_RUNNER")}"
EXECUTOR="${ENGRAMA_EXECUTOR:-Codex}"
EXECUTOR_CMD="${ENGRAMA_EXECUTOR_CMD:-codex exec}"
MODELO_CRITICA="${ENGRAMA_MODELO_CRITICA:-gpt-5.5}"
MODELO_EXECUTOR_PESADO="${ENGRAMA_MODELO_EXECUTOR_PESADO:-gpt-5.4}"
MODELO_EXECUTOR_LEVE="${ENGRAMA_MODELO_EXECUTOR_LEVE:-gpt-5.4-mini}"

if [ -n "$OVERRIDES" ]; then
  apply_overrides "$OVERRIDES"
fi

VALUES_TMP="$(mktemp)"
trap 'rm -f "$VALUES_TMP"' EXIT

cat > "$VALUES_TMP" <<EOF
PROJETO=$PROJETO
REPO_PATH=$REPO_PATH
ORQUESTRADOR=$ORQUESTRADOR
AUTORIDADE=$AUTORIDADE
DATA=$DATA
FINALIDADE_DO_PROJETO=$FINALIDADE_DO_PROJETO
STACK=$STACK
DEV_URL=$DEV_URL
CMD_DEV=$CMD_DEV
CMD_BUILD=$CMD_BUILD
CMD_TEST=$CMD_TEST
CMD_E2E=$CMD_E2E
EXECUTOR=$EXECUTOR
EXECUTOR_CMD=$EXECUTOR_CMD
MODELO_CRITICA=$MODELO_CRITICA
MODELO_EXECUTOR_PESADO=$MODELO_EXECUTOR_PESADO
MODELO_EXECUTOR_LEVE=$MODELO_EXECUTOR_LEVE
EOF

bash "$INSTALLER" "$ROOT" "$VALUES_TMP"

cat <<EOF

Bootstrap concluído com os defaults:
- PROJETO=$PROJETO
- REPO_PATH=$REPO_PATH
- ORQUESTRADOR=$ORQUESTRADOR
- AUTORIDADE=$AUTORIDADE
- DATA=$DATA
- FINALIDADE_DO_PROJETO=$FINALIDADE_DO_PROJETO
- STACK=$STACK
- DEV_URL=$DEV_URL
- CMD_DEV=$CMD_DEV
- CMD_BUILD=$CMD_BUILD
- CMD_TEST=$CMD_TEST
- CMD_E2E=$CMD_E2E
- EXECUTOR=$EXECUTOR
- EXECUTOR_CMD=$EXECUTOR_CMD
- MODELO_CRITICA=$MODELO_CRITICA
- MODELO_EXECUTOR_PESADO=$MODELO_EXECUTOR_PESADO
- MODELO_EXECUTOR_LEVE=$MODELO_EXECUTOR_LEVE

Próximo passo:
- adaptar .engrama/scripts/critique-gate.sh ao domínio do projeto;
- registrar crítica do Executor + log + aprovação da Autoridade antes do 1º commit.
EOF
