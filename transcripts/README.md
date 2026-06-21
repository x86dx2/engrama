# Transcripts do executor-bridge

Registro **verbatim** de cada invocação do Executor (`codex exec`) — a **ordem enviada**
e a **resposta na íntegra** — exigido pelo **ADR 0003** ("transparência para a Autoridade").
Antes esses I/O viviam só em `/tmp` (efêmeros); agora ficam **versionados e públicos**,
para que qualquer um possa auditar exatamente o que foi pedido ao Executor e o que ele devolveu.

## Convenção

A partir de `.engrama/scripts/exec-bridge.sh`, cada invocação gera um par datado em `transcripts/`:

```
transcripts/<YYYY-MM-DD>-<label>-order.md      # a ordem (verbatim)
transcripts/<YYYY-MM-DD>-<label>-response.md   # a resposta do codex (íntegra) + cabeçalho
```

O cabeçalho da resposta registra `codex-session`, modelo, sandbox e timestamp. A entrada
correspondente no [ledger](../.engrama/qa/criticas-do-executor.md) referencia o `label` e o
`codex-session:<id>` como **evidência (fraca) de execução real** do Executor (não prova
identidade independente — ver ADR 0011).

## Histórico

- [`sessao-01-auditoria-remediacao/`](sessao-01-auditoria-remediacao/) — os I/O do codex de
  toda a auditoria → remediação → absorção → reorganização → fechamento das pendências
  (preservados de `/tmp`; sem `codex-session` capturado, pois antecederam o wrapper).
