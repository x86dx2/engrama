#!/usr/bin/env bash
set -u

REPORT_ONLY=0

usage() {
  cat <<'EOF'
Uso: bash lint.sh [--report]

Valida a saude mecanica do Engrama:
- wikilinks em .engrama/**/*.md e na raiz (CLAUDE.md / AGENTS.md)
- source_refs no frontmatter
- frontmatter minimo nas areas obrigatorias
- ADR superseded sem ponteiro para substituta
EOF
}

case "${1:-}" in
  "")
    ;;
  --report)
    REPORT_ONLY=1
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  *)
    echo "ERRO: argumento desconhecido: $1" >&2
    usage >&2
    exit 2
    ;;
esac

ROOT="$(
  CDPATH='' cd -- "$(dirname -- "$0")" && pwd
)"
TMP_REPORT="$(mktemp 2>/dev/null || mktemp -t engrama-lint)"
trap 'rm -f "$TMP_REPORT"' EXIT
ERRORS=0

trim() {
  local s="${1-}"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

strip_quotes() {
  local s="$1"
  case "$s" in
    \"*\")
      s="${s#\"}"
      s="${s%\"}"
      ;;
    \'*\')
      s="${s#\'}"
      s="${s%\'}"
      ;;
  esac
  printf '%s' "$s"
}

report_problem() {
  local file="$1" line="$2" message="$3"
  printf '%s:%s: %s\n' "$file" "$line" "$message" >> "$TMP_REPORT"
  ERRORS=$((ERRORS + 1))
}

requires_frontmatter() {
  local file="$1" base
  case "$file" in
    .engrama/decisions/*|.engrama/governance/*|.engrama/specs/*|.engrama/gaps/*|.engrama/project/*|.engrama/qa/*)
      base="$(basename "$file")"
      [ "$base" = "index.md" ] && return 1
      [ "$base" = "log.md" ] && return 1
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

resolve_wikilink_target() {
  local slug="$1"
  slug="${slug%%|*}"
  slug="${slug%%#*}"
  slug="$(trim "$slug")"
  slug="${slug%.md}"
  [ -n "$slug" ] || return 1
  printf '%s/.engrama/%s.md' "$ROOT" "$slug"
}

frontmatter_reset() {
  FRONTMATTER_PRESENT=0
  FRONTMATTER_CLOSED=0
  FRONTMATTER_END_LINE=0
  FRONTMATTER_TYPE_VALUE=""
  FRONTMATTER_STATUS_LINE=0
  FRONTMATTER_STATUS_VALUE=""
  FRONTMATTER_DATE_VALUE=""
  SOURCE_REFS_DATA=""
}

parse_frontmatter() {
  local file="$1" line line_no=0 source_refs_mode=0 trimmed value

  frontmatter_reset

  while IFS= read -r line || [ -n "$line" ]; do
    line_no=$((line_no + 1))

    if [ "$line_no" -eq 1 ]; then
      if [ "$line" = "---" ]; then
        FRONTMATTER_PRESENT=1
        continue
      fi
      break
    fi

    [ "$FRONTMATTER_PRESENT" -eq 1 ] || break

    if [ "$line" = "---" ]; then
      FRONTMATTER_CLOSED=1
      FRONTMATTER_END_LINE="$line_no"
      break
    fi

    trimmed="$(trim "$line")"

    case "$trimmed" in
      type:*)
        value="$(trim "${trimmed#type:}")"
        if [ -n "$value" ]; then
          FRONTMATTER_TYPE_VALUE="$value"
        fi
        source_refs_mode=0
        ;;
      status:*)
        value="$(trim "${trimmed#status:}")"
        if [ -n "$value" ]; then
          FRONTMATTER_STATUS_LINE="$line_no"
          FRONTMATTER_STATUS_VALUE="$value"
        fi
        source_refs_mode=0
        ;;
      date:*)
        value="$(trim "${trimmed#date:}")"
        if [ -n "$value" ]; then
          FRONTMATTER_DATE_VALUE="$value"
        fi
        source_refs_mode=0
        ;;
      source_refs:*)
        source_refs_mode=1
        ;;
      -\ *)
        if [ "$source_refs_mode" -eq 1 ]; then
          value="$(trim "${trimmed#- }")"
          SOURCE_REFS_DATA="${SOURCE_REFS_DATA}${line_no}	${value}
"
        fi
        ;;
      "")
        ;;
      *)
        source_refs_mode=0
        ;;
    esac
  done < "$file"
}

check_wikilinks() {
  local file="$1" line_no slug target

  while IFS=: read -r line_no slug; do
    [ -n "${line_no:-}" ] || continue
    target="$(resolve_wikilink_target "$slug")" || continue
    if [ ! -e "$target" ]; then
      report_problem "$file" "$line_no" "wikilink orfao: [[${slug}]] -> ${target#"$ROOT"/}"
    fi
  done < <(
    awk '
      {
        rest = $0
        while (match(rest, /\[\[[^][]+\]\]/)) {
          print FNR ":" substr(rest, RSTART + 2, RLENGTH - 4)
          rest = substr(rest, RSTART + RLENGTH)
        }
      }
    ' "$file"
  )
}

check_frontmatter_requirements() {
  local file="$1"

  requires_frontmatter "$file" || return 0

  if [ "$FRONTMATTER_PRESENT" -eq 0 ]; then
    report_problem "$file" 1 "frontmatter YAML ausente"
    return 0
  fi

  if [ "$FRONTMATTER_CLOSED" -eq 0 ]; then
    report_problem "$file" 1 "frontmatter YAML nao fechado"
  fi

  [ -n "$FRONTMATTER_TYPE_VALUE" ] || report_problem "$file" 1 "frontmatter obrigatorio ausente: type"
  [ -n "$FRONTMATTER_STATUS_VALUE" ] || report_problem "$file" 1 "frontmatter obrigatorio ausente: status"
  [ -n "$FRONTMATTER_DATE_VALUE" ] || report_problem "$file" 1 "frontmatter obrigatorio ausente: date"
}

resolve_source_ref_path() {
  local ref="$1" suffix candidate

  case "$ref" in
    /*)
      suffix="${ref#/}"
      while :; do
        candidate="$ROOT/$suffix"
        if [ -e "$candidate" ]; then
          printf '%s\n' "$candidate"
          return 0
        fi

        case "$suffix" in
          */*) suffix="${suffix#*/}" ;;
          *) break ;;
        esac
      done
      return 1
      ;;
    *)
      candidate="$ROOT/$ref"
      [ -e "$candidate" ] || return 1
      printf '%s\n' "$candidate"
      return 0
      ;;
  esac
}

