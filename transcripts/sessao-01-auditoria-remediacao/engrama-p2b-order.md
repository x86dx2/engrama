Você é o EXECUTOR (Executor Crítico). Tier T4 (enforcement). Critique antes de executar. cwd = raiz do repo "engrama".

OBJETIVO: fazer a CI **reexecutar o gate contra o diff do PR**, tornando o enforcement server-side REAL (a doc hoje diz que isso é pendente — ver README/ADR 0006). Isso mitiga o furo R1 (auto-aprovação local), porque o controle passa a existir num lugar não-burlável pelo autor.

ESTADO FACTUAL: o gate local `.engrama/scripts/critique-gate.sh` checa `git diff --cached` (staged) + `git branch --show-current`. Em CI/PR NÃO há staging e o checkout costuma ser DETACHED HEAD (que o gate agora fail-closa, de propósito). Logo, precisa de um MODO CI com entrada diferente (lista de arquivos do PR + nome da branch do PR), reusando a MESMA lógica de classificação e de checagem do ledger (parsing por campo).

ESCOPO (escolha a mecânica de MENOR risco ao modo local):
A) MODO CI reusando a lógica: ou um wrapper `critique-gate-ci.sh` na raiz, ou um modo no próprio gate guardado por flag/env. Requisito: o caminho LOCAL (pre-commit) NÃO pode mudar de comportamento — G1–G7/R2–R5 e a suíte atual seguem verdes. O modo CI recebe (via args/env) a LISTA de arquivos mudados e o NOME da branch do PR, e aplica `classify()` + a checagem do ledger por campo. Bloqueia (exit!=0) se faltar crítica registrada para alguma categoria.
B) `.github/workflows/ci.yml`: adicionar, no evento `pull_request`, passos que computam os arquivos mudados (`git diff --name-only -z "origin/${{ github.base_ref }}...HEAD"` com `fetch-depth: 0`/fetch da base) e a branch do PR (`${{ github.head_ref }}`), e chamam o modo CI. Mantenha o job atual (shellcheck + tests/run.sh).
C) TESTES LOCAIS do núcleo: `tests/gate/ci.test.sh` (padrão das outras suítes — set -u, fail-fast, check): dado (branch, lista de arquivos), o modo CI BLOQUEIA governança sem ledger; LIBERA com `confirmo` da branch; mantém parsing por campo (entrada de outra branch que cita o nome no texto NÃO libera). Pelo menos 3-4 casos.

FRONTEIRAS:
- Se você MEXER em `.engrama/scripts/critique-gate.sh`, rode `bash sync-template.sh` para propagar ao template e mantenha `tests/contract/sync.test.sh` verde (não deixe drift). Se usar um wrapper separado, não precisa.
- Não toque prosa de governança, `install.sh`, `bootstrap.sh`, nem as suítes existentes (só CRIE a nova ci.test.sh).
- Portabilidade BSD/GNU.
- HONESTIDADE: no cabeçalho/comentário, deixe claro que a INTEGRAÇÃO GitHub (refs/env) é validada por revisão, e o NÚCLEO (classify+ledger por branch+arquivos) é validado por teste local. Não overclaime.

ACEITE (cole as saídas):
- `bash tests/run.sh` verde, incluindo o novo `ci.test.sh`; o modo local intacto (G1–G7/R2–R5 inalterados).
- prova do modo CI: invoque-o com uma branch+lista de arquivos sem ledger → bloqueia; com `confirmo` no ledger daquela branch → libera.
- `shellcheck` limpo nos arquivos novos/alterados.
- `.github/workflows/ci.yml` é YAML válido; descreva o que cada passo faz.
- se o gate mudou: `bash sync-template.sh` idempotente + `tests/contract/sync.test.sh` verde.

RESPONDA nos 6 itens do Executor. Em português.
