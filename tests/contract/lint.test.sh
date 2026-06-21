#!/usr/bin/env bash
# Contract tests do lint do Engrama.
# Valida checks mecanicos em fixtures temporarios e no repo real.
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LINT_SRC="$REPO_ROOT/.engrama/scripts/lint.sh"
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
  mkdir -p \
    "$d/.engrama/decisions" \
    "$d/.engrama/gaps" \
    "$d/.engrama/governance" \
    "$d/.engrama/project" \
    "$d/.engrama/qa" \
    "$d/.engrama/scripts" \
    "$d/.engrama/specs"
  cp "$LINT_SRC" "$d/.engrama/scripts/lint.sh"
  chmod +x "$d/.engrama/scripts/lint.sh"
  printf '%s' "$d"
}

new_temp_dir() {
  mktemp -d 2>/dev/null || mktemp -d -t engrama-lint-test
}

write_file() {
  local path="$1"
  mkdir -p "$(dirname "$path")"
  cat > "$path"
}

seed_clean_repo() {
  local repo="$1"

  write_file "$repo/.engrama/index.md" <<'EOF'
# indice

- [[project/bootstrap-do-projeto]]
- [[governance/index]]
- [[decisions/0001-primeira]]
- [[specs/README]]
EOF

  write_file "$repo/.engrama/governance/index.md" <<'EOF'
# indice de governanca

- [[governance/regras]]
- [[log]]
EOF

  write_file "$repo/.engrama/log.md" <<'EOF'
# log
EOF

  write_file "$repo/.engrama/project/bootstrap-do-projeto.md" <<'EOF'
---
type: governance
status: active
date: 2026-06-21
source_refs:
  - .engrama/log.md
---

Bootstrap ativo.
EOF

  write_file "$repo/.engrama/governance/regras.md" <<'EOF'
---
type: governance
status: active
date: 2026-06-21
source_refs:
  - .engrama/log.md
---

Ver [[governance/index]] e [[log]].
EOF

  write_file "$repo/.engrama/decisions/0001-primeira.md" <<'EOF'
---
type: decision
status: active
date: 2026-06-21
source_refs:
  - .engrama/log.md
---

ADR inicial. Ver [[governance/regras]].
EOF

  write_file "$repo/.engrama/specs/README.md" <<'EOF'
---
type: spec
status: active
date: 2026-06-21
source_refs:
  - .engrama/log.md
---

Guia. Ver [[governance/regras]].
EOF
}

run_lint() {
  (
    cd "$1" || exit 2
    bash ./.engrama/scripts/lint.sh >/dev/null 2>&1
    echo $?
  )
}

