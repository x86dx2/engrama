---
type: decision
status: active
touches: [memory/governance/papeis-e-alcadas, memory/governance/modelo-operacional]
date: {{DATA}}
source_refs:
  - CLAUDE.md
---

Adotamos um modelo de governança operacional de **3 papéis canônicos** (por função, não por vendor) com **validação cruzada**: Orquestrador/Auditor, Executor Crítico, Autoridade de Mudança.

## Contexto
Este pack define o **núcleo estrutural** de governança entre agentes — deliberadamente **stack-agnóstico** e portável. O modelo é independente da linguagem, do framework, do host de git/CI e do conjunto concreto de agentes que ocupam cada papel: o que ele fixa é a **separação de funções** e a **validação cruzada**, não as ferramentas.

> Nota: se este modelo for portado de um projeto anterior, traga apenas o **núcleo estrutural** (papéis, alçadas, validação cruzada) e deixe o histórico de churn e os gates específicos de ambiente para serem (re)decididos no contexto do novo projeto — tipicamente num ADR de domínio/stack próprio. Gates de promoção staging/prod só se ativam quando existir deploy ([[memory/decisions/0009-producao-intocavel-dupla-confirmacao]]).

## Decisão
Três papéis, distintos e não-substituíveis:
- **Orquestrador/Auditor/QA/Arquiteto/Guardião de Produção** — dirige, decompõe, audita, dono do git, veredito final. Não escreve código de fatia.
- **Executor Crítico** — escreve o código; critica ativamente antes; nunca cego.
- **Autoridade de Mudança** — aprova o sensível; arbitra discordâncias.

O mapeamento dos papéis para agentes/pessoas concretos é **mutável** sem invalidar o modelo.

> Template: defina o mapeamento atual em [[memory/governance/papeis-e-alcadas]] (`{{ORQUESTRADOR}}` / `{{EXECUTOR}}` / `{{AUTORIDADE}}`). Vale qualquer combinação de agentes/pessoas, desde que o separador **escritor ≠ auditor** e a **arbitragem humana de impasse** se mantenham.

## Alternativas consideradas
- **Tooling de swarm/orquestração de subagentes** (muitos subagentes coordenados por mensageria entre si) como modelo de governança: rejeitado. Qualquer tooling de swarm/orquestração de subagentes fica como **tooling subordinado**, nunca o canal de governança — o canal de governança é **o engrama versionado + {{EXECUTOR_CMD}} (executor-bridge)**.
- **Orquestrador sozinho** (sem executor distinto): rejeitado — perde a validação cruzada estrutural (escritor = auditor).

## Consequências
- Validação cruzada estrutural: quem escreve ≠ quem audita ≠ quem aprova.
- Exige um Executor independente — ver [[memory/decisions/0002-orquestrador-dono-do-git-executor-escreve]] e [[memory/decisions/0003-executor-bridge-orquestrador-invoca-executor]].
