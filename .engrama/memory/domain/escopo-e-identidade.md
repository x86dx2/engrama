---
type: domain
status: active
touches: [memory/governance/papeis-e-alcadas, memory/governance/cadeia-de-comando, evidence/qa/criticas-do-executor, memory/domain/validacao-cruzada-estrutural]
date: 2026-06-21
source_refs:
  - .engrama/memory/governance/papeis-e-alcadas.md
  - .engrama/memory/governance/cadeia-de-comando.md
  - .engrama/evidence/qa/criticas-do-executor.md
  - .engrama/engine/scripts/critique-gate.sh
  - .engrama/engine/scripts/exec-bridge.sh
reconcilia: ADD
---

O Engrama já pratica um **namespacing multi-camada** para memória, crítica e retomada. A analogia com mem0 é útil porque mostra que as camadas `user/session/agent/org` não precisam de banco próprio quando o repo, a branch e a governança já delimitam identidade e escopo.

## Mapeamento de camadas

| Camada conceitual | Mecanismo concreto no Engrama | Efeito prático |
|---|---|---|
| `user` | papel ocupado em [[memory/governance/papeis-e-alcadas]] | identidade de responsabilidade: quem dirige, quem executa, quem arbitra |
| `agent` | agente concreto que encarna o papel (`Claude`, `Codex`, humano) | separa vendor/processo do papel canônico |
| `session` | `codex-session:<id>` no ledger/transcripts + checkpoint vivo no topo de [[log]] | delimita a execução observável de uma run e o ponto factual de retomada |
| `org` | o próprio repo/instância Engrama | fronteira institucional da memória canônica |
| `inquiry` / escopo visível | branch atual + categoria do gate | limita para qual fatia uma crítica conta |

## Papel, agente e identidade

O namespace primário do Engrama não é "usuário da API"; é **papel canônico**. [[memory/governance/papeis-e-alcadas]] fixa que a primeira identidade relevante é:
- Orquestrador;
- Executor;
- Autoridade.

O agente concreto é uma segunda camada. `Codex` não é automaticamente "o crítico"; ele é crítico **quando ocupa o papel de Executor**. Isso evita acoplar a identidade institucional ao vendor e permite trocar quem ocupa o papel sem reescrever o modelo.

## Sessão como recorte observável

O equivalente de `session` aparece em dois lugares:
- `codex-session:<id>`, emitido por `.engrama/engine/scripts/exec-bridge.sh`, que marca uma execução observável do Executor;
- o topo de [[log]], que materializa o checkpoint vivo da sessão para retomada.

Esses dois artefatos cumprem funções diferentes:
- `codex-session:<id>` é rastro de uma corrida específica do bridge;
- o topo do `log.md` é estado factual recompilável para a próxima sessão.

## Repo como namespace organizacional

O equivalente de `org` é simples: **o repo é a fronteira da memória canônica**. Tudo o que vale institucionalmente precisa sobreviver ao clone e ficar versionado em `.engrama/`.

Isso impede que a memória dependa de um banco externo opaco:
- o repo define o que pertence a esta instituição;
- o template distribui o framework;
- a instância viva carrega o domínio concreto.

## Branch + categoria como escopo do gate

O equivalente mais próximo de `inquiry` fica em `.engrama/engine/scripts/critique-gate.sh`. A função `classify()` decide **quais arquivos entram em quais categorias** (`governance`, `gate`, `contract`); depois o gate exige que a entrada do ledger combine:
- a **branch** atual;
- a **categoria** tocada;
- o **veredito** permitido;
- opcionalmente o **sha256** do diff.

Em outras palavras, a crítica não vale "para o repo inteiro". Ela vale para um **recorte**:
- esta branch;
- esta categoria;
- e, no caminho forte, este diff.

Esse recorte é exatamente o namespace operacional que impede vazamento de contexto entre fatias.

## Teto honesto

Esse namespacing melhora muito o escopo, mas não elimina toda ambiguidade de identidade. `codex-session:<id>` ajuda a localizar **qual sessão** produziu um artefato; ele não substitui uma identidade criptográfica independente do crítico. Esse limite reaparece em [[memory/domain/validacao-cruzada-estrutural]] e em [[memory/decisions/0011-diff-binding-atestacao-verificavel]].
