---
type: decision
status: proposed
touches: [memory/governance/papeis-e-alcadas, memory/governance/modelo-operacional]
date: {{DATA}}
source_refs:
  - CLAUDE.md
  - .engrama/memory/governance/papeis-e-alcadas.md
---

**Produção é intocável** (quando houver deploy): escrita em produção exige ordem da Autoridade **+ segunda confirmação explícita** (AA); o Orquestrador **abre** MR de produção mas **nunca aprova/mergeia**. Status `proposed` — **inativo até existir ambiente de deploy**.

## Contexto
A regra existe para barrar mistura acidental de staging/produção (incidente clássico em projetos com mais de um ambiente). Enquanto o projeto **não tiver deploy**, a regra fica registrada e marcada inativa para não inventar ambiente inexistente.

> Nota: se este modelo for portado de um projeto anterior que já sofreu um incidente de mistura staging/prod, registre o incidente como motivação concreta — mas a regra vale por si, independentemente de histórico.

## Decisão (ativa quando houver staging/produção)
- **Staging:** o Orquestrador tem autonomia total (abre/comita/push/abre+aprova MR/limpa).
- **MR de produção:** o Orquestrador abre e avisa a Autoridade; **nunca aprova** (exceção única: delegação explícita da Autoridade com dupla aprovação).
- **Escrita em produção remota** (deploy, `--remote` de escrita, secrets/infra, migration/rollback/seed/reset): **AA** — o agente **para**, declara exatamente o que vai atingir produção e **só executa após 2ª confirmação**.
- **Read-only remoto** (inspeção/auditoria) é livre.
- **Mutação remota** proibida por padrão; só sob ordem explícita da Autoridade.

## Consequências
- Quando o projeto tiver alvo de deploy (stack-alvo: `{{STACK}}`), esta ADR vira `active` e a matriz de alçadas ativa os gates de prod/staging.
- Até lá, a operação é git-local + (quando houver remote) trilha `feature → staging → main` sem deploy.

> Template: defina, para o **seu** projeto, (a) quando esta ADR deixa de ser `proposed` e vira `active` — tipicamente no primeiro ambiente de deploy real; (b) os nomes concretos de branches/ambientes (`staging`, `main`, `prod`, etc.) e qual host de git/CI os hospeda; (c) o que conta como "escrita em produção" na sua stack (comandos de deploy, flags `--remote`, migrations/seeds, rotação de secrets/infra). Mantenha invariantes: o Orquestrador nunca aprova/mergeia MR de produção, e toda escrita em produção remota exige AA (ordem + 2ª confirmação).
