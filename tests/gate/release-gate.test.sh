#!/usr/bin/env bash
# Suite do release-gate repo-central-only.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RELEASE_GATE_SRC="$REPO_ROOT/bin/release-gate.sh"
DIFF_HASH_SRC="$REPO_ROOT/.engrama/engine/scripts/engrama-diff-hash.sh"
MANIFEST_SRC="$REPO_ROOT/.engrama/release-surface.manifest"
WAIVER_SRC="$REPO_ROOT/.engrama/evidence/qa/release-waivers.md"
[ -f "$RELEASE_GATE_SRC" ] || { echo "FATAL: release-gate nao encontrado em $RELEASE_GATE_SRC"; exit 1; }
[ -f "$DIFF_HASH_SRC" ] || { echo "FATAL: helper de hash nao encontrado em $DIFF_HASH_SRC"; exit 1; }
[ -f "$MANIFEST_SRC" ] || { echo "FATAL: manifest nao encontrado em $MANIFEST_SRC"; exit 1; }
[ -f "$WAIVER_SRC" ] || { echo "FATAL: waiver file nao encontrado em $WAIVER_SRC"; exit 1; }

_probe="$(mktemp -d 2>/dev/null)" || { echo "FATAL: mktemp indisponivel — abortando"; exit 3; }
git -C "$_probe" init -q 2>/dev/null || { echo "FATAL: git init indisponivel — abortando"; rm -rf "$_probe"; exit 3; }
rm -rf "$_probe"

PASS=0; FAIL=0; HOLES=0
RESULTS=""

check() {
  local id="$1" tag="$2" exp="$3" got="$4" desc="$5" mark
  if [ "$exp" = "$got" ]; then mark="ok"; PASS=$((PASS + 1)); else mark="XX"; FAIL=$((FAIL + 1)); fi
  [ "$tag" = "FURO" ] && HOLES=$((HOLES + 1))
  local label
  case "$got" in
    0) label="PASSA" ;;
    1) label="CONFIG" ;;
    2) label="POLICY" ;;
    *) label="exit:$got" ;;
  esac
  RESULTS="$RESULTS\n  [$mark] $id  ($tag)  -> $label  | $desc"
}

check_text() {
  local id="$1" tag="$2" needle="$3" haystack="$4" desc="$5" mark
  if printf '%s' "$haystack" | grep -Fq "$needle"; then mark="ok"; PASS=$((PASS + 1)); else mark="XX"; FAIL=$((FAIL + 1)); fi
  [ "$tag" = "FURO" ] && HOLES=$((HOLES + 1))
  RESULTS="$RESULTS\n  [$mark] $id  ($tag)  -> texto  | $desc"
}

new_repo() {
  local branch="$1" d
  d="$(mktemp -d 2>/dev/null || mktemp -d -t engrama-release-gate)"
  git -C "$d" init -q -b "$branch" 2>/dev/null || { git -C "$d" init -q; git -C "$d" checkout -q -b "$branch"; }
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  mkdir -p "$d/bin" "$d/.engrama/engine/scripts" "$d/.engrama/evidence/qa" "$d/template"
  cp "$RELEASE_GATE_SRC" "$d/bin/release-gate.sh"
  cp "$DIFF_HASH_SRC" "$d/.engrama/engine/scripts/engrama-diff-hash.sh"
  cp "$MANIFEST_SRC" "$d/.engrama/release-surface.manifest"
  cp "$WAIVER_SRC" "$d/.engrama/evidence/qa/release-waivers.md"
  cat > "$d/VERSION" <<'EOF'
0.1.0
EOF
  cat > "$d/CHANGELOG.md" <<'EOF'
# Changelog

## [Não lançado]

## [0.1.0] - 2026-06-21

### Added
- Base.
EOF
  cat > "$d/template/CLAUDE.md" <<'EOF'
template v1
EOF
  cat > "$d/.markdownlint-cli2.yaml" <<'EOF'
globs:
  - "**/*.md"
EOF
  cat > "$d/outside.txt" <<'EOF'
outside v1
EOF
  git -C "$d" add .
  git -C "$d" commit -qm base
  printf '%s' "$d"
}

run_gate() {
  local repo="$1" mode="$2" base_ref="${3:-}" rc
  (
    cd "$repo" || exit 2
    if [ -n "$base_ref" ]; then
      bash ./bin/release-gate.sh --mode "$mode" --base-ref "$base_ref" >/dev/null 2>&1
    else
      bash ./bin/release-gate.sh --mode "$mode" >/dev/null 2>&1
    fi
    rc=$?
    echo "$rc"
  )
}

run_gate_capture() {
  local repo="$1" mode="$2" base_ref="${3:-}" rc out
  (
    cd "$repo" || exit 2
    if [ -n "$base_ref" ]; then
      out="$(bash ./bin/release-gate.sh --mode "$mode" --base-ref "$base_ref" 2>&1 >/dev/null)"; rc=$?
    else
      out="$(bash ./bin/release-gate.sh --mode "$mode" 2>&1 >/dev/null)"; rc=$?
    fi
    printf '%s\n' "$rc"
    printf '%s\n' "$out"
  )
}

print_hash() {
  (
    cd "$1" || exit 2
    bash ./bin/release-gate.sh --print-hash --base-ref "$2"
  )
}

write_release() {
  local repo="$1" version="$2" date="$3"
  cat > "$repo/VERSION" <<EOF
$version
EOF
  cat > "$repo/CHANGELOG.md" <<EOF
# Changelog

## [Nao lancado]

## [$version] - $date

### Changed
- Release.

## [0.1.0] - 2026-06-21

### Added
- Base.
EOF
}

