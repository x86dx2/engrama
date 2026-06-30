---
type: governance
status: active
touches: [memory/governance/papeis-e-alcadas, memory/governance/cadeia-de-comando, memory/decisions/0016-runtime-model-router-usage-ledger]
date: 2026-06-30
source_refs:
  - .engrama/engine/scripts/exec-bridge.sh
  - .engrama/engine/scripts/model-router.sh
  - .engrama/memory/governance/papeis-e-alcadas.md
  - .engrama/memory/specs/executor.md
reconcilia: ADD
---

Os contratos de papel em runtime tornam explicito que `role` nao e decoracao. Mesmo quando o adapter/modelo fisico for o mesmo, a execucao governada deve carregar contrato, alcada, proibicoes e formato de resposta do papel logico.

## Fonte de verdade

- Normativo completo: `.engrama/memory/governance/roles/*.md`
- Carregamento runtime: `.engrama/engine/scripts/exec-bridge.sh`
- Roteamento `role+tier`: `.engrama/engine/scripts/model-router.sh`

Nao existe espelho destes contratos em `.engrama/engine/roles/`. O runtime carrega os markdowns normativos diretamente por convencao de nome.

## Regras de runtime

1. Execucao governada deve usar `exec-bridge.sh --role <role> --tier <tier>`.
2. Quando `--role`/`--tier` vierem explicitamente, o bridge deve localizar `roles/<role>.md`, sintetizar um prompt com cabecalho de governanca + contrato + ordem original e registrar o hash do contrato no transcript e no usage ledger.
3. Quando a chamada defaultar para `execute/T2`, o comportamento legado continua compativel, mas fica marcado como `governance_mode=legacy/defaulted` e **nao** deve fingir que um contrato foi aplicado.
4. Contrato ausente para um papel oficial eh erro de runtime: o bridge falha alto, nao chama adapter e nao cria ledger de execucao.

## Papeis oficiais nesta fase

- [[memory/governance/roles/orchestrate]]
- [[memory/governance/roles/execute]]
- [[memory/governance/roles/review]]
- [[memory/governance/roles/critique]]
- [[memory/governance/roles/audit]]
- [[memory/governance/roles/authority]]

`curate` fica fora desta fase. Ele ainda nao existe no runtime nem no normativo canonico, entao sua introducao precisa de ADR/PR separado.

## Campos rastreados

Transcript de resposta:
- `role-contract`
- `role-contract-hash`
- `governance-mode`

Usage ledger:
- `role_contract`
- `role_contract_hash`
- `governance_mode`

## Handoff minimo

Quando houver execucao roteada, o handoff deve informar:
- `role`
- `tier`
- `role_contract_hash`
- `adapter/provider/model`
- `transcript_path`
- `usage_ledger`

## Fronteira

Os gateways da raiz (`AGENTS.md`, `CLAUDE.md`) sao apenas ponteiros curtos. O contrato completo do papel vive nesta area de governance, nao nos entrypoints.
