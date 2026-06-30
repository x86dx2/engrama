---
type: decision
status: active
touches: [memory/decisions/0003-executor-bridge-orquestrador-invoca-executor, memory/decisions/0010-roteamento-modelo-effort-do-executor, memory/decisions/0013-bridge-resiliente-a-version-drift-do-codex]
date: 2026-06-30
source_refs:
  - .engrama/engine/scripts/model-router.sh
  - .engrama/engine/scripts/exec-bridge.sh
  - .engrama/engine/adapters/codex.sh
  - .engrama/engine/config/models.conf
  - .engrama/evidence/usage
reconcilia: UPDATE memory/decisions/0010-roteamento-modelo-effort-do-executor
---

O roteamento de modelos deixa de ser apenas política documental e passa a ser decisão runtime verificável: `role+tier` resolve adapter, provider, modelo e effort; toda execução pelo bridge registra rota e uso local.

## Contexto

A ADR 0010 definiu tiers e a regra de crítica no maior modelo aprovado, mas o `exec-bridge.sh` ainda aceitava flags livres do `codex exec`. Isso deixava três fragilidades: drift entre docs e runtime, fallback silencioso possível em crítica, e falta de métrica local para comparar uso por assinatura versus custo hipotético de API.

## Decisão

1. **Config runtime shell-safe.** `.engrama/engine/config/models.conf` é a fonte runtime para tiers `T1`, `T2`, `T3`, `T4` e `T4+`. Os ids de modelo continuam sendo configuração local editável, não verdade universal.
2. **Router obrigatório.** `.engrama/engine/scripts/model-router.sh` resolve `role+tier -> adapter+provider+model+effort`. Roles sensíveis têm piso mecânico: `critique`/`audit` exigem `>=T4`, `authority` exige `T4+`, `review`/`orchestrate` exigem `>=T3`. Config ausente falha alto.
3. **Sem modo legado silencioso no bridge.** Se `--role/--tier` não vierem, `exec-bridge.sh` usa default explícito `execute/T2` e registra `routing-mode: default` no transcript e no usage ledger. Se só um dos dois vier, falha.
4. **Adapter vendor-specific.** Codex fica em `.engrama/engine/adapters/codex.sh`. O núcleo do bridge fala em adapter/model/effort; o adapter Codex traduz para `codex exec --json -m <model> -c model_reasoning_effort=<effort>`.
5. **T4+ é neutro; `xhigh` é tradução Codex.** O tier do Engrama é `T4+`. Nesta instância, o adapter Codex recebe `xhigh` em `ENGRAMA_T4_PLUS_EFFORT`; outros adapters podem mapear o mesmo tier para outro knob.
6. **Usage ledger local.** Cada execução pelo bridge escreve uma linha JSONL em `.engrama/evidence/usage/usage-YYYY-MM.jsonl` com schema `engrama.usage.v1`: projeto, branch, role, tier, adapter, provider, model, effort, billing mode, plano, timestamps, duração, tokens quando disponíveis, turns, transcript e sessão.
7. **Relatório local.** `.engrama/engine/scripts/usage-report.sh` sumariza o ledger por mês e por `model|role|tier|adapter`. Tokens/preços ausentes aparecem como `unknown`, sem falhar.
8. **Billing por assinatura e API separados.** `.engrama/engine/config/subscriptions.conf` modela planos como Codex Pro; `.engrama/engine/config/prices.conf` guarda estimativas editáveis de API. Preços vazios não bloqueiam.

## Alternativas consideradas

### Manter flags livres como contrato primário
Rejeitada. Era o estado anterior: fácil de usar, mas invisível ao Engrama. O objetivo desta fatia é medir e auditar a decisão de modelo, então a rota precisa passar pelo router.

### Preservar modo legado sem router
Rejeitada pela Autoridade nesta fatia. O caminho mais coerente é que toda execução observável passe por `role+tier`. Para reduzir atrito operacional, o bridge ainda aceita ausência total de `role/tier`, mas isso vira default explícito `execute/T2` registrado como tal.

### Tratar `max` como effort universal
Rejeitada. `max` é semântica de produto, não knob portátil. O tier neutro é `T4+`; cada adapter traduz para seu effort real. No Codex atual, a tradução configurada é `xhigh`.

### Dashboard externo ou SQLite
Rejeitados por escopo. O primeiro passo é ledger local Bash-first, portável e auditável; Langfuse/LiteLLM/OpenRouter/Kimi/GLM ficam fora desta fase.

## Consequências

- O gate de crítica passa a orientar o uso do bridge: `exec-bridge.sh --role critique --tier T4 --sandbox read-only`.
- A comparação custo assinatura/API deixa de depender de memória informal; o ledger local dá a base para medição posterior.
- O template distribuível ganha `engine/config`, `engine/adapters` e `evidence/usage`; por isso a mudança exige disciplina de release (ADR 0014).
- `jq` permanece dependência operacional do bridge/report. Não é dependência nova: o bridge já exigia `jq` para parsear `codex exec --json`.
- O ledger prova o que o bridge observou, mas não prova identidade independente do crítico. O teto de identidade continua sendo o da ADR 0011.

## Status

Ativo. Atualiza ADR 0010 e complementa ADRs 0003/0013: o executor-bridge agora é roteado, vendor-specific por adapter, e metrificado por usage ledger local.
