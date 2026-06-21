Você é o EXECUTOR (Executor Crítico). Tier T3. Critique antes de executar. cwd = raiz do repo "engrama".

CONTEXTO: o schema `.engrama/CLAUDE.md` DOCUMENTA um workflow "Lint" (páginas órfãs, `source_refs` que mudaram, ADRs `superseded` sem ponteiro, contradições, wikilinks faltando) mas NÃO existe código que o execute — mesma lacuna "prega-mas-não-pratica" que já corrigimos nos testes. Esta fatia entrega o Lint + fuzz do parser do gate + jobs de CI de qualidade. Absorção dos projetos ai-memory (curator/lint), walrus (simulation/fuzz + markdown-lint/secret-scan).

ORDEM (3 entregas):

A) `lint.sh` (raiz) — linter do Engrama, bash portável (BSD/GNU), `set -u`. Checa, sobre `.engrama/**/*.md` (e a raiz `CLAUDE.md`/`AGENTS.md`):
   - **Wikilinks órfãos:** todo `[[slug]]` deve resolver para um arquivo existente. Regra de resolução: `[[x/y]]` -> `.engrama/x/y.md`; `[[log]]` -> `.engrama/log.md`; `[[governance/index]]` -> `.engrama/governance/index.md`. (Use o mesmo mapeamento dos wikilinks já usados no repo.)
   - **source_refs quebrados:** todo caminho sob `source_refs:` no frontmatter que não existe no disco.
   - **Frontmatter:** páginas em `.engrama/decisions|governance|specs|gaps|project|qa/` devem ter frontmatter YAML com pelo menos `type`, `status`, `date` (log.md e index.md são isentos — são índices).
   - **ADR superseded sem ponteiro:** ADR com `status: superseded` deve linkar o ADR que o substitui.
   Saída: lista os problemas por arquivo:linha; `exit 0` se limpo, `exit 1` se houver erro. Aceite um flag `--report` (só reporta, exit 0) vs default estrito.
   IMPORTANTE: rode `bash lint.sh` no repo REAL e ou deixe-o LIMPO (corrigindo problemas triviais reais que achar — ex.: um wikilink/ref quebrado), ou liste os problemas não-triviais nas pendências para o Orquestrador triar. NÃO invente correções em prosa normativa; correção de link/ref quebrado é trivial e ok.

B) `tests/contract/lint.test.sh` (padrão das suítes: `set -u`, fail-fast com mktemp/git, função `check`): monta fixtures temporários e prova que o lint PEGA: wikilink órfão, source_ref quebrado, frontmatter ausente, ADR superseded sem ponteiro; e PASSA num fixture limpo. Inclua um caso que roda `lint.sh` no próprio repo e exige exit 0 (regressão).

C) `tests/gate/fuzz.test.sh` (absorção walrus — simulation/property): gera N (ex.: 200) linhas de ledger e listas de arquivos PSEUDO-aleatórias (determinístico: use um contador/seed fixo, NÃO `$RANDOM`/date — o ambiente proíbe) e afirma INVARIANTES do gate sobre elas, ex.: (i) nunca LIBERA uma categoria sensível sem um veredito OK por campo para a branch exata; (ii) `objeção`/`discordo` sem `waiver` no campo 3 nunca libera; (iii) branch que só aparece no texto livre (não no campo 1) nunca casa. Monte repos sintéticos como nas outras suítes. Sem dependência externa.

D) `.github/workflows/ci.yml` — adicionar (sem quebrar o existente):
   - step que roda `bash lint.sh` (lint do Engrama);
   - job/step **gitleaks** (secret scan) — use a action oficial `gitleaks/gitleaks-action@v2` ou `docker run zricethezav/gitleaks`;
   - step **markdown-lint** (ex.: `DavidAnson/markdownlint-cli2-action` ou `npx markdownlint-cli2`), com config tolerante (não falhar por linha-longa; foco em links quebrados/estrutura).
   Mantenha shellcheck e `tests/run.sh`. Adicione `lint.sh` ao `shellcheck`.

E) `classify()` do gate: adicionar `lint.sh) addcat gate` (é tooling sensível). Se mexer no gate, rode `sync-template.sh` e mantenha `sync.test.sh` verde.

FRONTEIRAS: não toque a prosa normativa de governança (ADRs/governance) exceto consertar um link/ref quebrado trivial achado pelo lint; não toque install/bootstrap; não mude a lógica do gate (só o classify, se necessário). Portabilidade BSD/GNU. Não comite.

ACEITE (cole as saídas): `bash lint.sh` no repo real → exit 0 (ou pendências listadas); `bash tests/run.sh` verde incl. lint.test e fuzz.test; `shellcheck lint.sh tests/contract/lint.test.sh tests/gate/fuzz.test.sh` limpo; `.github/workflows/ci.yml` YAML válido; se mexeu no gate, `sync.test.sh` verde.

RESPONDA nos 6 itens do Executor. Em português.
