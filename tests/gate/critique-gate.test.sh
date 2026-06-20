#!/usr/bin/env bash
# Suite de testes do gate de critica (.engrama/scripts/critique-gate.sh).
# Portavel (bash puro, zero dependencia externa alem de git) — roda local e em CI.
#
# Cada caso monta um repo git temporario, copia o gate real, encena um staging,
# roda o gate e compara o exit code. A coluna TAG diz se o comportamento atual e
# CORRETO (regressao a proteger) ou FURO (comportamento inseguro a corrigir).
#
# Exit codes do gate:  0 = libera commit · 2 = BLOQUEIA commit
#
# Uso: bash tests/gate/critique-gate.test.sh
set -u

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
GATE_SRC="$REPO_ROOT/.engrama/scripts/critique-gate.sh"
[ -f "$GATE_SRC" ] || { echo "FATAL: gate nao encontrado em $GATE_SRC"; exit 1; }

# fail-fast: o ambiente precisa de mktemp + git funcionais. Sob sandbox read-only
# (mktemp/git falham) a suite ABORTA com exit 3 em vez de emitir falso-verde.
# (Incorpora a critica do Executor 2026-06-20: testes nao podem passar em setup quebrado.)
_probe="$(mktemp -d 2>/dev/null)" || { echo "FATAL: mktemp indisponivel — abortando (evita falso-verde)"; exit 3; }
git -C "$_probe" init -q 2>/dev/null || { echo "FATAL: git init indisponivel — abortando"; rm -rf "$_probe"; exit 3; }
rm -rf "$_probe"

PASS=0; FAIL=0; HOLES=0
RESULTS=""

# new_repo <branch> -> imprime o caminho do repo temporario ja inicializado com o gate
new_repo() {
  local branch="$1" d
  d="$(mktemp -d 2>/dev/null || mktemp -d -t engrama)"
  git -C "$d" init -q -b "$branch" 2>/dev/null || { git -C "$d" init -q; git -C "$d" checkout -q -b "$branch"; }
  git -C "$d" config user.email t@t; git -C "$d" config user.name t
  mkdir -p "$d/.engrama/scripts" "$d/.engrama/qa" "$d/.engrama/governance"
  cp "$GATE_SRC" "$d/.engrama/scripts/critique-gate.sh"
  printf '%s' "$d"
}

# write_ledger <repo> <conteudo...>  (escreve a linha de dados do ledger)
write_ledger() { printf '%s\n' "$2" > "$1/.engrama/qa/criticas-do-executor.md"; }

run_gate() { ( cd "$1" && bash .engrama/scripts/critique-gate.sh >/dev/null 2>&1; echo $?; ); }

# check <id> <tag CORRETO|FURO> <esperado> <obtido> <descricao>
check() {
  local id="$1" tag="$2" exp="$3" got="$4" desc="$5" mark
  if [ "$exp" = "$got" ]; then mark="ok"; PASS=$((PASS+1)); else mark="XX"; FAIL=$((FAIL+1)); fi
  [ "$tag" = "FURO" ] && HOLES=$((HOLES+1))
  local label; case "$got" in 0) label="LIBERA";; 2) label="BLOQUEIA";; *) label="exit:$got";; esac
  RESULTS="$RESULTS\n  [$mark] $id  ($tag)  -> gate $label  | $desc"
}

# ── GREEN: comportamento correto (proteger contra regressao) ──────────────────

# G1: governanca + ledger com 'confirmo' p/ a branch+categoria => LIBERA
r="$(new_repo main)"
write_ledger "$r" "## [2026-06-20] main | [governance] plano | confirmo | ref"
echo x > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md .engrama/qa/criticas-do-executor.md
check G1 CORRETO 0 "$(run_gate "$r")" "governanca COM critica 'confirmo' registrada"

# G2: governanca SEM nenhuma entrada no ledger => BLOQUEIA
r="$(new_repo main)"
write_ledger "$r" "# ledger vazio"
echo x > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md .engrama/qa/criticas-do-executor.md
check G2 CORRETO 2 "$(run_gate "$r")" "governanca SEM critica registrada"

# G3: objecao sem waiver => BLOQUEIA
r="$(new_repo main)"
write_ledger "$r" "## [2026-06-20] main | [governance] x | objecao: risco serio | ref"
echo x > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md .engrama/qa/criticas-do-executor.md
check G3 CORRETO 2 "$(run_gate "$r")" "objecao do Executor SEM waiver"

# G4: entrada apenas 'pendente' => BLOQUEIA
r="$(new_repo main)"
write_ledger "$r" "## [2026-06-20] main | [governance] x | pendente | ref"
echo x > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md .engrama/qa/criticas-do-executor.md
check G4 CORRETO 2 "$(run_gate "$r")" "critica ainda 'pendente'"

