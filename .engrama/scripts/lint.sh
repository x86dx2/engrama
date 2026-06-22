#!/usr/bin/env bash
set -u

REPORT_ONLY=0
WARNINGS=0
STALE_AFTER_DAYS=90
STALE_AFTER_SECONDS=$((STALE_AFTER_DAYS * 24 * 60 * 60))

usage() {
  cat <<'EOF'
Uso: bash ./.engrama/scripts/lint.sh [--report]

Valida a saude mecanica do Engrama:
- wikilinks em .engrama/**/*.md e na raiz (CLAUDE.md / AGENTS.md)
- source_refs no frontmatter
- frontmatter minimo nas areas obrigatorias
- `reconcilia:` quando presente
- ADR superseded sem ponteiro para substituta
- paginas orfas nas areas indexadas do Engrama (metrica de densidade de enlaces)
- gaps de numeracao em ADRs
- status de frontmatter fora do enum permitido
- TODO/FIXME/XXX em documentacao normativa
- staleness (warning) em governance/specs/decisions `active`
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

REPO_ROOT="$(
  CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd -P
)"
ROOT="$REPO_ROOT"
TMP_REPORT="$(mktemp 2>/dev/null || mktemp -t engrama-lint)"
TMP_WARNINGS="$(mktemp 2>/dev/null || mktemp -t engrama-lint-warn)"
trap 'rm -f "$TMP_REPORT" "$TMP_WARNINGS"' EXIT
ERRORS=0

if [ -n "${ENGRAMA_NOW:-}" ]; then
  case "$ENGRAMA_NOW" in
    ''|*[!0-9]*)
      echo "ERRO: ENGRAMA_NOW invalido: $ENGRAMA_NOW" >&2
      exit 2
      ;;
    *)
      NOW_EPOCH="$ENGRAMA_NOW"
      ;;
  esac
else
  NOW_EPOCH="$(date +%s)"
fi

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