run_lint_report() {
  (
    cd "$1" || exit 2
    bash ./.engrama/scripts/lint.sh --report >/dev/null 2>&1
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
seed_clean_repo "$R"
write_file "$R/.engrama/governance/regras.md" <<'EOF'
---
type: governance
status: active
date: 2026-06-21
source_refs:
  - .engrama/log.md
---

Ver [[governance/nao-existe]].
EOF
rc="$(run_lint "$R")"
if is_one "$rc"; then _r=0; else _r=1; fi
check L1 CORRETO "$_r" "wikilink orfao derruba o lint"

# L2: source_ref relativo quebrado => BLOQUEIA
R="$(new_repo)"
seed_clean_repo "$R"
write_file "$R/.engrama/project/bootstrap-do-projeto.md" <<'EOF'
---
type: governance
status: active
date: 2026-06-21
source_refs:
  - .engrama/nao-existe.md
---

Texto.
EOF
rc="$(run_lint "$R")"
if is_one "$rc"; then _r=0; else _r=1; fi
check L2 CORRETO "$_r" "source_ref relativo inexistente derruba o lint"

# L3: frontmatter ausente em area obrigatoria => BLOQUEIA
R="$(new_repo)"
seed_clean_repo "$R"
write_file "$R/.engrama/specs/README.md" <<'EOF'
Sem frontmatter.
EOF
rc="$(run_lint "$R")"
if is_one "$rc"; then _r=0; else _r=1; fi
check L3 CORRETO "$_r" "frontmatter ausente derruba o lint"

# L4: ADR superseded sem ponteiro => BLOQUEIA
R="$(new_repo)"
seed_clean_repo "$R"
write_file "$R/.engrama/decisions/0001-primeira.md" <<'EOF'
---
type: decision
status: superseded
date: 2026-06-21
source_refs:
  - .engrama/log.md
---

ADR antiga sem substituta.
EOF
rc="$(run_lint "$R")"
if is_one "$rc"; then _r=0; else _r=1; fi
check L4 CORRETO "$_r" "ADR superseded sem ponteiro derruba o lint"

# L5: fixture limpo => PASSA
R="$(new_repo)"
seed_clean_repo "$R"
rc="$(run_lint "$R")"
if is_zero "$rc"; then _r=0; else _r=1; fi
check L5 CORRETO "$_r" "fixture limpo passa"

# L6: --report so reporta (exit 0)
R="$(new_repo)"
seed_clean_repo "$R"
write_file "$R/.engrama/governance/regras.md" <<'EOF'
---
type: governance
status: active
date: 2026-06-21
source_refs:
  - .engrama/log.md
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

# L8: clone em outro path continua valido com source_ref relativo
R_SRC="$(new_repo)"
seed_clean_repo "$R_SRC"
git -C "$R_SRC" add . >/dev/null 2>&1
git -C "$R_SRC" commit -qm "seed" >/dev/null 2>&1
R_CLONE_PARENT="$(new_temp_dir)"
R_CLONE="$R_CLONE_PARENT/clone"
git clone -q "$R_SRC" "$R_CLONE"
rm -rf "$R_SRC"
rc="$(
  cd "$R_CLONE" || exit 2
  bash ./.engrama/scripts/lint.sh >/dev/null 2>&1
  echo $?
)"
if is_zero "$rc"; then _r=0; else _r=1; fi
check L8 CORRETO "$_r" "clone em outro path passa com source_ref relativo"
rm -rf "$R_CLONE_PARENT"

# L9: source_ref absoluto legado segue compativel
R_SRC="$(new_repo)"
seed_clean_repo "$R_SRC"
write_file "$R_SRC/.engrama/project/bootstrap-do-projeto.md" <<EOF
---
type: governance
status: active
date: 2026-06-21
source_refs:
  - $R_SRC/.engrama/log.md
---

Texto.
EOF
git -C "$R_SRC" add . >/dev/null 2>&1
git -C "$R_SRC" commit -qm "seed" >/dev/null 2>&1
R_CLONE_PARENT="$(new_temp_dir)"
R_CLONE="$R_CLONE_PARENT/clone"
git clone -q "$R_SRC" "$R_CLONE"
rm -rf "$R_SRC"
rc="$(
  cd "$R_CLONE" || exit 2
  bash ./.engrama/scripts/lint.sh >/dev/null 2>&1
  echo $?
)"
if is_zero "$rc"; then _r=0; else _r=1; fi
check L9 CORRETO "$_r" "source_ref absoluto legado segue valido por compatibilidade"
rm -rf "$R_CLONE_PARENT"

# L10: pagina orfa => BLOQUEIA
R="$(new_repo)"
seed_clean_repo "$R"
write_file "$R/.engrama/specs/orfa.md" <<'EOF'
---
type: spec
status: active
date: 2026-06-21
source_refs:
  - .engrama/log.md
---

Sem referencias de entrada.
EOF
rc="$(run_lint "$R")"
if is_one "$rc"; then _r=0; else _r=1; fi
check L10 CORRETO "$_r" "pagina orfa derruba o lint"

# L11: pagina orfa resolvida por indice => PASSA
R="$(new_repo)"
seed_clean_repo "$R"
write_file "$R/.engrama/specs/orfa.md" <<'EOF'
---
type: spec
status: active
date: 2026-06-21
source_refs:
  - .engrama/log.md
---

Agora listada.
EOF
write_file "$R/.engrama/index.md" <<'EOF'
# indice