# G5: branch 'slice/1' NAO casa entrada de 'slice/10' => BLOQUEIA
r="$(new_repo slice/1)"
write_ledger "$r" "## [2026-06-20] slice/10 | [governance] x | confirmo | ref"
echo x > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md .engrama/qa/criticas-do-executor.md
check G5 CORRETO 2 "$(run_gate "$r")" "slice/1 nao deve casar entrada de slice/10 (space-delimited)"

# G6: arquivo NAO-sensivel => LIBERA (gate nao e burocracia universal)
r="$(new_repo main)"
write_ledger "$r" "# ledger"
echo x > "$r/README-do-produto.txt"
git -C "$r" add README-do-produto.txt
check G6 CORRETO 0 "$(run_gate "$r")" "arquivo fora de superficie sensivel"

# ── RED: furos reais (comportamento atual e inseguro) ─────────────────────────

# R1: AUTO-APROVACAO no MESMO commit — autor escreve 'confirmo' e comita junto.
#     O gate nao distingue prova independente de auto-atestado => LIBERA (FURO).
r="$(new_repo main)"
write_ledger "$r" "## [2026-06-20] main | [governance] eu mesmo aprovei | confirmo | ref"
echo x > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md .engrama/qa/criticas-do-executor.md
check R1 FURO 0 "$(run_gate "$r")" "auto-aprovacao no mesmo commit (sem identidade/diff independente)"

# R2: FALSO-POSITIVO por substring — 'nao confirmo' contem 'confirmo' => LIBERA (FURO).
r="$(new_repo main)"
write_ledger "$r" "## [2026-06-20] main | [governance] x | nao confirmo, tenho ressalvas serias | ref"
echo x > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md .engrama/qa/criticas-do-executor.md
check R2 FURO 0 "$(run_gate "$r")" "'nao confirmo' libera porque casa substring 'confirmo'"

# R3: PATH NON-ASCII — git quota o nome ("...decis\303\243o.md") e classify() nao
#     casa o leading-quote => CATS vazio => LIBERA (FURO). Isolado: NAO stageia o
#     ledger (que e .engrama/qa/* e por si so dispararia 'governance' e mascararia
#     o teste). Controle ASCII (G2) prova que o mesmo arquivo sem acento BLOQUEIA.
r="$(new_repo main)"
echo x > "$r/.engrama/governance/decisão.md"
git -C "$r" add ".engrama/governance/decisão.md"
check R3 FURO 0 "$(run_gate "$r")" "arquivo sensivel acentuado escapa a classificacao (fail-open; controle ASCII bloqueia)"

# R4: DETACHED HEAD com linha de ledger contendo espaco-duplo => casa BRANCH vazio (FURO).
r="$(new_repo main)"
write_ledger "$r" "## [2026-06-20] qualquer  | [governance] x | confirmo | ref"
echo base > "$r/base.txt"; git -C "$r" add .; git -C "$r" commit -qm base
git -C "$r" checkout -q --detach
echo x > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md .engrama/qa/criticas-do-executor.md
check R4 FURO 0 "$(run_gate "$r")" "detached HEAD: BRANCH vazio casa espaco-duplo no ledger"

# G7: o gate le o ledger STAGED, nao o working-tree (prova o ponto forte).
#     Stageia gov + ledger COM 'confirmo'; depois SUJA o working-tree (sem stage).
#     Gate deve LIBERAR (le o staged, nao o disco).
r="$(new_repo main)"
write_ledger "$r" "## [2026-06-20] main | [governance] x | confirmo | ref"
echo x > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md .engrama/qa/criticas-do-executor.md
printf 'LIXO no working-tree sem confirmo\n' > "$r/.engrama/qa/criticas-do-executor.md"
check G7 CORRETO 0 "$(run_gate "$r")" "le o ledger STAGED, ignora o working-tree sujo"

# R5: BYPASS cross-branch (achado da critica do Executor) — grep livre na linha
#     inteira: entrada de OUTRA branch que MENCIONA 'main' no texto livre libera main.
r="$(new_repo main)"
write_ledger "$r" "## [2026-06-20] outra | [governance] afeta o fluxo main do produto | confirmo | ref"
echo x > "$r/.engrama/governance/p.md"
git -C "$r" add .engrama/governance/p.md .engrama/qa/criticas-do-executor.md
check R5 FURO 0 "$(run_gate "$r")" "entrada de 'outra' branch que cita 'main' no texto libera (grep livre, nao por campo)"

# ── RELATORIO ─────────────────────────────────────────────────────────────────
printf '%b\n' "$RESULTS"
echo ""
echo "Resumo: $PASS asserts batidos, $FAIL divergentes | $HOLES casos marcados FURO (a corrigir)"
echo "Legenda: 'ok' = gate fez o esperado neste teste; CORRETO = comportamento bom; FURO = comportamento atual inseguro."
[ "$FAIL" -eq 0 ] || exit 1
