---
type: decision
status: active
touches: [governance/papeis-e-alcadas, 0001-governanca-tres-papeis, 0003-executor-bridge-orquestrador-invoca-executor]
date: 2026-06-20
source_refs:
  - CLAUDE.md
---

O **Orquestrador é dono do ciclo git e não escreve código de fatia**; o **Executor escreve todo o código**. Decisão de commit/branch/MR é do Orquestrador, derivada da auditoria.

## Decisão
- **Executor (Executor Crítico)** escreve o código da fatia na branch que o Orquestrador abrir.
- **Orquestrador** decide o que/quando commitar (última palavra, da auditoria), abre branches, gere MRs, limpa branches. Só toca código para **auditar/corrigir pontual** (typo/lint/1–2 linhas); correção substantiva volta ao Executor.

## Consequências
- "Executor não se autoaprova" vira **estrutural** (escritor=Executor ≠ auditor=Orquestrador).
- O Orquestrador **não comita trabalho não auditado**.
- Em sessão sem Executor, a fatia de código **aguarda** — o Orquestrador faz o seu domínio (orquestração/auditoria/git/governança) e prepara o handoff.
