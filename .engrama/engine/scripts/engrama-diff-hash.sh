#!/usr/bin/env bash
set -u

usage() {
  cat <<'EOF'
Uso:
  bash ./.engrama/engine/scripts/engrama-diff-hash.sh
  bash ./.engrama/engine/scripts/engrama-diff-hash.sh --cached
  bash ./.engrama/engine/scripts/engrama-diff-hash.sh --range <gitrange>
  bash ./.engrama/engine/scripts/engrama-diff-hash.sh --range <gitrange> --manifest <arquivo>
  bash ./.engrama/engine/scripts/engrama-diff-hash.sh --cached --include <regra> --exclude <regra>

Imprime um fingerprint estavel do diff alvo, excluindo o ledger
.engrama/evidence/qa/criticas-do-executor.md. Sem flags (ou com --cached),
usa o diff staged; com --range, usa o diff real entre refs git.

Filtros opcionais (opt-in, sem afetar o caminho default):
- --manifest <arquivo>: carrega regras de include (uma por linha; vazio/# ignora).
- --include <regra>: inclui um caminho literal ou um prefixo terminado em /**.
- --exclude <regra>: remove um caminho literal ou um prefixo terminado em /**.
EOF
}

MODE="cached"
GIT_RANGE=""
MANIFEST=""
declare -a INCLUDE_RULES=()
declare -a EXCLUDE_RULES=()

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

add_include_rule() {
  INCLUDE_RULES+=("$1")
}

add_exclude_rule() {
  EXCLUDE_RULES+=("$1")
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --cached)
      MODE="cached"
      ;;
    --range)
      shift
      [ "$#" -gt 0 ] || {
        echo "ERRO: faltou o valor de --range" >&2
        usage >&2
        exit 2
      }
      MODE="range"
      GIT_RANGE="$1"
      ;;
    --manifest)
      shift
      [ "$#" -gt 0 ] || {
        echo "ERRO: faltou o valor de --manifest" >&2
        usage >&2
        exit 2
      }
      MANIFEST="$1"
      ;;
    --include)
      shift
      [ "$#" -gt 0 ] || {
        echo "ERRO: faltou o valor de --include" >&2
        usage >&2
        exit 2
      }
      add_include_rule "$1"
      ;;
    --exclude)
      shift
      [ "$#" -gt 0 ] || {
        echo "ERRO: faltou o valor de --exclude" >&2
        usage >&2
        exit 2
      }
      add_exclude_rule "$1"
      ;;
    *)
      echo "ERRO: argumento desconhecido: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "ERRO: este script precisa rodar dentro de um repo git" >&2
  exit 2
}
cd "$REPO_ROOT" || {
  echo "ERRO: nao consegui acessar a raiz do repo: $REPO_ROOT" >&2
  exit 2
}

sha256_stream() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum
    return
  fi

  if command -v shasum >/dev/null 2>&1; then
    shasum -a 256
    return
  fi

  echo "ERRO: preciso de sha256sum ou shasum -a 256 para calcular o fingerprint" >&2
  exit 2
}

legacy_diff_stream() {
  case "$MODE" in
    cached)
      git diff --cached --raw -z -- . ':(exclude).engrama/evidence/qa/criticas-do-executor.md'
      ;;
    range)
      git diff --raw -z "$GIT_RANGE" -- . ':(exclude).engrama/evidence/qa/criticas-do-executor.md'
      ;;
    *)
      echo "ERRO: modo de diff invalido: $MODE" >&2
      exit 2
      ;;
  esac
}

load_manifest_rules() {
  local manifest_file="$1" line
  [ -f "$manifest_file" ] || {
    echo "ERRO: manifest obrigatorio ausente: $manifest_file" >&2
    exit 2
  }

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    line="$(trim "$line")"
    case "$line" in
      ''|\#*)
        continue
        ;;
      *)
        add_include_rule "$line"
        ;;
    esac
  done < "$manifest_file"
}

matches_rule() {
  local path="$1" rule="$2" prefix
  case "$rule" in
    */\*\*)
      prefix="${rule%/**}"
      case "$path" in
        "$prefix"/*) return 0 ;;
        *) return 1 ;;
      esac
      ;;
    *)
      [ "$path" = "$rule" ]
      ;;
  esac
}

path_matches_any_rule() {
  local path="$1" rule
  shift
  for rule in "$@"; do
    matches_rule "$path" "$rule" && return 0
  done
  return 1
}

path_is_selected() {
  local path="$1"

  if [ "${#INCLUDE_RULES[@]}" -gt 0 ] && ! path_matches_any_rule "$path" "${INCLUDE_RULES[@]}"; then
    return 1
  fi

  if [ "${#EXCLUDE_RULES[@]}" -gt 0 ] && path_matches_any_rule "$path" "${EXCLUDE_RULES[@]}"; then
    return 1
  fi

  return 0
}

filter_raw_stream() {
  local header status_field status_letter path_old path_new selected

  while IFS= read -r -d '' header; do
    status_field="${header##* }"
    status_letter="${status_field%%[0-9]*}"

    IFS= read -r -d '' path_old || path_old=""
    path_new=""
    case "$status_letter" in
      R|C)
        IFS= read -r -d '' path_new || path_new=""
        ;;
      *)
        ;;
    esac

    selected=1
    if ! path_is_selected "$path_old"; then
      selected=0
      if [ -n "$path_new" ] && path_is_selected "$path_new"; then
        selected=1
      fi
    fi

    [ "$selected" -eq 1 ] || continue

    printf '%s\0%s\0' "$header" "$path_old"
    case "$status_letter" in
      R|C)
        printf '%s\0' "$path_new"
        ;;
      *)
        ;;
    esac
  done
}

diff_stream() {
  if [ -n "$MANIFEST" ]; then
    load_manifest_rules "$MANIFEST"
  fi

  if [ "${#INCLUDE_RULES[@]}" -eq 0 ] && [ "${#EXCLUDE_RULES[@]}" -eq 0 ]; then
    legacy_diff_stream
    return
  fi

  legacy_diff_stream | filter_raw_stream
}

DIGEST_LINE="$(
  diff_stream | sha256_stream
)" || exit 2

DIGEST_HEX="$(printf '%s\n' "$DIGEST_LINE" | awk 'NR == 1 { print $1 }')"
[ -n "$DIGEST_HEX" ] || {
  echo "ERRO: nao consegui extrair o digest SHA-256" >&2
  exit 2
}

printf 'sha256:%s\n' "$DIGEST_HEX"
