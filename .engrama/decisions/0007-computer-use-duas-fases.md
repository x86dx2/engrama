---
type: decision
status: active
touches: [governance/cadeia-de-comando, governance/papeis-e-alcadas]
date: 2026-06-20
source_refs:
  - /Users/x86/git-projects/engrama/.engrama/governance/cadeia-de-comando.md
  - /Users/x86/git-projects/engrama/.engrama/governance/papeis-e-alcadas.md
---

Computer-use/controle de UI com potencial de mutação (`mutating_ui_task`) é do **Executor, nunca cego**, em **duas fases**: reconhecimento read-only → aprovação do Orquestrador → execução do exatamente-aprovado.

## Decisão
- **Fase 1 — reconhecimento (read-only):** o Executor levanta o estado atual (telas, valores, opções) + `recognition_timestamp` e reporta ao Orquestrador. Não muta.
- **Aprovação do Orquestrador → `approved_action_scope`:** alvo, estado esperado, ações permitidas, ações proibidas, condição de parada.
- **Fase 2 — execução:** o Executor executa **exatamente** o aprovado; **se a UI divergir do reconhecimento → PARA e volta à Fase 1**.
- `read_only_lookup` (validar app, pesquisa, leitura) fica **fora** — uma fase, livre.

## Consequências
- Sem mutação de UI sem reconhecimento + escopo aprovado.
- Gates de produção preservados (quando houver deploy): mutação de prod via UI exige ordem + 2ª confirmação.
