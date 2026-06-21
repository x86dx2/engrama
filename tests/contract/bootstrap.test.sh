#!/usr/bin/env bash
# Contract tests do instalador (bin/install.sh / bin/bootstrap.sh).
# Caracteriza o comportamento REAL (golden) num repo-alvo temporario.
# Portavel (bash + git). Uso: bash tests/contract/bootstrap.test.sh
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PASS=0; FAIL=0; HOLES=0; RESULTS=""

# fail-fast: ambiente precisa de mktemp + git. Sob setup quebrado a suite ABORTA
# (exit 3) em vez de emitir falso-verde. (Incorpora critica do Executor 2026-06-20.)
_probe="$(mktemp -d 2>/dev/null)" || { echo "FATAL: mktemp indisponivel — abortando"; exit 3; }
git -C "$_probe" init -q 2>/dev/null || { echo "FATAL: git init indisponivel — abortando"; rm -rf "$_probe"; exit 3; }
rm -rf "$_probe"

check() { # <id> <tag> <cond 0/1> <desc>
  local id="$1" tag="$2" ok="$3" desc="$4" mark
  if [ "$ok" -eq 0 ]; then mark="ok"; PASS=$((PASS+1)); else mark="XX"; FAIL=$((FAIL+1)); fi
  [ "$tag" = "FURO" ] && HOLES=$((HOLES+1))
  RESULTS="$RESULTS\n  [$mark] $id  ($tag)  | $desc"
}

# target limpo (JA inicializado como repo git, pois bin/install.sh exige um) + values
new_target() {
  local d; d="$(mktemp -d 2>/dev/null || mktemp -d -t eg)"
  git -C "$d" init -q -b main 2>/dev/null
  git -C "$d" config user.email t@t; git -C "$d" config user.name t
  printf '%s' "$d"
}

mk_values() { # <file> <projeto> <autoridade>
  cat > "$1" <<EOF
PROJETO=$2
REPO_PATH=/tmp/x
ENGRAMA_VERSION=0.1.0
ORQUESTRADOR=Claude (Claude Code)
AUTORIDADE=$3
DATA=2026-06-20
FINALIDADE_DO_PROJETO=teste
STACK=Bash
DEV_URL=N/A
CMD_DEV=N/A
CMD_BUILD=N/A
CMD_TEST=N/A
CMD_E2E=N/A
EXECUTOR=Codex
EXECUTOR_CMD=codex exec
MODELO_CRITICA=gpt-5.5
MODELO_EXECUTOR_PESADO=gpt-5.4
MODELO_EXECUTOR_LEVE=gpt-5.4-mini
EOF
}

# C1: instalacao base — sem placeholders crus restantes
T="$(new_target)"; V="$(new_target)/v"; mkdir -p "$(dirname "$V")"
mk_values "$V" "MeuProjeto" "Humano (a@b.com)"
bash "$REPO_ROOT/bin/install.sh" "$T" "$V" >/dev/null 2>&1
# precondicao dura: se o install nao produziu saida, e setup quebrado -> FATAL
# (nao deixa um setup falho mascarar de 'C1 ok').
[ -f "$T/CLAUDE.md" ] || { echo "FATAL: bin/install.sh nao produziu CLAUDE.md em $T (setup quebrado) — abortando"; exit 3; }
rem="$(grep -rho '{{[A-Z_]*}}' "$T/CLAUDE.md" "$T/AGENTS.md" "$T/.engrama" 2>/dev/null | sort -u)"
if [ -z "$rem" ]; then _r=0; else _r=1; fi; check C1 CORRETO "$_r" "instalacao base: zero placeholders crus restantes"

# C2: hooksPath setado
got="$(git -C "$T" config core.hooksPath 2>/dev/null)"
if [ "$got" = ".engrama/githooks" ]; then _r=0; else _r=1; fi; check C2 CORRETO "$_r" "core.hooksPath == .engrama/githooks"

# C3: deteccao de colisao — 2a execucao recusa (exit != 0)
bash "$REPO_ROOT/bin/install.sh" "$T" "$V" >/dev/null 2>&1; rc=$?
if [ "$rc" -ne 0 ]; then _r=0; else _r=1; fi; check C3 CORRETO "$_r" "2a instalacao recusa sobrescrever (exit=$rc)"

# C4: nenhum .govtmp orfao
n="$(find "$T" -name '*.govtmp' 2>/dev/null | wc -l | tr -d ' ')"
if [ "$n" -eq 0 ]; then _r=0; else _r=1; fi; check C4 CORRETO "$_r" "nenhum arquivo .govtmp orfao apos install"

# P0.1 PROMOVIDO: o instalador foi corrigido (Executor via codex exec, branch
# fix/p0-instalador). C5/C6/C7 agora afirmam o comportamento CORRETO (CORRETO).

