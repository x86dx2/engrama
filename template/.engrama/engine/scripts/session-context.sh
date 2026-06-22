#!/usr/bin/env bash
# session-context.sh -- auto-surface + lembrete para o inicio/compactacao da sessao.
#
# Honestidade: isto NAO auto-escreve log/ledger. Atualizar .engrama/log.md e
# .engrama/evidence/qa/criticas-do-executor.md continua manual e exige julgamento do
# agente/humano. O papel deste script e so reapresentar contexto factual e
# lembrar o handshake minimo.
set -u

script_dir() {
  local dir
  dir="$(CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null && pwd)" || return 0
  printf '%s' "$dir"
}

repo_root_from_script() {
  local base="$1" root
  root="$(CDPATH='' cd -- "$base/../../.." 2>/dev/null && pwd)" || return 0
  printf '%s' "$root"
}

print_checkpoint() {
  local log_file="$1" checkpoint
  [ -f "$log_file" ] || return 0

  checkpoint="$(
    awk '
      BEGIN { in_block = 0 }
      /^## \[/ {
        if (in_block) {
          exit
        }
        in_block = 1
      }
      in_block { print }
    ' "$log_file" 2>/dev/null || true
  )"

  [ -n "$checkpoint" ] || return 0

  printf 'Checkpoint vivo (.engrama/log.md):\n'
  printf '%s\n' "$checkpoint"
}

print_bootstrap_status() {
  local bootstrap_file="$1" status_line=""
  [ -f "$bootstrap_file" ] || return 0

  status_line="$(grep -m 1 '^[[:space:]]*status:[[:space:]]*' "$bootstrap_file" 2>/dev/null || true)"

  case "$status_line" in
    *proposed*)
      printf 'BOOTSTRAP PENDENTE: .engrama/memory/project/bootstrap-do-projeto.md esta com status proposed.\n'
      return 0
      ;;
    *)
      ;;
  esac

  if grep -q 'TODO' "$bootstrap_file" 2>/dev/null; then
    printf 'BOOTSTRAP PENDENTE: .engrama/memory/project/bootstrap-do-projeto.md ainda tem TODO.\n'
    return 0
  fi

  printf 'Bootstrap: active.\n'
}

print_handshake_reminder() {
  printf 'Handshake: papel · alcada · estado factual · proximo passo seguro · o que depende da Autoridade.\n'
  printf 'Lembrete: auto-surface + lembrete; atualizar log/ledger continua manual.\n'
}

main() {
  local dir="" root="." log_file bootstrap_file

  dir="$(script_dir)"
  if [ -n "$dir" ]; then
    root="$(repo_root_from_script "$dir")"
    [ -n "$root" ] || root="."
  fi

  log_file="$root/.engrama/log.md"
  bootstrap_file="$root/.engrama/memory/project/bootstrap-do-projeto.md"

  print_checkpoint "$log_file"
  print_bootstrap_status "$bootstrap_file"
  print_handshake_reminder
  exit 0
}

main "$@"
