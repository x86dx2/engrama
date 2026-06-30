---
type: roadmap
status: resolved
critica_tecnica: incorporada
touches: [memory/decisions/0006-governanca-nao-se-autoaprova, memory/decisions/0010-roteamento-modelo-effort-do-executor, memory/governance/modelo-operacional, evidence/qa/criticas-do-executor]
date: 2026-06-30
source_refs:
  - .engrama/engine/scripts/critique-gate.sh
  - .engrama/engine/scripts/critique-gate-hook.sh
  - bin/install.sh
  - tests/gate/critique-gate.test.sh
  - tests/contract/bootstrap.test.sh
  - .engrama/memory/decisions/0011-diff-binding-atestacao-verificavel.md
  - .engrama/memory/decisions/0016-runtime-model-router-usage-ledger.md
---

Auditoria imparcial do Engrama (3 fontes independentes — leitura manual, workflow multi-agente de 47 agentes/39 achados confirmados, crítica externa do `codex`) **validada por testes** e **revisada pela crítica do Executor** (`codex exec`, veredito `discordo` → ajustes incorporados; ver [[evidence/qa/criticas-do-executor]]). Registra o que está **comprovadamente correto**, o que é **furo comprovado por teste**, e o **plano completo de remediação** por fases. Governança → não se autoaprova: o commit depende da Autoridade.

## Revisão 2026-06-30 — resolvido como roadmap histórico

Esta página não é mais backlog ativo. Ela permanece como **registro histórico da auditoria inicial** que originou o endurecimento do gate, diff-binding, CI server-side, sync raiz↔template, versionamento e disciplina de honestidade.

Estado atual:

- P0/P1/P2/P3 foram absorvidos por PRs posteriores e por ADRs ativas, principalmente [[memory/decisions/0006-governanca-nao-se-autoaprova]], [[memory/decisions/0011-diff-binding-atestacao-verificavel]], [[memory/decisions/0014-gate-de-release-repo-central]] e [[memory/decisions/0016-runtime-model-router-usage-ledger]].
- O gap [[memory/gaps/follow-ups-pos-0.2.0]] fechou as duas ressalvas remanescentes da release 0.2.0 no PR #21.
- O residual **R1 identidade do crítico** permanece teto aceito: o gate prova cobertura do diff, não identidade criptográfica ou independente do crítico. A mitigação vigente é server-side: CI required + diff-binding estrito.
- A ressalva de PR multi-commit continua como limite operacional documentado na ADR 0011.

Uso correto desta página daqui em diante: citar como origem/diagnóstico da remediação, não como lista viva de tarefas.

## STATUS FINAL (2026-06-20) — roadmap entregue

| Fase | Estado | Commit |
|------|--------|--------|
| P0.1 instalador (`#`/`&` + fail-closed) | ✅ | 8518b37 |
| P0.2/P0.3 CI + classify + R3/R4 + hook | ✅ | 335e696 |
| R2/R5 parsing por campo | ✅ | f024029 |
| P0.4 honestidade + P3 higiene (LICENSE/CHANGELOG/schema) | ✅ | 735e3eb |
| P2 sync-template + propaga fixes ao template + drift (EX2) | ✅ | 9b8da4e |
| P2b CI reexecuta o gate contra o PR (`critique-gate-ci.sh`) | ✅ | (esta fatia) |

**Furos:** 7 dos 8 fechados e travados por teste (C5/C6/C7 · R2/R3/R4/R5). **R1** (auto-aprovação local) **mitigado server-side**: a CI reexecuta o gate contra o PR e o job `test` (que embute esse gate) **está marcado como *required*** no *branch protection* — o bloqueio de merge é **vinculante**. Com a unificação do fingerprint, o **modo estrito do diff-binding voltou a ficar ligado na CI**; o teto remanescente é de **identidade do crítico**, não mais de consistência de hash. O modelo de governança foi dogfoodado em cada fatia (Executor escreve, Orquestrador audita, ledger registra, gate ao vivo) e **pegou erros reais no trabalho do Orquestrador 3×**.

## Método (por que confiar)

