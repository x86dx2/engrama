#!/usr/bin/env bash
# Contract tests do lint do Engrama.
# Valida os checks mecanicos em fixtures temporarios e no repo real.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LINT_SRC="$REPO_ROOT/lint.sh"
[ -f "$LINT_SRC" ] || { echo "FATAL: lint nao encontrado em $LINT_SRC"; exit 1; }

_probe="$(mktemp -d 2>/dev/null)" || { echo "FATAL: mktemp indisponivel — abortando"; exit 3; }
git -C "$_probe" init -q 2>/dev/null || { echo "FATAL: git init indisponivel — abortando"; rm -rf "$_probe"; exit 3; }
rm -rf "$_probe"

PASS=0; FAIL=0; HOLES=0; RESULTS=""

check() { # <id> <tag> <cond 0/1> <desc>
  local id="$1" tag="$2" ok="$3" desc="$4" mark
  if [ "$ok" -eq 0 ]; then mark="ok"; PASS=$((PASS + 1)); else mark="XX"; FAIL=$((FAIL + 1)); fi
  [ "$tag" = "FURO" ] && HOLES=$((HOLES + 1))
  RESULTS="$RESULTS\n  [$mark] $id  ($tag)  | $desc"
}

new_repo() {
  local d
  d="$(mktemp -d 2>/dev/null || mktemp -d -t engrama-lint-test)"
  git -C "$d" init -q -b main 2>/dev/null || { git -C "$d" init -q; git -C "$d" checkout -q -b main; }
  git -C "$d" config user.email t@t
  git -C "$d" config user.name t
  mkdir -p "$d/.engrama/decisions" "$d/.engrama/governance" "$d/.engrama/project" "$d/.engrama/qa" "$d/.engrama/specs"
  printf '%s' "$d"
}

write_file() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  cat > "$path"
}

run_lint() {
  (
    cd "$1" || exit 2
    bash "$LINT_SRC" >/dev/null 2>&1
    echo $?
  )
}

run_lint_report() {
  (
    cd "$1" || exit 2
    bash "$LINT_SRC" --report >/dev/null 2>&1
    echo $?
  )
}

is_zero() {
  [ "$1" -eq 0 ]
}

is_one() {
  [ "$1" -eq 1 ]
}

# L1: wikilink orfao => BLOQUEIA
R="$(new_repo)"
write_file "$R/.engrama/governance/p.md" <<'EOF'
---
type: governance
status: active
date: 2026-06-20
---

Ver [[governance/nao-existe]].
EOF
rc="$(run_lint "$R")"
if is_one "$rc"; then _r=0; else _r=1; fi
check L1 CORRETO "$_r" "wikilink orfao derruba o lint"

# L2: source_ref quebrado => BLOQUEIA
R="$(new_repo)"
write_file "$R/.engrama/project/p.md" <<'EOF'
---
type: governance
status: active
date: 2026-06-20
source_refs:
  - /nao/existe/no/disco
---

Texto.
EOF
rc="$(run_lint "$R")"
if is_one "$rc"; then _r=0; else _r=1; fi
check L2 CORRETO "$_r" "source_ref inexistente derruba o lint"

# L3: frontmatter ausente em area obrigatoria => BLOQUEIA
R="$(new_repo)"
write_file "$R/.engrama/specs/p.md" <<'EOF'
Sem frontmatter.
EOF
rc="$(run_lint "$R")"
if is_one "$rc"; then _r=0; else _r=1; fi
check L3 CORRETO "$_r" "frontmatter ausente derruba o lint"

# L4: ADR superseded sem ponteiro => BLOQUEIA
R="$(new_repo)"
write_file "$R/.engrama/decisions/0001-antiga.md" <<'EOF'
---
type: decision
status: superseded
date: 2026-06-20
---

ADR antiga sem substituta.
EOF
rc="$(run_lint "$R")"
if is_one "$rc"; then _r=0; else _r=1; fi
check L4 CORRETO "$_r" "ADR superseded sem ponteiro derruba o lint"

# L5: fixture limpo => PASSA
R="$(new_repo)"
write_file "$R/.engrama/governance/index.md" <<'EOF'
# indice

Ver [[log]].
EOF
write_file "$R/.engrama/log.md" <<'EOF'
# log
EOF
write_file "$R/.engrama/governance/p.md" <<EOF
---
type: governance
status: active
date: 2026-06-20
source_refs:
  - $R/.engrama/log.md
---

Ver [[governance/index]] e [[log]].
EOF
write_file "$R/.engrama/decisions/0002-nova.md" <<'EOF'
---
type: decision
status: active
date: 2026-06-20
---

ADR nova.
EOF
write_file "$R/.engrama/decisions/0001-antiga.md" <<'EOF'
---
type: decision
status: superseded
date: 2026-06-20
---

Substituida por [[decisions/0002-nova]].
EOF
rc="$(run_lint "$R")"
if is_zero "$rc"; then _r=0; else _r=1; fi
check L5 CORRETO "$_r" "fixture limpo passa"

# L6: --report so reporta (exit 0)
R="$(new_repo)"
write_file "$R/.engrama/governance/p.md" <<'EOF'
---
type: governance
status: active
date: 2026-06-20
---

Ver [[governance/nao-existe]].
EOF
rc="$(run_lint_report "$R")"
if is_zero "$rc"; then _r=0; else _r=1; fi
check L6 CORRETO "$_r" "--report nunca falha o processo"

# L7: repo real deve estar limpo
rc="$(run_lint "$REPO_ROOT")"
if is_zero "$rc"; then _r=0; else _r=1; fi
check L7 CORRETO "$_r" "repo real passa no proprio lint"

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: CORRETO = contrato esperado do lint."
[ "$FAIL" -eq 0 ] || exit 1