- [[project/bootstrap-do-projeto]]
- [[governance/index]]
- [[decisions/0001-primeira]]
- [[specs/README]]
- [[specs/orfa]]
EOF
rc="$(run_lint "$R")"
if is_zero "$rc"; then _r=0; else _r=1; fi
check L11 CORRETO "$_r" "pagina deixa de ser orfa quando entra no indice"

# L12: gap na numeracao de ADR => BLOQUEIA
R="$(new_repo)"
seed_clean_repo "$R"
write_file "$R/.engrama/decisions/0003-terceira.md" <<'EOF'
---
type: decision
status: active
date: 2026-06-21
source_refs:
  - .engrama/log.md
---

ADR terceira.
EOF
write_file "$R/.engrama/index.md" <<'EOF'
# indice

- [[project/bootstrap-do-projeto]]
- [[governance/index]]
- [[decisions/0001-primeira]]
- [[decisions/0003-terceira]]
- [[specs/README]]
EOF
rc="$(run_lint "$R")"
if is_one "$rc"; then _r=0; else _r=1; fi
check L12 CORRETO "$_r" "gap na sequencia 0001..N derruba o lint"

# L13: sequencia de ADR contigua => PASSA
R="$(new_repo)"
seed_clean_repo "$R"
write_file "$R/.engrama/decisions/0002-segunda.md" <<'EOF'
---
type: decision
status: active
date: 2026-06-21
source_refs:
  - .engrama/log.md
---

ADR segunda.
EOF
write_file "$R/.engrama/index.md" <<'EOF'
# indice

- [[project/bootstrap-do-projeto]]
- [[governance/index]]
- [[decisions/0001-primeira]]
- [[decisions/0002-segunda]]
- [[specs/README]]
EOF
rc="$(run_lint "$R")"
if is_zero "$rc"; then _r=0; else _r=1; fi
check L13 CORRETO "$_r" "sequencia contigua de ADRs passa"

# L14: status invalido => BLOQUEIA
R="$(new_repo)"
seed_clean_repo "$R"
write_file "$R/.engrama/governance/regras.md" <<'EOF'
---
type: governance
status: draft
date: 2026-06-21
source_refs:
  - .engrama/log.md
---

Ver [[governance/index]] e [[log]].
EOF
rc="$(run_lint "$R")"
if is_one "$rc"; then _r=0; else _r=1; fi
check L14 CORRETO "$_r" "status fora do enum derruba o lint"

# L15: status valido volta a passar
R="$(new_repo)"
seed_clean_repo "$R"
write_file "$R/.engrama/governance/regras.md" <<'EOF'
---
type: governance
status: resolved
date: 2026-06-21
source_refs:
  - .engrama/log.md
---

Ver [[governance/index]] e [[log]].
EOF
rc="$(run_lint "$R")"
if is_zero "$rc"; then _r=0; else _r=1; fi
check L15 CORRETO "$_r" "status permitido segue verde"

# L16: TODO em doc normativo => BLOQUEIA
R="$(new_repo)"
seed_clean_repo "$R"
write_file "$R/.engrama/governance/regras.md" <<'EOF'
---
type: governance
status: active
date: 2026-06-21
source_refs:
  - .engrama/log.md
---

TODO: consolidar a regra.
EOF
rc="$(run_lint "$R")"
if is_one "$rc"; then _r=0; else _r=1; fi
check L16 CORRETO "$_r" "TODO em governanca derruba o lint"

# L17: marcador fora da area normativa (bootstrap) nao derruba
R="$(new_repo)"
seed_clean_repo "$R"
write_file "$R/.engrama/project/bootstrap-do-projeto.md" <<'EOF'
---
type: governance
status: active
date: 2026-06-21
source_refs:
  - .engrama/log.md
---

TODO: este placeholder e permitido no bootstrap.
EOF
rc="$(run_lint "$R")"
if is_zero "$rc"; then _r=0; else _r=1; fi
check L17 CORRETO "$_r" "TODO no bootstrap continua permitido"

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: CORRETO = contrato esperado; os pares L10/L11, L12/L13, L14/L15 e L16/L17 provam sensibilidade dos checks novos."
[ "$FAIL" -eq 0 ] || exit 1
