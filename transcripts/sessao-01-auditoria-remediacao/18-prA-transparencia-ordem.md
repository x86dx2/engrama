Você é o EXECUTOR (Executor Crítico). Tier T3. Critique antes de executar. cwd = raiz do repo "engrama", branch `feat/transparencia-executor-bridge`. Não comite.

OBJETIVO: mecanizar a TRANSPARÊNCIA do executor-bridge (ADR 0003): um wrapper que invoca o `codex exec` e SALVA a ordem (verbatim) + a resposta (íntegra) + o session-id do codex em `transcripts/` (versionado), e a convenção do ledger registrar `codex-session:<id>` como evidência (fraca) de execução real do Executor (atestação do R1 — item 3). Já existe `transcripts/README.md` e `transcripts/sessao-01-.../` (histórico desta sessão). NÃO mexa nesses.

ORDEM:
A) `bin/exec-bridge.sh` (bash portável, `set -u`): wrapper do executor-bridge.
   - Args: `--order <arquivo>` (a ordem), `--label <slug>`, `--sandbox <read-only|workspace-write>` (default read-only), e repassa flags extras ao codex se preciso.
   - Roda o codex lendo a ordem do arquivo. Para capturar o **session-id**: prefira `codex exec --json` e extraia o id de sessão do stream de eventos (ex.: campo `session_id`/`thread_id`/`conversation_id` — inspecione o formato real com um teste rápido); se não houver, derive um id determinístico = `sha256` curto da resposta (e marque como `derived`).
   - Salva: `transcripts/<DATA>-<label>-order.md` (cópia da ordem) e `transcripts/<DATA>-<label>-response.md` (a resposta + um cabeçalho YAML com `codex-session`, `model`, `sandbox`, `label`). A `<DATA>` deve vir de `git`/arg (o ambiente PROÍBE `date`/`$RANDOM` em scripts de teste — no wrapper de produção `date` é ok, mas aceite `--date <YYYY-MM-DD>` para o teste injetar uma data fixa e ser determinístico).
   - Imprime no stdout: os 2 caminhos salvos + a linha `codex-session:<id>` (para o Orquestrador colar no ledger).
   - TESTÁVEL: aceite `ENGRAMA_CODEX_BIN` (default `codex`) para o teste injetar um STUB que ecoa uma resposta fake + um session-id fake, sem rede.
B) `tests/contract/exec-bridge.test.sh` (padrão das suítes, fail-fast): com um STUB de codex (via `ENGRAMA_CODEX_BIN`), prova: (i) salva os 2 arquivos (order+response) em transcripts/ com `--date` fixo; (ii) o response tem o cabeçalho com `codex-session`; (iii) extrai/imprime o `codex-session:<id>`; (iv) degrada com erro claro se faltar `--order`/`--label`. NÃO chame o codex real.
C) `classify()` do gate: `bin/exec-bridge.sh` → `gate`. **NÃO** classifique `transcripts/*` (são registros/evidência, não código — classificá-los criaria exigência circular de crítica a cada transcript). Rode `sync-template.sh` se mexer no gate.
D) DOC/normativo:
   - ADR 0003 (raiz + template): acrescentar que a transparência agora é **mecanizada** — `bin/exec-bridge.sh` + `transcripts/` versionado preservam a ordem verbatim e a resposta íntegra; o ledger referencia `codex-session:<id>`.
   - ADR 0011 (raiz + template) ou 0006: nota curta de que `codex-session:<id>` é **evidência fraca** de que um codex real rodou (NÃO prova identidade independente — continua o teto do R1).
   - Doc do ledger (`.engrama/qa/criticas-do-executor.md` cabeçalho): o campo 4 (`ref`) pode conter `codex-session:<id>` além do `sha256:`.
E) `.gitignore`: NÃO ignore `transcripts/` (são commitados, por decisão da Autoridade).

FRONTEIRAS: não mude a lógica do gate além do classify; não toque os transcripts existentes; portabilidade BSD/GNU; sem `date`/`$RANDOM` em testes. Não comite.

ACEITE (cole as saídas): `bash tests/contract/exec-bridge.test.sh` verde (com stub); `bash tests/run.sh` VERDE; `shellcheck bin/exec-bridge.sh tests/contract/exec-bridge.test.sh` limpo; `lint.sh` exit 0; `sync.test.sh` verde; e uma DEMO com o stub: `ENGRAMA_CODEX_BIN=<stub> bash bin/exec-bridge.sh --order <f> --label demo --date 2026-06-21` gera os 2 arquivos e imprime `codex-session:`.

RESPONDA nos 6 itens do Executor. Em português.
