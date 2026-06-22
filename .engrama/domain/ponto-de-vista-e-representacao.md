---
type: domain
status: active
touches: [specs/orquestrador, governance/papeis-e-alcadas, governance/cadeia-de-comando, qa/criticas-do-executor, decisions/0011-diff-binding-atestacao-verificavel]
date: 2026-06-21
source_refs:
  - .engrama/specs/orquestrador.md
  - .engrama/governance/papeis-e-alcadas.md
  - .engrama/governance/cadeia-de-comando.md
  - .engrama/qa/criticas-do-executor.md
  - .engrama/scripts/exec-bridge.sh
  - .engrama/decisions/0011-diff-binding-atestacao-verificavel.md
reconcilia: ADD
---

O Engrama já mantém dois planos de representação úteis para teoria-de-mente operacional: **auto-representação** do sistema de governança e **representação de outros** sobre a fatia em análise. Esta página só **nomeia** o padrão; ela **não** altera schema nem resolve a identidade do crítico.

## 1. Auto-representação

A auto-representação do Engrama vive no que o sistema declara sobre si mesmo:
- [[specs/orquestrador]] descreve como o Orquestrador deveria operar;
- [[governance/papeis-e-alcadas]] declara quem faz o quê;
- [[governance/cadeia-de-comando]] fixa como a objeção e a arbitragem deveriam fluir.

Esse conjunto funciona como um "modelo interno" explícito: papéis, fronteiras, critérios de aceite, handoff e QA.

## 2. Representação de outros

A representação do outro aparece quando o Executor observa a ordem ou o diff e devolve um julgamento externo ao Orquestrador. Hoje isso já existe em duas superfícies:
- na resposta crítica do Executor, cujo protocolo em [[governance/continuidade-de-sessao]] admite `concordo | ajuste-menor | discordo`;
- no ledger [[qa/criticas-do-executor]], que registra a projeção commit-oriented dessa observação (`confirmo`, `ressalvas`, `waiver`, `dispensada` e equivalentes aceitos pelo gate).

O ponto importante não é a nomenclatura exata do schema atual, e sim o fato estrutural: há um **observador distinto** registrando uma leitura sobre a ação proposta por outro papel.

## Tipologia útil da observação

Como nome de padrão, a observação do outro cabe bem nesta trinca:
- `confirmo` — a leitura externa sustenta seguir;
- `ajuste-menor` — a leitura externa corrige sem bloquear a execução;
- `discordo` — a leitura externa identifica risco material e força arbitragem.

No estado atual do repo, essa tipologia está **espalhada** entre a resposta do Executor e o ledger. Fase 1 é só documentação: o padrão fica nomeado, mas o schema do ledger **não** é reformatado aqui.

## Por que isso importa

Sem esse plano de representação de outros, o Orquestrador teria só auto-relato. Com ele, o Engrama passa a registrar:
- o que o sistema diz sobre si;
- e o que um observador distinto diz sobre a mesma fatia.

É esse contraste que torna a crítica mais útil do que um comentário qualquer de revisão.

## Limite assumido nesta fase

Nomear o padrão **não resolve** o teto documentado em [[decisions/0011-diff-binding-atestacao-verificavel]]. O repo melhora o rastro de cobertura (`sha256`, `codex-session:<id>`, ledger, transcripts), mas ainda não prova de forma independente a **identidade** do observador. Esta página registra o plano de representação; não promete mais do que isso.

Ver também [[domain/validacao-cruzada-estrutural]] e [[domain/escopo-e-identidade]].
