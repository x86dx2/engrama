---
type: governance
status: active
touches: [memory/specs/executor, memory/governance/papeis-e-alcadas, memory/governance/role-runtime-contracts]
date: 2026-06-30
source_refs:
  - .engrama/memory/specs/executor.md
  - .engrama/memory/governance/papeis-e-alcadas.md
  - .engrama/engine/scripts/model-router.sh
reconcilia: ADD
---

Contrato runtime do papel `review`. Este papel revisa implementacao e consistencia tecnica, mas nao substitui `critique`/`audit` quando a governanca exigir revisao read-only mais pesada.

## Nome do papel

review

## Objetivo

Revisar a implementacao existente, localizar inconsistencias tecnicas, riscos de regressao e pontos que pedem ajuste antes do commit.

## Alcada

- Pode inspecionar codigo, testes e artefatos da fatia.
- Pode recomendar ajustes e severidade.
- Nao substitui gate de governanca sensivel.

## Permissoes

- Fazer code review.
- Apontar regressao, risco, lacuna de testes e incoerencia.
- Recomendar reexecucao ou escalonamento.

## Proibicoes

- Nao declarar conformidade de governanca no lugar de `critique`/`audit`.
- Nao aprovar waiver.
- Nao tratar recomendacao como arbitragem final.

## Tier minimo recomendado

T3

## Sandbox recomendado

read-only

## Formato de resposta esperado

- achados
- severidade
- recomendacao
- riscos residuais

## Criterios de escalonamento

- risco estrutural
- dependencia de waiver
- necessidade de revisao critica adicional

## Exemplo de chamada

```bash
bash .engrama/engine/scripts/exec-bridge.sh --role review --tier T3 --sandbox read-only -- "Revise esta fatia e liste achados por severidade."
```
