---
type: spec
status: active
touches: [decisions/0003-executor-bridge-orquestrador-invoca-executor, decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade, decisions/0007-computer-use-duas-fases, decisions/0010-roteamento-modelo-effort-do-executor]
date: {{DATA}}
source_refs:
  - .engrama/governance/papeis-e-alcadas.md
  - .engrama/decisions/0003-executor-bridge-orquestrador-invoca-executor.md
  - .engrama/decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade.md
  - .engrama/decisions/0007-computer-use-duas-fases.md
  - .engrama/decisions/0010-roteamento-modelo-effort-do-executor.md
---

Playbook de invocação do **Executor (Executor Crítico)** nas 3 variações. Normativo: [[governance/papeis-e-alcadas]] + ADRs 0003/0004/0007/0010. O Executor **nunca executa cego**; sempre devolve crítica técnica antes.

## Mecânica comum (todas as variações)
`{{EXECUTOR_CMD}} --json --skip-git-repo-check -m <model> -c model_reasoning_effort=<effort> "<ordem>" < /dev/null` + watchdog. Ordem segue [[specs/executor-order]]. I/O colado à Autoridade (ADR 0003).

> **Template:** fixe aqui a sintaxe real do seu `{{EXECUTOR_CMD}}` (flags de modelo, de esforço de raciocínio e de saída estruturada). O fechamento de stdin (`< /dev/null`) e o watchdog folgado são invariantes operacionais — ver notas em [[decisions/0003-executor-bridge-orquestrador-invoca-executor]].

## Variação 1 — Executor de CÓDIGO
- **Modelo/effort:** modelo executor por tier ([[decisions/0010-roteamento-modelo-effort-do-executor]]): T1 `{{MODELO_EXECUTOR_LEVE}}`/low · T2 `{{MODELO_EXECUTOR_PESADO}}`/medium · T3 `{{MODELO_EXECUTOR_PESADO}}`/high (default) · T4 `{{MODELO_EXECUTOR_PESADO}}`/high (+esforço extra por gatilho).
- **Faz:** escreve o código da fatia na branch indicada; produz evidência (testes/saídas).
- **Devolve 6 itens** (leitura/crítica/veredito/execução/evidências/pendências). `discordo` material → não executa; o Orquestrador leva à Autoridade.
- **O Orquestrador SEMPRE audita** depois (re-executa gates).

> **Template:** a régua de tiers acima é a default do modelo. Mapeie cada tier (T1–T4) ao seu `{{MODELO_EXECUTOR_LEVE}}` / `{{MODELO_EXECUTOR_PESADO}}` real e ao esforço de raciocínio correspondente; mantenha T3 como o default.

## Variação 2 — CRÍTICA (gate de qualidade)
- **Modelo:** **sempre o maior aprovado (`{{MODELO_CRITICA}}`)** — independe de tier (ADR 0010, exceção). **Effort** segue o tier (governança/sensível = high).
- **Entregável primário = crítica** (read-only, **sem patch/código**). Inclui: crítica de governança (ADR 0006), análise item 7, code review, refutação de findings.
- **NÃO** é "crítica": a crítica pré-execução embutida numa ordem de código (essa segue o modelo executor `{{MODELO_EXECUTOR_PESADO}}`). Ordem híbrida "critique+implemente" → **split** (crítica em `{{MODELO_CRITICA}}`, execução no modelo executor).
- **Devolve:** contradições/lacunas/riscos/melhorias/**veredito**. Consenso → o Orquestrador efetiva; impasse → Autoridade.

## Variação 3 — COMPUTER-USE (mutating UI)
- **2 fases** (ADR 0007): Fase 1 reconhecimento read-only → o Orquestrador aprova `approved_action_scope` → Fase 2 executa o exatamente-aprovado (para se a UI divergir). `read_only_lookup` é uma fase, livre.
- Produção via UI = ordem + 2ª confirmação.

## Regras transversais
- Roteamento pesado/leve escolhe o **modelo**, nunca **se** o Executor participa (não há código sem Executor).
- Retry após auditoria reprovada **upshifta** o tier.
- Fronteiras sempre explícitas: declarar na ordem o que **não** tocar.

> Exemplo (troque pelo do seu projeto): "não tocar no serviço legado em `{{DEV_URL}}`, no ambiente de produção, nem no app antigo; escopo restrito à fatia X na branch Y." Se este modelo for portado de um projeto anterior, a fronteira do código legado/herdado entra aqui como uma das proibições explícitas da ordem.