report_warning() {
  local file="$1" line="$2" message="$3"
  printf 'WARN %s:%s: %s\n' "$file" "$line" "$message" >> "$TMP_WARNINGS"
  WARNINGS=$((WARNINGS + 1))
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

list_markdown_files() {
  find .engrama -type f -name '*.md' | sort
  [ -f CLAUDE.md ] && printf '%s\n' CLAUDE.md
  [ -f AGENTS.md ] && printf '%s\n' AGENTS.md
}

list_orphan_candidates() {
  local file base
  for file in \
    .engrama/decisions/*.md \
    .engrama/governance/*.md \
    .engrama/specs/*.md \
    .engrama/gaps/*.md \
    .engrama/project/*.md
  do
    [ -f "$file" ] || continue
    base="$(basename "$file")"
    case "$base" in
      index.md|log.md|CLAUDE.md)
        continue
        ;;
      *)
        printf '%s\n' "$file"
        ;;
    esac
  done
}

extract_wikilinks() {
  awk '
    {
      rest = $0
      while (match(rest, /\[\[[^][]+\]\]/)) {
        print FNR "\t" substr(rest, RSTART + 2, RLENGTH - 4)
        rest = substr(rest, RSTART + RLENGTH)
      }
    }
  ' "$1"
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
  FRONTMATTER_RECONCILIA_LINE=0
  FRONTMATTER_RECONCILIA_VALUE=""
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
      reconcilia:*)
        value="$(trim "${trimmed#reconcilia:}")"
        FRONTMATTER_RECONCILIA_LINE="$line_no"
        FRONTMATTER_RECONCILIA_VALUE="$value"
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

validate_reconcilia_target() {
  local file="$1" line="$2" op="$3" slug="$4" target

  target="$(resolve_wikilink_target "$slug")" || {
    report_problem "$file" "$line" "reconcilia malformado: $op exige slug-alvo no formato de wikilink/slug"
    return 1
  }

  if [ ! -e "$target" ]; then
    report_problem "$file" "$line" "reconcilia alvo inexistente: $slug"
    return 1
  fi

  return 0
}

check_reconcilia_value() {
  local file="$1" raw_value value op slug remainder

  [ -n "$FRONTMATTER_RECONCILIA_VALUE" ] || return 0

  raw_value="$FRONTMATTER_RECONCILIA_VALUE"
  value="$(strip_quotes "$(trim "$raw_value")")"

  [ -n "$value" ] || {
    report_problem "$file" "${FRONTMATTER_RECONCILIA_LINE:-1}" "reconcilia malformado: valor vazio"
    return 0
  }

  op="${value%% *}"
  if [ "$op" = "$value" ]; then
    slug=""
  else
    remainder="${value#"$op"}"
    slug="$(trim "$remainder")"
  fi

  case "$op" in
    ADD|UPDATE|DELETE|NOOP)
      ;;
    *)
      report_problem "$file" "${FRONTMATTER_RECONCILIA_LINE:-1}" "reconcilia invalido: $value (esperado: ADD|UPDATE|DELETE|NOOP)"
      return 0
      ;;
  esac

  case "$slug" in
    *" "*)
      report_problem "$file" "${FRONTMATTER_RECONCILIA_LINE:-1}" "reconcilia malformado: esperado no maximo um slug-alvo"
      return 0
      ;;
    *)
      ;;
  esac

  case "$op" in
    ADD)
      [ -n "$slug" ] || return 0
      validate_reconcilia_target "$file" "${FRONTMATTER_RECONCILIA_LINE:-1}" "$op" "$slug"
      ;;
    UPDATE|DELETE|NOOP)
      if [ -z "$slug" ]; then
        report_problem "$file" "${FRONTMATTER_RECONCILIA_LINE:-1}" "reconcilia malformado: $op exige slug-alvo"
        return 0
      fi
      validate_reconcilia_target "$file" "${FRONTMATTER_RECONCILIA_LINE:-1}" "$op" "$slug"
      ;;
  esac
}

check_wikilinks() {
  local file="$1" line_no slug target

  while IFS='	' read -r line_no slug; do
    [ -n "${line_no:-}" ] || continue
    target="$(resolve_wikilink_target "$slug")" || continue
    if [ ! -e "$target" ]; then
      report_problem "$file" "$line_no" "wikilink orfao: [[${slug}]] -> ${target#"$ROOT"/}"
    fi
  done < <(extract_wikilinks "$file")
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

check_status_value() {
  local file="$1" status_value

  requires_frontmatter "$file" || return 0
  [ -n "$FRONTMATTER_STATUS_VALUE" ] || return 0

  status_value="$(strip_quotes "$(trim "$FRONTMATTER_STATUS_VALUE")")"
  case "$status_value" in
    active|proposed|superseded|resolved)
      ;;
    *)
      report_problem "$file" "${FRONTMATTER_STATUS_LINE:-1}" "status invalido: $status_value (esperado: active|proposed|superseded|resolved)"
      ;;
  esac
}

resolve_source_ref_path() {
  local ref="$1" suffix candidate dir base resolved_dir

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
      dir="${ref%/*}"
      base="${ref##*/}"
      [ "$dir" = "$ref" ] && dir="."
      resolved_dir="$(
        CDPATH='' cd -- "$ROOT/$dir" 2>/dev/null && pwd -P
      )" || return 1
      case "$resolved_dir" in
        "$ROOT"|"$ROOT"/*) ;;
        *) return 1 ;;
      esac
      candidate="$resolved_dir/$base"
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

  while IFS='	' read -r line_no slug; do
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
  done < <(extract_wikilinks "$file")

  if [ "$found" -eq 0 ]; then
    report_problem "$file" "${FRONTMATTER_STATUS_LINE:-1}" "ADR superseded sem ponteiro para substituta"
  fi
}

check_normative_markers() {
  local file="$1" line_no line_text marker

  case "$file" in
    .engrama/governance/*.md|.engrama/decisions/*.md) ;;
    *) return 0 ;;
  esac

  while IFS=: read -r line_no line_text; do
    [ -n "${line_no:-}" ] || continue
    marker="TODO"
    case "$line_text" in
      *FIXME*) marker="FIXME" ;;
      *XXX*) marker="XXX" ;;
      *TODO*) marker="TODO" ;;
    esac
    report_problem "$file" "$line_no" "marcador cru em doc normativo: $marker"
  done < <(grep -nE '(^|[^[:alnum:]_])(TODO|FIXME|XXX)([^[:alnum:]_]|$)' "$file" || true)
}

check_staleness() {
  local file="$1" status_value last_commit_epoch age_seconds age_days

  case "$file" in
    .engrama/governance/*.md|.engrama/specs/*.md|.engrama/decisions/*.md) ;;
    *) return 0 ;;
  esac

  [ -n "$FRONTMATTER_STATUS_VALUE" ] || return 0
  status_value="$(strip_quotes "$(trim "$FRONTMATTER_STATUS_VALUE")")"
  [ "$status_value" = "active" ] || return 0

  last_commit_epoch="$(git -C "$ROOT" log -1 --format=%ct -- "$file" 2>/dev/null || true)"
  last_commit_epoch="$(trim "$last_commit_epoch")"
  case "$last_commit_epoch" in
    ''|*[!0-9]*) return 0 ;;
    *) ;;
  esac

  age_seconds=$((NOW_EPOCH - last_commit_epoch))
  [ "$age_seconds" -gt "$STALE_AFTER_SECONDS" ] || return 0

  age_days=$((age_seconds / 86400))
  report_warning "$file" "${FRONTMATTER_STATUS_LINE:-1}" "staleness: ultima mudanca versionada ha ${age_days}d (> ${STALE_AFTER_DAYS}d)"
}

has_inbound_wikilink() {
  local target_file="$1" target_abs source_file line_no slug resolved
  target_abs="$ROOT/$target_file"

  while IFS= read -r source_file; do
    [ -n "$source_file" ] || continue
    [ "$source_file" = "$target_file" ] && continue

    while IFS='	' read -r line_no slug; do
      [ -n "${line_no:-}" ] || continue
      resolved="$(resolve_wikilink_target "$slug")" || continue
      if [ "$resolved" = "$target_abs" ]; then
        return 0
      fi
    done < <(extract_wikilinks "$source_file")
  done < <(list_markdown_files)

  return 1
}

is_listed_in_primary_indexes() {
  local target_file="$1" target_abs index_file line_no slug resolved
  target_abs="$ROOT/$target_file"

  for index_file in .engrama/index.md .engrama/governance/index.md; do
    [ -f "$index_file" ] || continue
    while IFS='	' read -r line_no slug; do
      [ -n "${line_no:-}" ] || continue
      resolved="$(resolve_wikilink_target "$slug")" || continue
      if [ "$resolved" = "$target_abs" ]; then
        return 0
      fi
    done < <(extract_wikilinks "$index_file")
  done

  return 1
}

check_orphan_pages() {
  local file

  # Paginas orfas funcionam como proxy simples da densidade de enlaces do Engrama.
  while IFS= read -r file; do
    [ -n "$file" ] || continue
    is_listed_in_primary_indexes "$file" && continue
    has_inbound_wikilink "$file" && continue
    report_problem "$file" 1 "pagina orfa: sem wikilink em outro .md e fora de .engrama/index.md/.engrama/governance/index.md"
  done < <(list_orphan_candidates)
}

check_adr_numbering_gaps() {
  local file base adr_number adr_number_dec max_number=0 found_numbers="" expected missing_numbers=""

  for file in .engrama/decisions/*.md; do
    [ -f "$file" ] || continue
    base="$(basename "$file")"
    case "$base" in
      [0-9][0-9][0-9][0-9]-*.md)
        adr_number="${base%%-*}"
        adr_number_dec=$((10#$adr_number))
        if [ "$adr_number_dec" -gt "$max_number" ]; then
          max_number="$adr_number_dec"
        fi
        found_numbers="$found_numbers $adr_number"
        ;;
      *)
        ;;
    esac
  done

  [ "$max_number" -gt 0 ] || return 0

  expected=1
  while [ "$expected" -le "$max_number" ]; do
    adr_number="$(printf '%04d' "$expected")"
    case " $found_numbers " in
      *" $adr_number "*) ;;
      *) missing_numbers="$missing_numbers $adr_number" ;;
    esac
    expected=$((expected + 1))
  done

  [ -n "$missing_numbers" ] || return 0
  missing_numbers="${missing_numbers# }"
  report_problem ".engrama/decisions" 1 "gap na numeracao de ADRs: faltando $missing_numbers"
}

lint_file() {
  local file="$1"
  check_wikilinks "$file"
  parse_frontmatter "$file"
  check_frontmatter_requirements "$file"
  check_status_value "$file"
  check_reconcilia_value "$file"
  check_source_refs "$file"
  check_superseded_pointer "$file"
  check_normative_markers "$file"
  check_staleness "$file"
}

while IFS= read -r file; do
  [ -n "$file" ] || continue
  lint_file "$file"
done < <(list_markdown_files)

check_orphan_pages
check_adr_numbering_gaps

if [ "$ERRORS" -gt 0 ]; then
  cat "$TMP_REPORT" >&2
fi

if [ "$WARNINGS" -gt 0 ]; then
  cat "$TMP_WARNINGS"
fi

if [ "$REPORT_ONLY" -eq 1 ]; then
  exit 0
fi

[ "$ERRORS" -eq 0 ] || exit 1
exit 0
