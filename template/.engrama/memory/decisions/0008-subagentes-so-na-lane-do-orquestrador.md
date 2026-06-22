---
type: decision
status: active
touches: [memory/governance/papeis-e-alcadas, memory/governance/modelo-operacional, 0002-orquestrador-dono-do-git-executor-escreve, 0003-executor-bridge-orquestrador-invoca-executor]
date: {{DATA}}
source_refs:
  - CLAUDE.md
---

Subagentes (subagentes nativos do Orquestrador ou qualquer tooling de swarm/orquestração de subagentes) são permitidos **apenas na lane do Orquestrador** (auditoria, pesquisa, análise paralela, QA-análise). **Nunca** como executor de código de fatia.

## Contexto
O Orquestrador pode spawnar subagentes. Se um subagente do Orquestrador escrevesse código de fatia, o **escritor e o auditor seriam ambos "Orquestrador"** → a validação cruzada estrutural ([[memory/decisions/0001-governanca-tres-papeis]]) colapsaria. A independência que sustenta o modelo vem do Executor ser outro processo/modelo — não de um subagente que o próprio Orquestrador gera e consome.

## Decisão
- ✅ Permitido: subagentes para o trabalho **do Orquestrador** — leitura/análise paralela, auditoria, verificação, pesquisa (ex.: um workflow de avaliação multi-lente).
- ❌ Proibido: subagente como **Executor de código de fatia**. Código é exclusivo do **Executor** (processo independente), invocado via [[memory/decisions/0003-executor-bridge-orquestrador-invoca-executor]].

## Consequências
- A invocação direta do `{{EXECUTOR_CMD}}` (Executor independente) **não** é afetada por esta regra — ela só veda subagentes do *Orquestrador* escrevendo código.
- Subagentes seguem úteis como multiplicador da auditoria/pesquisa do Orquestrador.

## Ajuste incorporado: autoria indireta proibida (crítica do Executor, {{DATA}})

O Executor apontou que a regra estava subespecificada: um subagente poderia **gerar o patch/diff final** de código de fatia e o Orquestrador apenas **aplicá-lo** — colapsando escritor≠auditor "pela porta dos fundos". Fica explícito: **autoria indireta é proibida.** Um subagente do Orquestrador **não pode produzir o patch/diff de código de fatia** para o Orquestrador aplicar. Código de fatia — **incluindo o patch** — é exclusivamente do Executor (processo independente, via [[memory/decisions/0003-executor-bridge-orquestrador-invoca-executor]]). Subagentes ficam restritos a produzir **análise/leitura/auditoria**, nunca artefato de código aplicável.