check_source_refs() {
  local file="$1" line_no ref

  [ -n "$SOURCE_REFS_DATA" ] || return 0

  while IFS='	' read -r line_no ref; do
    [ -n "${line_no:-}" ] || continue
    ref="$(strip_quotes "$(trim "$ref")")"
    [ -n "$ref" ] || continue
    if ! resolve_source_ref_path "$ref" >/dev/null; then
      report_problem "$file" "$line_no" "source_ref inexistente: $ref"
    fi
  done <<EOF
$(printf '%s' "$SOURCE_REFS_DATA")
EOF
}

check_superseded_pointer() {
  local file="$1" self_slug self_target found=0 line_no slug target

  case "$file" in
    .engrama/decisions/*.md) ;;
    *) return 0 ;;
  esac

  [ "$FRONTMATTER_STATUS_VALUE" = "superseded" ] || return 0

  self_slug="${file#*.engrama/}"
  self_slug="${self_slug%.md}"
  self_target="$ROOT/.engrama/${self_slug}.md"

  while IFS=: read -r line_no slug; do
    [ -n "${line_no:-}" ] || continue
    [ "$line_no" -gt "$FRONTMATTER_END_LINE" ] || continue
    target="$(resolve_wikilink_target "$slug")" || continue
    case "$target" in
      "$ROOT/.engrama/decisions/"*.md)
        if [ "$target" != "$self_target" ]; then
          found=1
          break
        fi
        ;;
      *)
        ;;
    esac
  done < <(
    awk '
      {
        rest = $0
        while (match(rest, /\[\[[^][]+\]\]/)) {
          print FNR ":" substr(rest, RSTART + 2, RLENGTH - 4)
          rest = substr(rest, RSTART + RLENGTH)
        }
      }
    ' "$file"
  )

  if [ "$found" -eq 0 ]; then
    report_problem "$file" "${FRONTMATTER_STATUS_LINE:-1}" "ADR superseded sem ponteiro para substituta"
  fi
}

lint_file() {
  local file="$1"
  check_wikilinks "$file"
  parse_frontmatter "$file"
  check_frontmatter_requirements "$file"
  check_source_refs "$file"
  check_superseded_pointer "$file"
}

while IFS= read -r file; do
  [ -n "$file" ] || continue
  lint_file "$file"
done < <(
  find .engrama -type f -name '*.md' | sort
  [ -f CLAUDE.md ] && printf '%s\n' CLAUDE.md
  [ -f AGENTS.md ] && printf '%s\n' AGENTS.md
)

if [ "$ERRORS" -gt 0 ]; then
  cat "$TMP_REPORT"
fi

if [ "$REPORT_ONLY" -eq 1 ]; then
  exit 0
fi

[ "$ERRORS" -eq 0 ] || exit 1
exit 0
