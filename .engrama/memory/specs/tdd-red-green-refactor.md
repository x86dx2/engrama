---
type: spec
status: active
touches: [memory/specs/test-writing, memory/specs/executor, memory/decisions/0005-orquestrador-qa-reexecucao-e-metricas, memory/decisions/0015-absorcao-seletiva-metodologia-superpowers]
date: 2026-06-27
source_refs:
  - .engrama/memory/specs/test-writing.md
reconcilia: UPDATE memory/specs/test-writing
---

Disciplina **test-first** em loop estrito. Complementa [[memory/specs/test-writing]] (que já cita o ciclo RED→GREEN com as convenções de harness do projeto) formalizando a **ordem** e o passo **REFACTOR**. Absorvida do Superpowers (ver [[memory/decisions/0015-absorcao-seletiva-metodologia-superpowers]]).

## O loop

1. **RED** — escreva o teste do comportamento **antes** do código. Rode e veja-o **falhar** pelo motivo certo (não por erro de setup). Falha não-vácua é a prova de que o teste exerce o comportamento.
2. **GREEN** — escreva o **mínimo** de código para o teste passar. Nada de generalização especulativa.
3. **REFACTOR** — com a suíte verde, limpe (nomes, duplicação, estrutura). Os testes verdes são a rede; se ficarem vermelhos, o refactor mudou comportamento.

## Regras

- Um **comportamento por ciclo**; não acumule vários testes vermelhos.
- Não escreva código de produção sem um teste falhando que o exija.
- Rode a suíte ao fim de cada passo; o Orquestrador re-executa na auditoria ([[memory/decisions/0005-orquestrador-qa-reexecucao-e-metricas]]).
- Convenções concretas (framework, golden files, unit/integração/e2e) vivem em [[memory/specs/test-writing]] — esta spec é só a **disciplina**, não as ferramentas.

## Aplicada por

**Executor** (sob spec), ao escrever código de fatia. O Orquestrador valida a não-vacuidade do RED na auditoria. Quando a fatia não produz código testável (ex.: doc/governança), a spec é **N/A** — registre o motivo.
