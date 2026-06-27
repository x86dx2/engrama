---
type: spec
status: active
touches: [memory/specs/executor-order, memory/governance/cadeia-de-comando, memory/domain/validacao-cruzada-estrutural, memory/decisions/0008-subagentes-so-na-lane-do-orquestrador, memory/decisions/0015-absorcao-seletiva-metodologia-superpowers]
date: 2026-06-27
source_refs:
  - .engrama/memory/specs/executor-order.md
reconcilia: UPDATE memory/specs/executor-order
---

Antes da ordem ao Executor: **refinar requisitos** (brainstorming) e **quebrar em tarefas pequenas com critério de aceite** (writing-plans). Alimenta o template de [[memory/specs/executor-order]]. Absorvida do Superpowers (ver [[memory/decisions/0015-absorcao-seletiva-metodologia-superpowers]]).

## Fase 1 — Brainstorming (refinar antes de codar)

- Fazer as perguntas que reduzem ambiguidade **antes** de qualquer código: o que é sucesso? o que está fora de escopo? quais fronteiras/superfícies sensíveis toca? (cruza com o `classify()` do gate).
- Saída: requisito enxuto e acordado. Sem isto, a ordem ao Executor parte de premissa frágil.

## Fase 2 — Plano (quebrar em fatias pequenas)

- Decompor em tarefas de granularidade pequena (alvo: minutos, não horas), cada uma com **critério de aceite explícito** e arquivos prováveis.
- Sequenciar por dependência; cada fatia deve ser auditável isoladamente (escritor ≠ auditor — [[memory/domain/validacao-cruzada-estrutural]]).
- O plano é insumo do [[memory/specs/executor-order]]; não substitui a ordem.

## Fronteiras (o que esta spec NÃO autoriza)

- Planejar **não** é executar em lote autônomo por horas sem checkpoints — o freio ativo do Executor e a arbitragem da Autoridade continuam ([[memory/governance/cadeia-de-comando]]).
- O Orquestrador **monta o plano**; o Executor **escreve o código** da fatia. Subagentes do Orquestrador ficam na lane de análise ([[memory/decisions/0008-subagentes-so-na-lane-do-orquestrador]]).

## Aplicada por

**Orquestrador** (monta brainstorm + plano) → **Executor** (recebe a ordem por fatia).