write_invalid_release_heading() {
  local repo="$1" version="$2"
  cat > "$repo/VERSION" <<EOF
$version
EOF
  cat > "$repo/CHANGELOG.md" <<'EOF'
# Changelog

## [Nao lancado]

## [0.1.0] - 2026-06-21

### Added
- Base.
EOF
}

# RG1: payload mudou sem bump -> bloqueia em ci
r="$(new_repo main)"
git -C "$r" checkout -q -b pr/rg1
printf 'template v2\n' > "$r/template/CLAUDE.md"
git -C "$r" add template/CLAUDE.md
git -C "$r" commit -qm payload
check RG1 CORRETO 2 "$(run_gate "$r" ci main)" "payload distribuivel mudou sem VERSION+CHANGELOG e sem waiver"

# RG2: payload + VERSION + CHANGELOG valido -> passa
r="$(new_repo main)"
git -C "$r" checkout -q -b pr/rg2
printf 'template v2\n' > "$r/template/CLAUDE.md"
write_release "$r" "0.2.0" "2026-06-24"
git -C "$r" add template/CLAUDE.md VERSION CHANGELOG.md
git -C "$r" commit -qm release
check RG2 CORRETO 0 "$(run_gate "$r" ci main)" "payload + bump + changelog corrente passa"

# RG3: waiver valido bound-by-hash -> passa
r="$(new_repo main)"
git -C "$r" checkout -q -b pr/rg3
printf 'template v2\n' > "$r/template/CLAUDE.md"
git -C "$r" add template/CLAUDE.md
git -C "$r" commit -qm payload
hash="$(print_hash "$r" main)"
printf '\n## [2026-06-24] pr/rg3 | sem-release | %s | sem release neste diff\n' "$hash" >> "$r/.engrama/evidence/qa/release-waivers.md"
git -C "$r" add .engrama/evidence/qa/release-waivers.md
git -C "$r" commit -qm waiver
check RG3 CORRETO 0 "$(run_gate "$r" ci main)" "waiver sem-release com hash atual libera payload sem bump"

# RG4: waiver stale -> bloqueia
r="$(new_repo main)"
git -C "$r" checkout -q -b pr/rg4
printf 'template v2\n' > "$r/template/CLAUDE.md"
git -C "$r" add template/CLAUDE.md
git -C "$r" commit -qm payload-1
hash="$(print_hash "$r" main)"
printf '\n## [2026-06-24] pr/rg4 | sem-release | %s | waiver antigo\n' "$hash" >> "$r/.engrama/evidence/qa/release-waivers.md"
git -C "$r" add .engrama/evidence/qa/release-waivers.md
git -C "$r" commit -qm waiver
printf 'template v3\n' > "$r/template/CLAUDE.md"
git -C "$r" add template/CLAUDE.md
git -C "$r" commit -qm payload-2
check RG4 CORRETO 2 "$(run_gate "$r" ci main)" "waiver stale nao cobre payload editado depois"

# RG5: VERSION mudou sem heading corrente -> bloqueia
r="$(new_repo main)"
git -C "$r" checkout -q -b pr/rg5
printf 'template v2\n' > "$r/template/CLAUDE.md"
write_invalid_release_heading "$r" "0.2.0"
git -C "$r" add template/CLAUDE.md VERSION CHANGELOG.md
git -C "$r" commit -qm invalid-heading
check RG5 CORRETO 2 "$(run_gate "$r" ci main)" "VERSION mudou sem heading corrente no CHANGELOG"

# RG6: release-only -> passa
r="$(new_repo main)"
git -C "$r" checkout -q -b pr/rg6
write_release "$r" "0.2.0" "2026-06-24"
git -C "$r" add VERSION CHANGELOG.md
git -C "$r" commit -qm release-only
check RG6 CORRETO 0 "$(run_gate "$r" ci main)" "release-only (VERSION + CHANGELOG) passa sem payload"

# RG7: delete em payload conta -> bloqueia
r="$(new_repo main)"
git -C "$r" checkout -q -b pr/rg7
git -C "$r" rm -q template/CLAUDE.md
git -C "$r" commit -qm delete
check RG7 CORRETO 2 "$(run_gate "$r" ci main)" "delete em caminho do payload conta como mudanca distribuivel"

# RG8A: rename saindo do payload conta -> bloqueia
r="$(new_repo main)"
git -C "$r" checkout -q -b pr/rg8a
mkdir -p "$r/docs"
git -C "$r" mv template/CLAUDE.md docs/CLAUDE.md
git -C "$r" commit -qm rename-out
check RG8A CORRETO 2 "$(run_gate "$r" ci main)" "rename saindo do payload conta como mudanca distribuivel"

# RG8B: rename entrando no payload conta -> bloqueia
r="$(new_repo main)"
git -C "$r" checkout -q -b pr/rg8b
git -C "$r" mv outside.txt template/outside.txt
git -C "$r" commit -qm rename-in
check RG8B CORRETO 2 "$(run_gate "$r" ci main)" "rename entrando no payload conta como mudanca distribuivel"

# RG9: warn sem base/tag -> exit 0 com skip
r="$(new_repo topic)"
capture="$(run_gate_capture "$r" warn)"
check RG9 CORRETO 0 "$(printf '%s\n' "$capture" | sed -n '1p')" "warn sem base branch nem tag nao quebra"
check_text RG9A CORRETO "pulando em --mode warn" "$capture" "warn sem base/tag emite skip explicito"

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: CORRETO = contrato esperado do release-gate."
[ "$FAIL" -eq 0 ] || exit 1
