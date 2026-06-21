Você é o EXECUTOR (Executor Crítico). Tier T3/T4 (superfície sensível: o GATE central). Critique antes de executar; se concordar, execute. cwd = raiz do repo "engrama", branch `remediacao/auditoria-engrama`.

CONTEXTO: há uma suíte de testes em `tests/` (rode `bash tests/run.sh`). A suíte do gate (`tests/gate/critique-gate.test.sh`) tem casos G1–G7 (comportamento CORRETO, devem continuar verdes) e R1–R5 (furos). Esta ordem corrige um SUBCONJUNTO seguro: R3, R4 e wiring/CI/hook. NÃO mexa em R1/R2/R5 (são outra fatia).

ORDEM (itens):
1. OBJETIVO: endurecer o gate e fechar o paradoxo "prega mas não roda", sem regredir G1–G7.
2. ESTADO FACTUAL: `tests/gate` prova: R3 (path non-ASCII escapa `classify()` porque `git diff --name-only` quota o nome → fail-open) e R4 (detached HEAD: `BRANCH` vazio casa espaço-duplo no ledger → false-allow). Não há CI. `tests/` e `.engrama/gaps/` escapam o `classify()`.
3. ESCOPO (edite estes arquivos):
   a) CRIAR `.github/workflows/ci.yml`: matriz `os: [ubuntu-latest, macos-latest]`; passos: checkout; garantir `shellcheck` (no macOS, `brew install shellcheck`); rodar `shellcheck` em `install.sh bootstrap.sh .engrama/scripts/*.sh .engrama/githooks/pre-commit tests/run.sh tests/gate/*.test.sh tests/contract/*.test.sh`; rodar `bash tests/run.sh`. Sem `permissions` amplas; trigger em `push` e `pull_request`.
   b) `.engrama/scripts/critique-gate.sh` — função `classify()`: ADICIONAR (sem remover o que existe) `tests/gate/*|*/tests/gate/*) addcat gate`; `.github/*) addcat gate`; `.engrama/gaps/*|.engrama/roadmap/*|.engrama/domain/*) addcat governance`. (`tests/contract/*` já existe.)
   c) **R3** em `.engrama/scripts/critique-gate.sh`: trocar a coleta de arquivos por `git diff --cached --name-only -z` lido em STREAM com `while IFS= read -r -d '' f; do classify "$f"; done < <(...)` (NÃO em variável — NUL se perde). Preservar o early-exit "sem staged → exit 0". Com `-z`, `core.quotePath` é irrelevante.
   d) **R4** em `.engrama/scripts/critique-gate.sh`: se `BRANCH` vazio (detached HEAD) E houver categoria sensível tocada → FAIL-CLOSED: bloquear (exit 2) com mensagem clara, em vez de degradar o grep.
   e) `.engrama/scripts/critique-gate-hook.sh`: se `python3` ausente OU o parse falhar para um comando que parece `git commit`, FAIL-CLOSED (não `exit 0` silencioso): ou delega ao gate, ou bloqueia com aviso. Não pode virar fail-open quando a dependência falta.
4. FRONTEIRAS (não tocar): NÃO edite `tests/**` (a quebra de R3/R4 é o sinal; quem promove é o Orquestrador). NÃO altere o formato/parsing do ledger (R2/R5/R1 são outra fatia). NÃO toque `install.sh`, `bootstrap.sh`, `template/**`, `.engrama/governance/**`, ADRs. Mantenha portabilidade BSD/GNU.
5. CRITÉRIOS DE ACEITE:
   - `bash tests/gate/critique-gate.test.sh`: G1–G7 seguem `[ok]`; R3 e R4 agora DIVERGEM `[XX]` (passaram a BLOQUEAR). R1/R2/R5 seguem como estão.
   - `bash tests/contract/bootstrap.test.sh`: segue 9/9 verde.
   - `shellcheck` limpo em `.engrama/scripts/critique-gate.sh` e `.engrama/scripts/critique-gate-hook.sh`.
   - `.github/workflows/ci.yml` é YAML válido e roda os passos descritos.
6. VALIDAÇÕES: cole as saídas de `shellcheck` e `bash tests/run.sh`.
7. RISCOS: a mudança para `-z`/stream pode quebrar o early-exit ou a classificação — G1–G7 verdes é a prova de não-regressão. O fail-closed de detached HEAD não pode bloquear branches normais (G-suite usa `main`/`slice/1`).
8. DEPENDE DA AUTORIDADE: o commit (do Orquestrador após auditoria).
9. PRÓXIMO PASSO: Orquestrador re-roda os testes, promove R3/R4 a CORRETO, e leva ao commit.
10. TIER: T4 (gate é o coração do sistema), effort alto.

RESPONDA nos 6 itens do Executor (leitura · crítica · veredito `concordo|ajuste-menor|discordo` · execução · evidências · pendências). Em português.
