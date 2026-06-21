---
type: spec
status: active
touches: [specs/orquestrador, specs/executor, specs/executor-order, specs/commit, specs/test-writing, specs/infra-runbook]
date: {{DATA}}
source_refs:
  - .engrama/specs/
---

Biblioteca de **specs operacionais** — playbooks/checklists reaproveitáveis para tarefas recorrentes. São o **"como"**; o **"porquê/normativo"** vive em `.engrama/governance/` e `.engrama/decisions/` (ADRs). Specs **apontam** pra governança, não duplicam.

## Princípio: spec ≠ subagente
- **Spec** = regras/checklist de uma tarefa. Doc versionado. Aplicado **pelo Orquestrador ou pelo Executor**.
- **Subagente** só quando há **isolamento, paralelismo ou independência** (ex.: análise paralela; o executor independente é o Executor). Tarefa sem esses 3 (ex.: commit) usa **spec, não subagente**.
- Não reinventar "100 agentes" via tooling de swarm. Papéis reais = tríade (Orquestrador/Executor/Autoridade) + subagentes nativos do Orquestrador só na lane de análise. Qualquer tooling de swarm/orquestração de subagentes é subordinado a este modelo — não o substitui.

## Specs
| Spec | O quê | Aplicada por |
|---|---|---|
| [[specs/orquestrador]] | playbook do Orquestrador (rotear tier, dispatch, auditar, commitar, colar I/O) | Orquestrador |
| [[specs/executor]] | invocar o Executor nas 3 variações (código · crítica · computer-use) | Orquestrador→Executor |
| [[specs/executor-order]] | template da ordem ao Executor (10 itens + tier + aceite) | Orquestrador |
| [[specs/commit]] | checklist de commit | Orquestrador |
| [[specs/test-writing]] | convenções do harness de teste do seu projeto (framework de unit/integração/e2e, golden files, ciclo RED→GREEN) | Executor (sob spec) |
| [[specs/infra-runbook]] | ops: provisionar/seedar ambiente, subir/matar o dev server local (`{{DEV_URL}}`), recriar golden/baseline | Orquestrador/Executor |
| [[specs/licao-aprendida]] | loop **falha→regra**: toda falha relevante vira regra durável (gate/lint/teste/ADR) | Orquestrador |

> Template: as linhas `test-writing` e `infra-runbook` são **agnósticas de stack** no pack. Preencha-as com as ferramentas concretas do seu projeto (runner de teste, banco/migrations, comando de dev server, host de CI/git) sem alterar os papéis nem o princípio spec ≠ subagente.

## Governança que rege (não duplicar — referenciar)
Tríade e alçadas: [[governance/papeis-e-alcadas]] · protocolo: [[governance/cadeia-de-comando]] · roteamento modelo/effort: [[decisions/0010-roteamento-modelo-effort-do-executor]] · executor-bridge: [[decisions/0003-executor-bridge-orquestrador-invoca-executor]] · QA: [[decisions/0005-orquestrador-qa-reexecucao-e-metricas]].

> Specs são operacionais: se uma introduzir **regra nova** (não só aplicar regra existente), essa parte vai à **crítica do Executor** (ADR 0006) antes de virar normativa.
