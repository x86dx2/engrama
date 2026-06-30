Você é o Executor Crítico em modo read-only.

Contexto: o PR #20 implementou runtime model-router + usage ledger, mas os gateways ainda não explicavam operacionalmente como usar o bridge, ledger e usage-report. A Autoridade aprovou uma fatia pequena de documentação.

Escopo do diff:
- AGENTS.md
- CLAUDE.md
- .engrama/CLAUDE.md
- .engrama/memory/governance/continuidade-de-sessao.md

Objetivo da crítica:
1. Verificar se um agente novo lendo AGENTS.md e CLAUDE.md entende que tarefas governadas devem usar exec-bridge roteado por role+tier.
2. Verificar se ficam claros roles/tiers, usage ledger, usage-report, ausência de dashboard/UI e segurança de secrets.
3. Verificar se o handoff em continuidade-de-sessao cobre role, tier, adapter, modelo efetivo, transcript e ledger.
4. Confirmar que não há alteração funcional nem promessa falsa.

Leia o diff em /tmp/engrama-runtime-gateways.diff e responda nos 6 itens do Executor: leitura, crítica técnica, veredito, execução N/A, evidências, pendências.
