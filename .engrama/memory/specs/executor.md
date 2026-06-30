---
type: spec
status: active
touches: [memory/decisions/0003-executor-bridge-orquestrador-invoca-executor, memory/decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade, memory/decisions/0007-computer-use-duas-fases, memory/decisions/0010-roteamento-modelo-effort-do-executor, memory/decisions/0016-runtime-model-router-usage-ledger]
date: 2026-06-20
source_refs:
  - .engrama/memory/governance/papeis-e-alcadas.md
  - .engrama/memory/decisions/0003-executor-bridge-orquestrador-invoca-executor.md
  - .engrama/memory/decisions/0004-executor-critica-ativa-discordancia-escala-a-autoridade.md
  - .engrama/memory/decisions/0007-computer-use-duas-fases.md
  - .engrama/memory/decisions/0010-roteamento-modelo-effort-do-executor.md
  - .engrama/memory/decisions/0016-runtime-model-router-usage-ledger.md
---

Playbook de invocação do **Executor (Executor Crítico)** nas 3 variações. Normativo: [[memory/governance/papeis-e-alcadas]] + ADRs 0003/0004/0007/0010. O Executor **nunca executa cego**; sempre devolve crítica técnica antes.

## Mecânica comum (todas as variações)
`bash .engrama/engine/scripts/exec-bridge.sh --role <role> --tier <tier> --sandbox <read-only|workspace-write> --order <arquivo>` (ou prompt inline após `--`) resolve `role+tier` via `model-router.sh`, chama o adapter configurado e grava transcript + usage ledger. Ordem segue [[memory/specs/executor-order]]. I/O colado à Autoridade (ADR 0003).

> **Template:** fixe em `.engrama/engine/config/models.conf` a configuração real do seu adapter. A sintaxe de vendor fica em `.engrama/engine/adapters/<adapter>.sh`; o contrato do Engrama é `role+tier`.

## Variação 1 — Executor de CÓDIGO
- **Modelo/effort:** resolvidos por `role=execute` + tier em `.engrama/engine/config/models.conf` ([[memory/decisions/0010-roteamento-modelo-effort-do-executor]], [[memory/decisions/0016-runtime-model-router-usage-ledger]]). T3 segue como default conceitual para execução complexa; T4/T4+ exigem gatilho/risco.
- **Faz:** escreve o código da fatia na branch indicada; produz evidência (testes/saídas).
- **Devolve 6 itens** (leitura/crítica/veredito/execução/evidências/pendências). `discordo` material → não executa; o Orquestrador leva à Autoridade.
- **O Orquestrador SEMPRE audita** depois (re-executa gates).

> **Template:** a régua de tiers acima é a default do modelo. Mapeie cada tier (T1–T4+) em `.engrama/engine/config/models.conf`; mantenha T3 como o default de execução complexa e T4/T4+ para crítica/auditoria.

## Variação 2 — CRÍTICA (gate de qualidade)
- **Modelo:** resolvido por `role=critique tier=T4` no model-router; deve apontar ao maior modelo aprovado (ADR 0010, exceção). **Effort** segue o tier (governança/sensível = high).
- **Entregável primário = crítica** (read-only, **sem patch/código**). Inclui: crítica de governança (ADR 0006), análise item 7, code review, refutação de findings.
- **NÃO** é "crítica": a crítica pré-execução embutida numa ordem de código (essa segue `role=execute`). Ordem híbrida "critique+implemente" → **split** (crítica em `role=critique tier=T4`, execução em `role=execute` no tier adequado).
- **Devolve:** contradições/lacunas/riscos/melhorias/**veredito**. Consenso → o Orquestrador efetiva; impasse → Autoridade.

## Variação 3 — COMPUTER-USE (mutating UI)
- **2 fases** (ADR 0007): Fase 1 reconhecimento read-only → o Orquestrador aprova `approved_action_scope` → Fase 2 executa o exatamente-aprovado (para se a UI divergir). `read_only_lookup` é uma fase, livre.
- Produção via UI = ordem + 2ª confirmação.

## Regras transversais
- Roteamento `role+tier` escolhe adapter, provider, **modelo e effort**, nunca **se** o Executor participa (não há código sem Executor).
- Retry após auditoria reprovada **upshifta** o tier.
- Fronteiras sempre explícitas: declarar na ordem o que **não** tocar.

> Exemplo (troque pelo do seu projeto): "não tocar no serviço legado em `N/A (sem servidor local)`, no ambiente de produção, nem no app antigo; escopo restrito à fatia X na branch Y." Se este modelo for portado de um projeto anterior, a fronteira do código legado/herdado entra aqui como uma das proibições explícitas da ordem.