# C5: valor com '&' PRESERVADO literalmente (antes corrompia).
T2="$(new_target)"; V2="$(mktemp)"
mk_values "$V2" "Tom & Jerry" "Humano (a@b.com)"
bash "$REPO_ROOT/bin/install.sh" "$T2" "$V2" >/dev/null 2>&1
if grep -rqF 'Tom & Jerry' "$T2/.engrama" 2>/dev/null; then _r=0; else _r=1; fi
check C5 CORRETO "$_r" "valor com '&' preservado literalmente"

# C6: valor com '#' SUBSTITUIDO, zero placeholders crus (antes quebrava o sed global).
T3="$(new_target)"; V3="$(mktemp)"
mk_values "$V3" "Proj1" "Humano (a#b.com)"
bash "$REPO_ROOT/bin/install.sh" "$T3" "$V3" >/dev/null 2>&1
rem3="$(grep -rho '{{[A-Z_]*}}' "$T3/CLAUDE.md" "$T3/AGENTS.md" "$T3/.engrama" 2>/dev/null | sort -u | wc -l | tr -d ' ')"
if [ "$rem3" -eq 0 ]; then _r=0; else _r=1; fi
check C6 CORRETO "$_r" "valor com '#' substituido literalmente; zero placeholders crus"

# C7: FAIL-CLOSED — values INCOMPLETO (faltam chaves) deixa placeholders e deve ABORTAR !=0
#     (antes: retornava exit 0 com placeholders crus = 'sucesso' falso).
T7="$(new_target)"; V7="$(mktemp)"; printf 'PROJETO=SoIsso\n' > "$V7"
bash "$REPO_ROOT/bin/install.sh" "$T7" "$V7" >/dev/null 2>&1; rc7=$?
if [ "$rc7" -ne 0 ]; then _r=0; else _r=1; fi
check C7 CORRETO "$_r" "values incompleto -> fail-closed (exit=$rc7, !=0)"

# C9: regressao adversaria — todos os especiais juntos preservados + zero crus + exit 0.
T9="$(new_target)"; V9="$(mktemp)"
mk_values "$V9" "A&B #1 C/D 'E' \\F" "Humano (a#b.com & c)"
bash "$REPO_ROOT/bin/install.sh" "$T9" "$V9" >/dev/null 2>&1; rc9=$?
rem9="$(grep -rho '{{[A-Z_]*}}' "$T9/CLAUDE.md" "$T9/AGENTS.md" "$T9/.engrama" 2>/dev/null | sort -u | wc -l | tr -d ' ')"
if [ "$rc9" -eq 0 ] && [ "$rem9" -eq 0 ] && grep -rqF "A&B #1 C/D 'E' \\F" "$T9/.engrama" 2>/dev/null; then _r=0; else _r=1; fi
check C9 CORRETO "$_r" "todos os especiais (& # / espaco barra) preservados; zero crus; exit 0"

# C8: caminho CANONICO end-to-end — bin/bootstrap.sh num diretorio NAO-git deve
#     git-init + instalar + zerar placeholders. (Incorpora critica do Executor:
#     ate aqui a suite so cobria bin/install.sh, nao bin/bootstrap.sh.)
T8="$(mktemp -d)/proj"
bash "$REPO_ROOT/bin/bootstrap.sh" "$T8" >/dev/null 2>&1
if git -C "$T8" rev-parse --is-inside-work-tree >/dev/null 2>&1 && [ -f "$T8/CLAUDE.md" ]; then
  rem8="$(grep -rho '{{[A-Z_]*}}' "$T8/CLAUDE.md" "$T8/AGENTS.md" "$T8/.engrama" 2>/dev/null | sort -u)"
  if [ -z "$rem8" ]; then _r=0; else _r=1; fi
else _r=1; fi
check C8 CORRETO "$_r" "bin/bootstrap.sh (caminho canonico) em dir nao-git: git-init + instala + zero placeholders"

# C10: bootstrap instala .engrama/VERSION com a versao do pack, sem placeholder cru.
pack_version="$(sed -n '1{s/\r$//;p;q;}' "$REPO_ROOT/VERSION" 2>/dev/null)"
installed_version="$(sed -n '1{s/\r$//;p;q;}' "$T8/.engrama/VERSION" 2>/dev/null || true)"
if [ -n "$pack_version" ] && [ "$installed_version" = "$pack_version" ] && ! grep -q '{{' "$T8/.engrama/VERSION" 2>/dev/null; then
  _r=0
else
  _r=1
fi
check C10 CORRETO "$_r" ".engrama/VERSION instalado com a versao do pack e sem placeholder cru"

printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: assert fixa o comportamento ATUAL (golden); FURO = bug; quando corrigido, o assert FURO quebra de proposito (promover)."
[ "$FAIL" -eq 0 ] || exit 1
