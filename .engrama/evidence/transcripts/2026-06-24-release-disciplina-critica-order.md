# ORDEM (FASE 1 = CRÍTICA READ-ONLY) — disciplina de release mecânica + 0.2.0

**Sandbox READ-ONLY. NÃO execute, NÃO edite, NÃO mova nada.** Critique o PLANO: riscos, gaps, falsos-positivos,
ordering, e dê veredito (`concordo`/`ajuste-menor`/`discordo`) sobre se está sólido para uma FASE 2.
Cace o que eu não mapeei. O foco é o **gate de release** (item B) — é a parte de design que mais pode ter furo.

## Contexto (causa-raiz)
Duas fatias estruturais (PR #14 consolidacao, PR #15 reorg memory/engine/evidence) subiram SEM bump de VERSION
nem CHANGELOG. Causa: a disciplina de release dependia SÓ de memória — não há gate/lint/CI que acople
"mudança no pack distribuível" -> "bump de VERSION + CHANGELOG". É o anti-padrão que o projeto existe pra matar
(modelo-operacional princ. 1 e 7; o critique-gate nasceu do mesmo lapso). A correção definitiva é MECÂNICA,
não "lembrar da próxima vez".

## Objetivo
1. Corrigir o sintoma: release 0.2.0.
2. Corrigir a CLASSE: gate de release mecânico (impede a reincidência).
3. Registrar a decisão (ADRs) e a lição.

## Escopo proposto

### A — Sintoma (release 0.2.0)
- `VERSION` 0.1.0 -> **0.2.0**.
- `CHANGELOG.md`: promover `## [Não lançado]` -> `## [0.2.0] - 2026-06-22`, documentando **consolidação** (#14: bin/critique-gate-ci + transcripts -> .engrama; endurecimento do exec-bridge) e **reorg** (#15: memory/engine/evidence). Criar nova `## [Não lançado]` vazia no topo.
- Corrigir o **anacronismo**: a entrada `## [0.1.0]` foi reescrita pelo rewrite de paths para `.engrama/engine/scripts/` — no 0.1.0 era `.engrama/scripts/`. Restaurar a verdade histórica dessa entrada.
- (Tag `v0.2.0` é git op do Orquestrador pós-merge — fora da sua fatia.)

### B — Gate de release (a correção de classe — CRITIQUE O DESIGN A FUNDO)
Intenção: toda mudança na **superfície distribuível** resulta em **bump de VERSION + entrada CHANGELOG correspondente**, OU numa decisão consciente e registrada de "sem release". Espelha o critique-gate (cooperativo local + binding na CI; escape logado).
- **Superfície distribuível (proposta — critique a definição):** `template/**`, `VERSION`, `.engrama/engine/scripts/**`, `.engrama/CLAUDE.md` (schema), `bin/**` (instalador). O que muda o que o adotante recebe ou como instala.
- **Mecânica proposta:**
  - **Invariante de acoplamento (no `lint.sh`):** `VERSION` deve ter uma entrada `## [<VERSION>]` correspondente no CHANGELOG (pega "bumpou VERSION sem CHANGELOG" e vice-versa). Erro bloqueante do lint.
  - **Check de release (novo, ex.: `.engrama/engine/scripts/release-gate.sh` ou função no lint):** dado um diff contra uma referência (na CI = base-ref do PR, como o critique-gate-ci; local = última tag `git describe`), se a superfície distribuível mudou E `VERSION` NÃO mudou vs a referência E não há escape -> **falha**.
  - **Local = WARNING (não bloqueia)** no `lint.sh` (mid-trabalho a versão ainda não foi decidida — igual à staleness, canal de warning separado). **CI = BLOQUEIA** (step no `ci.yml`, vinculante como o gate-CI).
  - **Escape:** linha `sem-release: <motivo>` na seção `## [Não lançado]` do CHANGELOG (espelha o `N/A: <motivo>` do critique-gate). Decisão consciente, versionada.
- Espelhar no template (o adotante herda a disciplina): via `sync-template.sh` se for script; e o `ci.yml` do template.
- Testes: `tests/` cobrindo (1) superfície mudou sem bump -> CI falha; (2) com bump+changelog -> passa; (3) escape `sem-release` -> passa; (4) VERSION sem entrada CHANGELOG -> lint erro.

### C — Docs + lição
- `CONTRIBUTING.md`: seção de **disciplina de release** (quando bumpar, SemVer 0.x, o gate, o escape).
- `.engrama/memory/specs/licao-aprendida.md`: registrar a lição (disciplina memória-dependente -> gate mecânico; mesma origem do critique-gate).

### D — ADRs (decisões que faltaram)
- ADR novo: **gate de release** (a decisão de adicionar o mecanismo + alternativas: CI-block vs lint-only; escape vs obrigatório).
- ADR novo: **reorg de .engrama por contexto** (a decisão estrutural do #15 que eu só loguei, sem ADR — contexto, alternativas cordão-vs-memory/, consequências). Retroativo, mas é o "por quê" durável.
- Numerar a partir de 0013. `reconcilia:` apropriado.

## Pontos pra você criticar com força
1. **Definição da superfície distribuível** — minha lista pega tudo? Pega demais (falso-positivo)? Ex.: mexer só num teste ou num doc interno (`.engrama/memory/**`) deveria exigir release? (Acho que não — não é shipado igual. Confirme.)
2. **Referência do diff** — última tag (`git describe --tags`) é robusta localmente? E quando não há tag? E na CI (base-ref do PR)? Há o risco de o fingerprint divergir local vs CI (já tivemos isso com o diff-binding).
3. **Escape `sem-release` no CHANGELOG** — é o lugar certo? Ou um marcador melhor?
4. **Bootstrap/instalação:** o gate de release não pode quebrar `install.sh`/`bootstrap.sh` num repo-alvo (lá o VERSION vem do placeholder).
5. **Fatiamento:** A+B+C+D num PR só é grande. Vale fatiar (ex.: A+D-reorg primeiro; B+C+D-release depois)? Ou 1 PR coeso?
6. Qualquer disciplina memória-dependente ADICIONAL que você veja sem freio mecânico (além de release) — é a pergunta de fundo da Autoridade: "se esqueceu isso, o que mais?".

NÃO execute. Só critique e proponha o melhor design.
