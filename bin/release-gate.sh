#!/usr/bin/env bash
# release-gate repo-central-only.
#
# Regra:
# - payload distribuivel mudou -> exige VERSION+CHANGELOG validos, ou waiver sem-release bound-by-hash
# - release-only (VERSION + CHANGELOG) -> passa
# - nada distribuivel mudou -> passa
set -u

usage() {
  cat <<'EOF'
Uso:
  bash ./bin/release-gate.sh --mode ci --base-ref <gitish>
  bash ./bin/release-gate.sh --mode warn [--base-ref <gitish>]
  bash ./bin/release-gate.sh --print-hash [--base-ref <gitish>]

Saidas:
  0 = passou, warning-only ou skip em --mode warn
  1 = erro de configuracao/entrada
  2 = violacao de policy no modo ci
EOF
}

MODE=""
PRINT_HASH=0
BASE_REF=""
BASE_REF_EXPLICIT=0

MANIFEST_REL=".engrama/release-surface.manifest"
WAIVER_REL=".engrama/evidence/qa/release-waivers.md"
DIFF_HASH_REL=".engrama/engine/scripts/engrama-diff-hash.sh"
VERSION_REL="VERSION"
CHANGELOG_REL="CHANGELOG.md"
SELF_REL="bin/release-gate.sh"

trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

config_fail() {
  echo "release-gate: ERRO: $*" >&2
  exit 1
}

warn_skip() {
  echo "release-gate: WARN: $*" >&2
  exit 0
}

policy_fail() {
  if [ "$MODE" = "ci" ]; then
    echo "release-gate: POLICY: $*" >&2
    exit 2
  fi

  echo "release-gate: WARN: $*" >&2
  exit 0
}

validate_ref() {
  git rev-parse --verify "${1}^{commit}" >/dev/null 2>&1
}

detect_base_ref() {
  local candidate

  candidate="$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [ -n "$candidate" ] && validate_ref "$candidate"; then
    printf '%s\n' "$candidate"
    return 0
  fi

  for candidate in origin/main main origin/master master; do
    if validate_ref "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  candidate="$(git describe --tags --abbrev=0 2>/dev/null || true)"
  if [ -n "$candidate" ] && validate_ref "$candidate"; then
    printf '%s\n' "$candidate"
    return 0
  fi

  return 1
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

  config_fail "preciso de sha256sum ou shasum -a 256"
}

empty_sha256() {
  local digest_line digest_hex
  digest_line="$(printf '' | sha256_stream)" || config_fail "nao consegui calcular o hash vazio"
  digest_hex="$(printf '%s\n' "$digest_line" | awk 'NR == 1 { print $1 }')"
  [ -n "$digest_hex" ] || config_fail "nao consegui extrair o digest do hash vazio"
  printf 'sha256:%s\n' "$digest_hex"
}

touches_path() {
  local range="$1" target="$2" header status_field status_letter old_path new_path

  while IFS= read -r -d '' header; do
    status_field="${header##* }"
    status_letter="${status_field%%[0-9]*}"

    IFS= read -r -d '' old_path || old_path=""
    new_path=""
    case "$status_letter" in
      R|C)
        IFS= read -r -d '' new_path || new_path=""
        ;;
      *)
        ;;
    esac

    if [ "$old_path" = "$target" ] || [ "$new_path" = "$target" ]; then
      return 0
    fi
  done < <(git diff --raw -z "$range")

  return 1
}

read_current_version() {
  local version
  [ -f "$VERSION_REL" ] || config_fail "arquivo obrigatorio ausente: $VERSION_REL"
  version="$(sed -n '1{s/\r$//;p;q;}' "$VERSION_REL" 2>/dev/null || true)"
  version="$(trim "$version")"
  [ -n "$version" ] || config_fail "VERSION vazio"
  printf '%s\n' "$version"
}

has_valid_current_changelog_heading() {
  local version="$1" line first_version_heading=""

  [ -f "$CHANGELOG_REL" ] || config_fail "arquivo obrigatorio ausente: $CHANGELOG_REL"

  while IFS= read -r line || [ -n "$line" ]; do
    line="${line%$'\r'}"
    case "$line" in
      '## [Não lançado]'|'## [Nao lancado]'|'## [Nao lançado]')
        continue
        ;;
      '## ['*)
        first_version_heading="$line"
        break
        ;;
      *)
        ;;
    esac
  done < "$CHANGELOG_REL"

  [ -n "$first_version_heading" ] || return 1

  case "$first_version_heading" in
    "## [$version] - "????-??-??)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

has_valid_release_waiver() {
  local wanted_hash="$1" line rest field2 field3

  [ -f "$WAIVER_REL" ] || return 1

  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      '## ['*)
        rest="$line"
        case "$rest" in
          *'|'*)
            rest="${rest#*|}"
            ;;
          *)
            continue
            ;;
        esac

        case "$rest" in
          *'|'*)
            field2="${rest%%|*}"
            rest="${rest#*|}"
            ;;
          *)
            continue
            ;;
        esac

        case "$rest" in
          *'|'*)
            field3="${rest%%|*}"
            ;;
          *)
            continue
            ;;
        esac

        field2="$(trim "${field2:-}")"
        field3="$(trim "${field3:-}")"

        [ "$field2" = "sem-release" ] || continue
        [ "$field3" = "$wanted_hash" ] || continue
        return 0
        ;;
      *)
        ;;
    esac
  done < "$WAIVER_REL"

  return 1
}