Cruzei três análises e **fact-checkei até os próprios críticos**: refutei 1 alegação do `codex` (`tests/contract/*` em `case` do bash **casa** subpastas — `*` casa `/`); e **incorporei a crítica do Executor**, que pegou erros factuais e fragilidades nos meus próprios testes (ver seção final). Cada achado aponta o **teste que o prova** (`tests/run.sh`: 20 asserts, fail-fast sob setup quebrado).

## Veredito empírico — o que está CORRETO (provado, proteger contra regressão)

| ID | Comportamento provado correto |
|----|-------------------------------|
| G1 | governança **com** crítica `confirmo` → gate **libera** |
| G2 | governança **sem** crítica → **bloqueia** |
| G3 | objeção sem `waiver` → **bloqueia** |
| G4 | crítica só `pendente` → **bloqueia** |
| G5 | `slice/1` **não** casa `slice/10` (branch space-delimited) |
| G6 | arquivo fora de superfície sensível → **libera** |
| G7 | gate lê o ledger **staged**, ignora o working-tree sujo (não dá pra forjar só no disco) |
| C1–C4 | install zera placeholders · seta `core.hooksPath` · recusa colisão · sem `.govtmp` órfão |
| C8 | `bootstrap.sh` (caminho canônico) em dir não-git: git-init + instala + zero placeholders |
| — | `shellcheck` limpo nos **5 scripts originais** (install/bootstrap/critique-gate/hook/pre-commit) **e** nas suítes |

Núcleo conceitual (tríade, ADR 0004, filosofia de teste RED-first/golden) **fica**.

## Veredito empírico — o que precisa MUDAR (furo comprovado por teste)

| ID | Sev | Furo (comprovado) | Teste |
|----|-----|-------------------|-------|
| **C6/C7** | **CRÍTICO** | um `#` em qualquer valor faz `sed -f` falhar **global** → install deixa **todos** os placeholders crus (observado: 16) e retorna **exit 0** ("sucesso" falso). `#` é input comum. | `contract C6/C7` |
| **R1** | **CRÍTICO** | auto-aprovação no mesmo commit: autor escreve `confirmo` e comita junto; gate **libera**. Sem vínculo ao diff, sem identidade independente, `EXECUTOR_CMD` nunca executado. | `gate R1` |
| **C5** | ALTO | valor com `&` corrompe a substituição (não preservado literalmente). | `gate/contract C5` |
| **R3** | ALTO | path non-ASCII escapa o `classify()` (git quota o nome) → **fail-open**; controle ASCII bloqueia. | `gate R3` |
| **R5** | ALTO | **bypass cross-branch** (achado da crítica do Executor): `grep` livre na linha inteira → entrada de **outra** branch que menciona o nome da branch atual no texto livre **libera**. | `gate R5` |
| **R2** | MÉDIO | `nao confirmo` libera por casar o substring `confirmo`. | `gate R2` |
| **R4** | MÉDIO | detached HEAD (`BRANCH` vazio) casa espaço-duplo no ledger → false-allow. | `gate R4` |
| **EX1** | ALTO | enforcement burlável: `--no-verify`, `git -c core.hooksPath=/dev/null`, commit fora do harness; `PreToolUse` fail-open se faltar `python3`. Sem CI/server-side. | manual |
| **EX2** | ALTO | **drift sem trilho de sync**: `sync-template.sh` é referenciado em `critique-gate.sh:51` mas **não existe**; `install.sh` copia só de `template/`; raiz e template divergem estruturalmente (a raiz cabeia paths `template/*`; o template carrega 4 exemplos de domínio comentados). *(Correção factual da crítica: ambos têm 3 categorias ATIVAS — não "3 vs 7".)* | manual |
| **EX3** | MÉDIO | claims absolutistas no `README.md` vs realidade de lembrete cooperativo; ADR 0006 diz "crítica no bootstrap", ledger diz `dispensada`. | manual |
| **EX4** | MÉDIO | `source_refs` absolutos contradizem portabilidade; schema "Estrutura" em `.engrama/CLAUDE.md` lista dirs inexistentes; defaults `gpt-5.x` hardcoded como PADRÃO. | manual |
| **EX5** | MÉDIO | `.engrama/memory/gaps/` (e `memory/roadmap/`, `memory/domain/`) e `tests/gate/` **não estão no `classify()`** → governança e os testes do gate **escapam o gate** (demonstrado ao vivo: este plano passou sem crítica exigida). | live |
| **EX6** | MÉDIO | sem teste/cobertura do hook `critique-gate-hook.sh` (parse JSON + `python3` + interceptação de `git commit`). | manual |
| **EX7** | BAIXO | sem `LICENSE`, `CHANGELOG`, versão; sem `.github/workflows`. | manual |

