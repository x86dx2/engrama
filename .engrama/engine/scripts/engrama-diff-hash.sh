#!/usr/bin/env bash
set -u

usage() {
  cat <<'EOF'
Uso:
  bash ./.engrama/engine/scripts/engrama-diff-hash.sh
  bash ./.engrama/engine/scripts/engrama-diff-hash.sh --cached
  bash ./.engrama/engine/scripts/engrama-diff-hash.sh --range <gitrange>

Imprime um fingerprint estavel do diff alvo, excluindo o ledger
.engrama/evidence/qa/criticas-do-executor.md. Sem flags (ou com --cached),
usa o diff staged; com --range, usa o diff real entre refs git.
EOF
}

MODE="cached"
GIT_RANGE=""

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

diff_stream() {
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

DIGEST_LINE="$(
  diff_stream | sha256_stream
)" || exit 2

DIGEST_HEX="$(printf '%s\n' "$DIGEST_LINE" | awk 'NR == 1 { print $1 }')"
[ -n "$DIGEST_HEX" ] || {
  echo "ERRO: nao consegui extrair o digest SHA-256" >&2
  exit 2
}

printf 'sha256:%s\n' "$DIGEST_HEX"
