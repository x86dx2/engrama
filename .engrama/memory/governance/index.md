---
type: governance
status: active
touches: [memory/governance/papeis-e-alcadas, memory/governance/role-runtime-contracts, memory/governance/cadeia-de-comando, memory/governance/modelo-operacional, memory/governance/continuidade-de-sessao]
date: 2026-06-20
source_refs:
  - CLAUDE.md
  - AGENTS.md
---

Porta de entrada da **governança operacional entre agentes** do projeto. Define como o **Orquestrador (Orquestrador/Auditor/QA/Arquiteto/Guardião de Produção)**, o **Executor (Executor Crítico)** e a **Autoridade (Autoridade de Mudança)** trabalham, fazem handoff e retomam trabalho sem depender de prompt longo nem de memória informal. O modelo é definido por **papéis por função, não por vendor**: os nomes canônicos (Orquestrador, Executor, Autoridade) são a voz correta, independentemente de qual ferramenta/modelo encarne cada papel.

> Nota: se este modelo for portado de um projeto anterior (maduro, em produção), adapte-o ao Engrama — herde o que funcionou e descarte o que era específico do projeto de origem.

## Governança vs ADR vs log vs gap

| Artefato | Responde | Onde |
|----------|----------|------|
| **Governança** (`memory/governance/`) | **Como** os agentes trabalham juntos | esta área |
| **ADR** (`memory/decisions/`) | **Por quê** uma decisão foi tomada | `memory/decisions/` |
| **Log** (`log.md`) | **O que** mudou e quando (append-only) | `log.md` |
| **Gap** (`memory/gaps/`) | **O que está em aberto** | as páginas de memory/gaps/ do seu projeto |

Governança **não** substitui o bootstrap do projeto. O **perfil inicial do projeto** (finalidade, stack, comandos e superfícies sensíveis) mora em [[memory/project/bootstrap-do-projeto]]. O **checkpoint vivo de retomada** (onde o trabalho parou + próximo passo) mora no **topo do [[log]]** — versionado. O que fica fora do engrama é só o estado **efêmero** do dia-a-dia (chat/status volátil que não vale versionar). Ver [[memory/governance/continuidade-de-sessao]].

## Ordem mínima de leitura (qualquer agente novo)

1. [[memory/governance/papeis-e-alcadas]] — qual é o seu papel, quem dirige quem, o que cada um pode fazer.
2. [[memory/governance/role-runtime-contracts]] — contratos normativos por papel e regras de runtime do bridge.
3. [[memory/governance/cadeia-de-comando]] — protocolo Orquestrador ↔ Executor ↔ Autoridade + o **executor-bridge** (o Orquestrador invoca o Executor direto).
4. [[memory/governance/modelo-operacional]] — os princípios inegociáveis.
5. [[memory/governance/continuidade-de-sessao]] — abrir, trabalhar, encerrar, handoff.
6. [[memory/project/bootstrap-do-projeto]] — se estiver `proposed`, a primeira tarefa é completar o bootstrap com a Autoridade.
7. ADRs de processo [[memory/decisions/0001-governanca-tres-papeis]] … [[memory/decisions/0009-producao-intocavel-dupla-confirmacao]] + roteamento de modelo/effort [[memory/decisions/0010-roteamento-modelo-effort-do-executor]] + diff-binding verificável [[memory/decisions/0011-diff-binding-atestacao-verificavel]].
8. Topo do [[log]] — estado factual recente.

## O que adaptar por projeto

- **Executor-bridge automatizado:** o **Orquestrador invoca o Executor diretamente** pelo executor-bridge roteado (`role+tier`) e fecha o loop até staging sozinho, sem relay humano de rotina. Ver [[memory/decisions/0003-executor-bridge-orquestrador-invoca-executor]] e [[memory/decisions/0016-runtime-model-router-usage-ledger]].
  > Template: defina o adapter/config runtime em `.engrama/engine/adapters/` e `.engrama/engine/config/models.conf`. O roteamento escolhe o *modelo*, nunca *se* o Executor participa.
- **Role Runtime Contracts:** o runtime governado carrega contratos em `.engrama/memory/governance/roles/*.md`; gateways da raiz sao so ponteiros curtos, nao fonte normativa duplicada.
- **Executor como freio ativo:** o Executor critica ativamente **toda ordem**; qualquer discordância material **escala à Autoridade** — o Orquestrador **não tem overrule**. Ver [[memory/decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade]].
- **Bootstrap do projeto no 1º startup:** o Orquestrador entrevista a Autoridade e fecha finalidade/stack/comandos/superfícies sensíveis em [[memory/project/bootstrap-do-projeto]] antes de trabalho substantivo.
- **Tooling de swarm é subordinado**, não o modelo de coordenação. A tríade é o modelo; **qualquer tooling de swarm/orquestração de subagentes** (e seus mecanismos de mensagem) não é o canal de governança — o canal é o **engrama versionado + executor-bridge**.
- **Gates de produção/staging/CI inativos até existir deploy.** Marcados na matriz; ativam quando o ambiente existir.
  > Template: decida quais gates (produção, staging, CI) já existem no seu projeto e ative-os na matriz de alçadas; mantenha inativos os ambientes que ainda não foram provisionados.
