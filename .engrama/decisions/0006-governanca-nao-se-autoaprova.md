---
type: decision
status: active
touches: [governance/cadeia-de-comando, governance/papeis-e-alcadas, decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade]
date: 2026-06-20
source_refs:
  - /Users/x86/git-projects/engrama/.engrama/scripts/critique-gate.sh
  - /Users/x86/git-projects/engrama/.engrama/qa/criticas-do-executor.md
---

**Governança não se autoaprova.** Toda edição de governança passa por **crítica independente do Executor antes do commit**: consenso → comita; discordância/impasse → escala à Autoridade (o Executor tem voz, não veto; a Autoridade pode dispensar).

## Contexto
Para **código**, a validação cruzada é estrutural (o Executor escreve, o Orquestrador audita). Para **governança**, o Orquestrador autora **e** comitaria — o último ponto de auto-aprovação. Esta ADR fecha isso.

## Decisão
1. O Orquestrador **autora** a mudança e **invoca o Executor** com o pedido de crítica (diff + intenção + fronteiras).
2. O Executor devolve crítica técnica.
3. **Consenso → o Orquestrador comita.** **Discordância/impasse → o Orquestrador apresenta à Autoridade** (consistente com [[decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade]]).
4. Sem Executor disponível → a governança **aguarda** no pré-commit (salvo dispensa da Autoridade).

Escopo amplo: `.engrama/governance/*`, ADRs, `AGENTS.md`, seções de governança do `CLAUDE.md`.

**Item 7:** análise de causa-raiz/veredito do Orquestrador em **superfície sensível** (fluxo principal, invariante, RBAC, segurança, arquitetura operacional — tipicamente as páginas de `gaps/` do seu projeto) também passa por crítica do Executor como **gate de uso** (não de commit): registrar o **fato** é livre; **usar** a análise (ordem/correção/fatia/aceite) exige a crítica. Estado em `critica_tecnica: pendente|confirmada|incorporada|escalada|dispensada` no front matter.

## Consequências
- Toda regra de governança **passa pela crítica do Executor antes do commit** — exceto o bootstrap inicial, cuja crítica foi `dispensada` pela Autoridade (chicken-and-egg; ver abaixo).
- **Bootstrap (chicken-and-egg, honesto):** o engrama **inicial** teve a crítica externa **dispensada** pela Autoridade (registrado como `dispensada` em [[qa/criticas-do-executor]]) — o gate precisava existir antes de poder exigir a prova de crítica. A partir do primeiro engrama, a regra passa a se aplicar a si mesma (toda edição de governança seguinte vai à crítica do Executor).
- Registrar o estado da crítica em cada commit de governança (`consenso`/`incorporado`/`escalado`/`dispensado`).

## Promoção a gate de commit mecânico (2026-06-20)

O item 7 era um **gate de uso** (confiava na disciplina do Orquestrador de criticar antes de *usar* a análise). Na prática isso falha: a disciplina de memória não substitui um freio mecânico.

> Exemplo (troque pelo do seu projeto): um veredito de superfície sensível (p.ex. um bug-vs-golden de RBAC) levado à arbitragem da Autoridade **sem a crítica precedente do Executor**, apoiado em qualquer tooling de swarm/orquestração de subagentes do Orquestrador como se fosse QA — o que **não substitui** a crítica do Executor (escritor≠auditor exige um agente/modelo independente; subagentes nativos do Orquestrador são lane do Orquestrador, [[decisions/0008-subagentes-so-na-lane-do-orquestrador]]).

**Decisão (Autoridade, 2026-06-20):** para **superfície sensível de código** — RBAC/permissões, fluxo financeiro, auth (auth/rate-limit/rotas auth+cron), schema (migrations), contratos golden e o próprio mecanismo do gate — além de governança, o gate passa de "uso" para **commit mecânico** (categorias: `financial · rbac · auth · schema · governance · gate · contract`):

1. Antes de comitar mudança que toque essas superfícies, a **crítica do Executor (gpt-5.5, read-only)** é obrigatória e registrada em [[qa/criticas-do-executor]] (por categoria, citando a branch).
2. O hook `.engrama/scripts/critique-gate.sh` (git pre-commit via `core.hooksPath .engrama/githooks` + PreToolUse do harness do Orquestrador, que pega `git commit` inclusive `--no-verify`) **bloqueia o commit** se faltar a entrada concluída — rejeita `<pendente>` e bloqueia `objeção` sem `waiver` (a Autoridade arbitra a objeção; "o Executor tem voz, não veto" → o waiver registra a arbitragem).
3. Override consciente p/ trivialidades: `N/A: <motivo>` no ledger (não silencioso).

> **Fronteira honesta do enforcement.** O hook local é **freio cooperativo**, não barreira inviolável: `git commit --no-verify`, `git -c core.hooksPath=/dev/null` e commits fora do harness do Orquestrador passam por cima dele; o `PreToolUse` só cobre o harness Claude. A garantia vinculante exigiria **enforcement server-side** — um *required status check* que reexecute o gate contra o diff do PR. **Hoje isso não existe:** a CI (`.github/workflows/ci.yml`) roda `shellcheck` + a suíte de testes, mas **não** reexecuta o gate contra o PR; *required check* é configuração de repositório. O gate garante que a crítica esteja **registrada**, não que um modelo independente de fato a tenha produzido — a independência é estrutural (Executor é processo separado), **não** provada pelo hook. **Furo R1 (aberto):** localmente o mesmo autor pode escrever `confirmo` e comitar; a mitigação (gate como required check na CI + vínculo ao diff) é **pendente** — ver [[gaps/auditoria-e-plano-de-remediacao]].

> Template: as categorias `governance · gate · contract` são **universais** (mantêm-se em qualquer projeto). As categorias `financial · rbac · auth · schema` são **ilustrativas do domínio** — adapte-as no `classify()` de `.engrama/scripts/critique-gate.sh` às superfícies sensíveis reais do seu produto (mapeie arquivo→categoria conforme seu layout).

Isso **não** dá veto ao Executor: objeção material continua indo à Autoridade ([[decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade]]); o gate só garante que a crítica **aconteça e fique registrada** antes do commit. Não depende da memória do Orquestrador.

## Ajustes incorporados (auto-aplicação no bootstrap, 2026-06-20)

- **Escopo do "gate de uso" (item 7) restringido:** a crítica do Executor à análise sensível do Orquestrador é gate de uso **apenas quando a análise vai mudar execução, aceite ou arquitetura** — não para qualquer análise meramente registrada. Evita travar operação por ambiguidade.
- **Sem regresso infinito:** incorporar os **ajustes sugeridos pelo próprio Executor** na crítica (veredito `ajuste-menor`) ou aplicar a **decisão explícita da Autoridade** **constitui consenso** — não exige um novo ciclo de crítica sobre os mesmos ajustes. Uma mudança de governança **substantiva e nova** (não a mera incorporação da crítica) reinicia o ciclo.
- **Provê o trilho deste bootstrap:** crítica do Executor = `ajuste-menor` (ajustes) → incorporados + decisão da Autoridade sobre override (dupla confirmação) → estado `incorporado`/`consenso`. Ver [[log]].
