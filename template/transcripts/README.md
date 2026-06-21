# Transcripts do executor-bridge

Registro **verbatim** de cada invocacao do Executor (`codex exec`) — a **ordem enviada**
e a **resposta na integra**. Estes transcripts sao **versionados** para que a
Autoridade possa auditar exatamente o que foi pedido ao Executor e o que ele
devolveu, sem depender de `/tmp` nem de relay manual.

## Convencao

Cada invocacao via `.engrama/scripts/exec-bridge.sh` gera um par datado em `transcripts/`:

```
transcripts/<YYYY-MM-DD>-<label>-order.md      # a ordem (verbatim)
transcripts/<YYYY-MM-DD>-<label>-response.md   # a resposta do codex (integra) + cabecalho YAML
```

O cabecalho da resposta registra `codex-session`, modelo, sandbox e `label`.
A entrada correspondente no [ledger](../.engrama/qa/criticas-do-executor.md)
pode referenciar `codex-session:<id>` como **evidencia fraca** de execucao real
do Executor: mostra que uma sessao observavel do Codex rodou, mas **nao** prova
identidade independente do critico. O teto honesto continua documentado no
ADR 0011.
