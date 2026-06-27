---
type: decision
status: active
touches: [memory/decisions/0003-executor-bridge-orquestrador-invoca-executor, memory/decisions/0005-orquestrador-qa-reexecucao-e-metricas, memory/specs/licao-aprendida, memory/specs/test-writing]
date: 2026-06-24
source_refs:
  - .engrama/engine/scripts/exec-bridge.sh
  - tests/contract/exec-bridge.test.sh
reconcilia: UPDATE memory/decisions/0003-executor-bridge-orquestrador-invoca-executor
---

**O `exec-bridge.sh` parseia múltiplos schemas do `codex exec --json` e é vinculado a um teste de contrato com fixture capturada da saída REAL do codex.** O canal de governança (o executor-bridge, ADR 0003) não pode quebrar em silêncio quando o `codex` muda o formato do `--json`; a única defesa que funciona é mecânica (teste não-vácuo), não memória.

## Contexto

O `exec-bridge.sh` extrai do stream `codex exec --json` a resposta do Executor e o id de sessão. O `codex-cli 0.142.0` mudou o schema: a resposta passou de `response_item`/`payload.message`/`output_text` (antigo) para `item.completed`/`item.type==agent_message`/`item.text` (novo), e a sessão de `session_meta` para `thread.started`/`thread_id`. O bridge, escrito para o schema antigo, **rodava, o Executor respondia, e o bridge descartava a resposta em silêncio** — transcript vazio, sessão `derived`, `model: unknown`. Como o canal é o meio de governança (não há caminho de código sem o Executor — ADR 0003), a falha é de alto custo: parece que o Executor não respondeu.

Pior: a suíte de contrato (`tests/contract/exec-bridge.test.sh`, casos E1–E7) usava **stubs no schema ANTIGO**. A suíte ficava **verde de forma vácua** — o caminho feliz nunca exercitou o stream real, então o drift passou sem detecção. É a **2ª ocorrência confirmada da mesma classe** (PR-B: corpo da resposta não capturado), com **precursor em PR-A** (introdução do bridge/transparência, onde o session-id também escapou). Em ambas, **o stub do teste não replicava o formato real do codex** (ver [[memory/specs/licao-aprendida]]).

## Decisão

1. **Dual-parse, não pinar versão.** O `extract_response_text` aceita os dois schemas (antigo `response_item`/`output_text` **e** novo `item.completed`/`agent_message`), e **exclui** `item.completed` do tipo `error` (ruído, ex.: warning de plugin). O `extract_session_id` cobre `thread.started`/`thread_id` (já o fazia pelo branch `.thread_id`). Não fixamos uma versão do `codex` — o adaptador de vendor é trocável (ADR 0003) e a Autoridade controla qual `codex` está instalado.
2. **Teste de contrato com eventos reais + prova de não-vacuidade.** O caminho feliz da suíte exercita o **JSONL real do `0.142.0`**, hoje embutido **inline (heredoc) no próprio teste** — capturado de uma execução real, não inventado; **não** há (ainda) artefato de fixture versionado à parte nem recaptura automatizada. Há um caso explícito (`E3A`) que roda o **parser legado** sobre o mesmo stream e exige que ele fique **vazio** — provando que o fix é load-bearing (RED sem ele). Um caso de compat retroativa (`E3B`) garante que o schema antigo continua capturando.
3. **Sem invenção de `model`.** O schema novo não emite `model` em nenhum evento do stream; o bridge registra `unknown` (ou o valor de `--model` quando passado). Não se fabrica um id.

## Alternativas consideradas

### Pinar a versão do `codex`
Rejeitada. O `codex` é adaptador de vendor controlado pela Autoridade (ADR 0003); o pack não pode (nem deve) forçar uma versão. Pinar moveria a fragilidade, não a removeria.

### Manter só o stub antigo no teste
Rejeitada — é exatamente o bug: verde vácuo que não prova o stream real. Foi assim que o drift passou.

### Fail-loud no bridge quando nenhum schema conhecido casa
Considerada e adiada. Abortar a run ao não reconhecer evento tornaria a quebra ruidosa em vez de silenciosa — desejável —, mas como default agressivo poderia derrubar o canal a cada novidade benigna do stream. O freio escolhido é o **teste de contrato** (detecta o drift quando a fixture é atualizada). Uma asserção fail-loud pode ser adicionada depois como reforço.

## Consequências

- Um bump do `codex` que mude o schema é **detectável**: ao atualizar a fixture com a saída real nova, o teste fica RED até o parser cobrir o novo formato; o dual-parse degrada com elegância para formatos já conhecidos.
- **Obrigação durável (hoje manual):** quando o `codex` mudar a saída, os eventos do teste devem ser **recapturados da saída real** (não editados a olho). Promover o stream inline a fixture versionada + recaptura mecânica fica como follow-up.
- **Resíduo conhecido (baixa prioridade):** o fallback `extract_response_from_session` (leitura do `~/.codex/sessions/*.jsonl`) ainda parseia o schema antigo. Como o stream do `0.142.0` agora traz o `agent_message` diretamente, esse fallback virou caminho raro; modernizá-lo fica como follow-up, não bloqueia.
- A origem (break-glass sob ordem da Autoridade para reabrir o canal + review retroativo do Executor) está no [[log]], nos transcripts versionados e no ledger [[evidence/qa/criticas-do-executor]].

## Status

Ativo. `reconcilia: UPDATE 0003` — complementa o canal do executor-bridge ([[memory/decisions/0003-executor-bridge-orquestrador-invoca-executor]]) com resiliência a version-drift e teste de contrato, sem invalidá-lo.