print_payload_hash() {
  local range="$1" payload_hash

  payload_hash="$(
    bash "$DIFF_HASH_REL" \
      --range "$range" \
      --manifest "$MANIFEST_REL" \
      --exclude "$VERSION_REL" \
      --exclude "$CHANGELOG_REL" \
      --exclude "$WAIVER_REL" \
      --exclude "$SELF_REL"
  )" || config_fail "nao consegui calcular o hash do payload"

  case "$payload_hash" in
    sha256:[0-9a-f][0-9a-f]*)
      ;;
    *)
      config_fail "hash do payload invalido: ${payload_hash:-<vazio>}"
      ;;
  esac

  printf '%s\n' "$payload_hash"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode)
      shift
      [ "$#" -gt 0 ] || config_fail "faltou valor para --mode"
      MODE="$1"
      ;;
    --base-ref)
      shift
      [ "$#" -gt 0 ] || config_fail "faltou valor para --base-ref"
      BASE_REF="$1"
      BASE_REF_EXPLICIT=1
      ;;
    --print-hash)
      PRINT_HASH=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      config_fail "argumento desconhecido: $1"
      ;;
  esac
  shift
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || config_fail "este script precisa rodar dentro de um repo git"
cd "$REPO_ROOT" || config_fail "nao consegui acessar a raiz do repo: $REPO_ROOT"

[ -f "$MANIFEST_REL" ] || config_fail "manifest obrigatorio ausente: $MANIFEST_REL"
[ -f "$DIFF_HASH_REL" ] || config_fail "script obrigatorio ausente: $DIFF_HASH_REL"

if [ "$PRINT_HASH" -ne 1 ]; then
  case "$MODE" in
    ci|warn)
      ;;
    *)
      config_fail "use --mode ci|warn, ou --print-hash"
      ;;
  esac
fi

if [ "$MODE" = "ci" ] && [ "$BASE_REF_EXPLICIT" -ne 1 ]; then
  config_fail "--mode ci exige --base-ref explicito"
fi

if [ -n "$BASE_REF" ]; then
  validate_ref "$BASE_REF" || config_fail "base-ref invalida: $BASE_REF"
else
  BASE_REF="$(detect_base_ref || true)"
fi

if [ -z "$BASE_REF" ]; then
  if [ "$PRINT_HASH" -eq 1 ]; then
    config_fail "nao consegui determinar a base para --print-hash"
  fi

  warn_skip "nao encontrei base branch nem tag; pulando em --mode warn"
fi

RANGE="$BASE_REF...HEAD"
EMPTY_PAYLOAD_HASH="$(empty_sha256)"
PAYLOAD_HASH="$(print_payload_hash "$RANGE")"

if [ "$PRINT_HASH" -eq 1 ]; then
  printf '%s\n' "$PAYLOAD_HASH"
  exit 0
fi

PAYLOAD_CHANGED=0
if [ "$PAYLOAD_HASH" != "$EMPTY_PAYLOAD_HASH" ]; then
  PAYLOAD_CHANGED=1
fi

VERSION_CHANGED=0
if touches_path "$RANGE" "$VERSION_REL"; then
  VERSION_CHANGED=1
fi

CURRENT_VERSION="$(read_current_version)"
CHANGELOG_OK=0
if has_valid_current_changelog_heading "$CURRENT_VERSION"; then
  CHANGELOG_OK=1
fi

WAIVER_OK=0
if has_valid_release_waiver "$PAYLOAD_HASH"; then
  WAIVER_OK=1
fi

if [ "$PAYLOAD_CHANGED" -eq 0 ]; then
  if [ "$VERSION_CHANGED" -eq 1 ] && [ "$CHANGELOG_OK" -ne 1 ]; then
    policy_fail "VERSION mudou, mas o primeiro heading versionado de CHANGELOG.md nao corresponde a [$CURRENT_VERSION] - YYYY-MM-DD"
  fi
  exit 0
fi

if [ "$VERSION_CHANGED" -eq 1 ] && [ "$CHANGELOG_OK" -eq 1 ]; then
  exit 0
fi

if [ "$VERSION_CHANGED" -eq 0 ] && [ "$WAIVER_OK" -eq 1 ]; then
  exit 0
fi

if [ "$VERSION_CHANGED" -eq 1 ] && [ "$CHANGELOG_OK" -ne 1 ]; then
  policy_fail "payload distribuivel mudou e VERSION mudou sem heading valido em CHANGELOG.md para $CURRENT_VERSION"
fi

if [ "$WAIVER_OK" -ne 1 ]; then
  policy_fail "payload distribuivel mudou sem bump de VERSION + CHANGELOG valido e sem waiver sem-release com hash atual ($PAYLOAD_HASH)"
fi

policy_fail "payload distribuivel mudou sem release valido"
