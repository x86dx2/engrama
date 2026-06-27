---
type: spec
status: active
touches: [memory/specs/licao-aprendida, memory/specs/tdd-red-green-refactor, memory/governance/modelo-operacional, memory/domain/validacao-cruzada-estrutural, memory/decisions/0005-orquestrador-qa-reexecucao-e-metricas, memory/decisions/0015-absorcao-seletiva-metodologia-superpowers]
date: 2026-06-27
source_refs:
  - .engrama/memory/specs/licao-aprendida.md
reconcilia: UPDATE memory/specs/licao-aprendida
---

Análise de causa-raiz **em fases, antes de corrigir** — em vez de tentativa-e-erro. Complementa o loop falha→regra de [[memory/specs/licao-aprendida]]: a depuração acha a causa; a lição transforma a causa em regra durável. Absorvida do Superpowers (ver [[memory/decisions/0015-absorcao-seletiva-metodologia-superpowers]]).

## As 4 fases

1. **Reproduzir e isolar** — torne a falha determinística e reduza ao menor caso que ainda falha. Sem reprodução estável, não há diagnóstico, só palpite.
2. **Hipótese de causa** — formule a causa-raiz provável (não o sintoma). Uma hipótese falsificável por vez.
3. **Provar a causa** — um teste/experimento mínimo que confirme a hipótese (e falharia se ela fosse falsa). Sem este passo, o "fix" é coincidência.
4. **Corrigir + regra** — aplique a correção e converta a causa numa **regra durável** (teste de regressão, gate, lint ou ADR) via [[memory/specs/licao-aprendida]].

## Regras

- Não corrija antes da fase 3. "Parece que resolveu" sem prova de causa é dívida.
- O teste que prova a causa vira regressão (cruza com [[memory/specs/tdd-red-green-refactor]]).
- O Orquestrador re-executa a reprodução na auditoria ([[memory/decisions/0005-orquestrador-qa-reexecucao-e-metricas]]).

## Aplicada por

**Executor** diagnostica e **corrige o código** — correção de fatia é sempre do Executor ([[memory/governance/modelo-operacional]]). O **Orquestrador** reproduz/isola na auditoria e **exige a regra durável**, mas **não corrige código**: achada a causa, a correção volta ao Executor (escritor ≠ auditor — [[memory/domain/validacao-cruzada-estrutural]]).
