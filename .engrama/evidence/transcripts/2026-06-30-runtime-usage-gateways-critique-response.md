---
codex-session: 019f197b-21a3-74d0-b8af-6152d0018db9
codex-session-source: stream
role: critique
tier: T4
adapter: codex
provider: openai
model: gpt-5.5
configured-model: gpt-5.5
observed-model: null
effort: high
no-fallback: 1
routing-mode: explicit
routing-reason: role=critique tier=T4 resolved via ENGRAMA_T4_*
sandbox: read-only
label: runtime-usage-gateways-critique
---

Vou seguir o gate do repositório primeiro, em modo somente leitura, e depois vou ler o diff indicado para emitir a crítica nos 6 itens pedidos.
A primeira leva confirma que esta crítica é gate de governança, então o papel correto aqui é Executor Crítico, read-only, com devolutiva crítica antes de qualquer aceitação. Vou completar a ordem obrigatória de leitura, incluindo bootstrap e topo do log, antes de avaliar o diff.
O diff é exclusivamente documental, mas vou conferir os scripts/config de runtime para validar se a documentação não promete flags, roles ou saídas que o código atual não sustenta.
A checagem do runtime bate com os pontos centrais do diff: roles e tiers aceitos existem, `usage-report` suporta os agrupamentos documentados, e o bridge escreve evidência quando o adapter chega a emitir stream. Vou olhar só o trecho de ledger/transcript para fechar a nuance de promessa operacional.
Há arquivos modificados/untracked no workspace além do diff, mas não toquei neles. Para esta resposta vou tratar `/tmp/engrama-runtime-gateways.diff` como a evidência auditada e mencionar o estado só como contexto factual.
1. **Leitura da ordem**
Papel: Executor Crítico. Alçada: crítica read-only de mudança de governança, sem editar. Estado factual: topo do `log.md` em `2026-06-30 audit | checkpoint pos-PR #21 + revisao dos gaps restantes`; próximo passo seguro é emitir crítica da fatia documental; aprovação da Autoridade só seria necessária em caso de discordância material/impasse. Li `/tmp/engrama-runtime-gateways.diff` e conferi runtime relevante.

2. **Crítica técnica**
O diff atende ao objetivo: `AGENTS.md` e `CLAUDE.md` passam a dizer explicitamente que tarefa governada deve usar `.engrama/engine/scripts/exec-bridge.sh --role <role> --tier <tier> -- "prompt"` e que `codex exec` direto é exceção operacional registrada.

Roles/tiers, ledger, `usage-report`, ausência de dashboard/UI e secrets ficam claros. Conferi no código que `model-router.sh` aceita `orchestrate execute critique review audit authority`, tiers `T1/T2/T3/T4/T4+`, e que `usage-report.sh` suporta `--by model|role|tier|adapter`.

Handoff em `continuidade-de-sessao.md` cobre `role`, `tier`, adapter, modelo efetivo, transcript, ledger mensal, validação executada e também o caso importante de falha antes de transcript/usage. Isso é bom e evita overclaim.

Único ajuste menor opcional: em `AGENTS.md`/`CLAUDE.md`, frases como “deve gravar/gerar evidência” poderiam ser lidas como garantia absoluta; `continuidade-de-sessao.md` já corrige a nuance ao exigir declarar falha sem transcript/usage. Não considero isso promessa falsa material.

3. **Veredito**
`concordo`. Sem objeção material.

4. **Execução**
N/A. Modo read-only; não editei arquivos.

5. **Evidências**
Li o gate obrigatório, bootstrap `status: active`, topo de `.engrama/log.md`, e o diff em `/tmp/engrama-runtime-gateways.diff`.

Pontos do diff: runtime em `.engrama/CLAUDE.md` linhas 9-19; runtime/handoff em `continuidade-de-sessao.md` linhas 32-68; gateway `AGENTS.md` linhas 80-126; gateway `CLAUDE.md` linhas 137-175. Conferi scripts: `model-router.sh`, `usage-report.sh`, `exec-bridge.sh`, `models.conf`.

6. **Pendências**
Nenhuma bloqueante. Opcional: espelhar em `AGENTS.md`/`CLAUDE.md` a mesma ressalva de `continuidade-de-sessao.md`: se o bridge falhar antes de gerar transcript/usage, declarar explicitamente.