Achado-bônus: stageiar o próprio ledger (`.engrama/evidence/qa/*`) já classifica como `governance`.

## Plano de remediação (por fases) — ordem revista pela crítica do Executor

### P0 — Estancar dano determinístico + rede de segurança (alto impacto, baixo esforço)
1. ✅ **FEITO (branch `fix/p0-instalador-substituicao-segura`).** Instalador corrigido via executor-bridge: `escape_sed_replacement()` (escapa `\`/`&`/`#`) + `find -print0`/`read -d ''` + **fail-closed** (aborta `exit 1` se sobrar placeholder). `C5/C6/C7` promovidos a CORRETO; `C9` adversário adicionado; suíte 9/9 verde; shellcheck limpo. Resta `*.govtmp` no `.gitignore` (P3).
2. **CI** `.github/workflows/ci.yml`: matriz `ubuntu`+`macos` rodando `shellcheck` + `bash tests/run.sh`. Como **required status check** + branch protection, vira a **única camada de enforcement não-burlável**. → fecha parte de EX1.
3. **Cabear os testes no `classify()` de forma explícita** (não `tests/*` amplo): `tests/gate/* → gate`, `tests/contract/* → contract`; e **`.engrama/memory/gaps|roadmap|memory/domain/* → governance`**. → fecha EX5.
4. **Alinhar claims à verdade.** Reescrever `README.md` (l.49-51) e [[memory/decisions/0006-governanca-nao-se-autoaprova]] para "lembrete imposto no caminho cooperativo, deliberadamente burlável; garantia real = CI/server-side". Reconciliar ADR 0006 ↔ ledger (`dispensada`). → fecha EX3.

### P1 — Endurecer o gate (fail-open → fail-closed)
5. **Classificação robusta:** `git diff --cached --name-only -z` **em stream direto** + `read -r -d ''` (resolve non-ASCII; com `-z`, `quotePath=false` é redundante — *correção da crítica*). → promove `R3`.
6. **`BRANCH` vazio = fail-closed** explícito (detached HEAD bloqueia). → promove `R4`.
7. **Parsing por campo, não substring:** ledger vira **gramática rígida** (campos delimitados por `|`, literal `|` proibido nos campos, espaços normalizados) e o gate lê o veredito com `awk -F'|'` **por campo da linha da branch certa** — fecha `R2` **e** `R5` (o bypass cross-branch some quando a branch é um campo, não substring na linha). → promove `R2`+`R5`.
8. **`python3` fail-closed** no hook + **teste do hook** (`tests/gate/hook.test.sh`: intercepta `git commit`, bloqueia sem `python3`, ignora não-commits). → fecha EX1(parcial)+EX6.

### P2 — Transformar lembrete em controle + fonte única
9. **Vincular a prova ao diff:** gravar `sha256` do `git diff --cached` **excluindo o ledger** (senão é autorreferência — *correção da crítica*) na linha do ledger; o gate recomputa e exige match (1 crítica = 1 diff, não a branch toda). Isso fecha o **vínculo ao conteúdo**, mas **não** a **independência do revisor** → ver P2.10. → promove `R1` (vínculo).
10. **Independência real só server-side:** required check em CI (P0.2) que reexecuta o gate + trailer `Executor: <modelo/response_id>` verificado; opcional `pre-receive`. É onde "escritor ≠ auditor" deixa de ser honra. → fecha o restante de `R1`/EX1.
11. **Fonte única raiz↔template:** criar `sync-template.sh` (gerador raiz→template) + check de CI que falha em diff não-placeholder; resolver a referência fantasma de `critique-gate.sh:51`. → fecha EX2.

### P3 — Higiene e coerência (baixo esforço)
12. `LICENSE` + `CHANGELOG` + `{{ENGRAMA_VERSION}}` injetado no `.engrama` instalado. → fecha EX7.
13. Corrigir o bloco "Estrutura" de `.engrama/CLAUDE.md`; seção de pré-requisitos; preencher `Dependências` no template. → fecha EX4(parcial).
14. Decidir `source_refs` relativos / URI `repo://`; separar **núcleo** de **adaptadores de vendor** (codex/claude). → fecha EX4 + lema "por função, não por vendor".

## Crítica do Executor (codex) — incorporada (dogfood do ADR 0006)

Esta sessão rodou o **executor-bridge real**: o Orquestrador autorou, o Executor (`codex exec`, read-only) criticou **antes do commit**, veredito **`discordo`** com 13 objeções. Incorporado:
- **Testes fail-fast** (objeção central): suítes agora **abortam (exit 3)** sob `mktemp`/`git` quebrados, em vez de falso-verde — provado.
- **EX2 corrigido** (era "3 vs 7"; são 3 ativas em ambos).
- **Overclaims removidos** (C5/C6 alinhados ao que o teste prova; "shellcheck limpo" qualificado).
- **R5 adicionado** (bypass cross-branch) + **C8** (cobre `bootstrap.sh`, não só `install.sh`).
- **R1 reformulado** (sha256 = vínculo ao conteúdo, exclui o ledger; independência ≠ vínculo, exige server-side).
- **P0 reordenado** (instalador determinístico antes de doc); **P0.3 explícito** por subpasta; **hook test** (EX6) e refinamentos `-z`/`awk` adicionados.

**Residual escalado à Autoridade:** o veredito foi `discordo` (governança/gate é material). Por ADR 0004/0006, o Orquestrador **não comita por conta própria**: incorporou os ajustes e **apresenta à Autoridade** para a decisão de commit (consenso sobre o artefato revisado ou nova rodada).

## Critério de pronto original — status revisado em 2026-06-30

- [x] Crítica do Executor registrada em [[evidence/qa/criticas-do-executor]] (`critica_tecnica → incorporada`).
- [x] Suítes `tests/` verdes, shellcheck-limpas e fail-fast (20 asserts, 8 furos caracterizados).
- [x] Decisão da Autoridade sobre este commit (governança não se autoaprova; Executor `discordo` incorporado).
- [x] P0–P2: furos fecháveis promovidos e travados por teste; R1 identidade do crítico reclassificado como teto aceito/mitigado, não bug aberto.
- [x] `sync-template.sh` + CI que reexecuta o gate; referência fantasma resolvida.
- [x] Required check ativo no *branch protection* (job `test` embute o gate-contra-PR) → enforcement vinculante.
- [x] ADRs 0011+ formalizam vínculo-ao-diff, enforcement server-side, fonte única, testes portáveis e roteamento runtime.

## Pendências aceitas / tetos (2026-06-21)

Itens que permanecem abertos por **limitação inerente** ou decisão consciente (não são regressões):

- **R1 — identidade do crítico (teto inerente):** o diff-binding prova *cobertura do diff*, não *identidade independente* do crítico. Fechar exigiria assinatura/chave que o `codex exec` não expõe. **Aceito**; mitigado server-side pelo *required check*.
- **Diff-binding em PR multi-commit:** o fingerprint na CI cobre o **diff cumulativo** de `base...HEAD`, não cada commit isoladamente. O fluxo recomendado continua sendo squash/PR de 1 commit. Ver [[memory/decisions/0011-diff-binding-atestacao-verificavel]].
- **EX4 — portabilidade/vendor:** `source_refs` absolutos (migrar p/ relativos) e ids de modelo `gpt-5.x` + canal `codex exec` hardcoded (separar núcleo de adaptadores). Em correção.
- **Cerimônia/dormência:** ADR 0007 (computer-use) e ADR 0010 (5 tiers) dormentes nesta instância; ADR 0009 (produção) `proposed` até existir deploy.
