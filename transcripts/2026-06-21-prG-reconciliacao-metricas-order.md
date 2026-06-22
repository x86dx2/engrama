# Ordem ao Executor — PR-G: absorção de mem0/Honcho (reconciliação + métricas)

Branch já criada: `feat/absorcao-reconciliacao-metricas`. Sandbox: workspace-write. **NÃO comitar.** Critique antes; o ADR 0012 é decisão de governança — quero sua crítica de mérito.

## ⚠️ ISOLAMENTO (regra pós-incidente)
NUNCA rode `git config`/`git add`/`git commit`/`git checkout` no repo real. Todo smoke com git roda em `T=$(mktemp -d)` com `git -C "$T"` + identidade só no temp. Não altere a config git do repo real.

## Contexto
Uma análise de absorção (Honcho/mem0) verificada adversarialmente aprovou um punhado de PADRÕES (não infra de runtime — o engrama é markdown/gate, sem DB/embeddings/API). Esta fatia implementa o cluster "operações de memória + métricas". Mantenha o estilo da casa. `lint.sh` é sincronizado ao template via `bash bin/sync-template.sh` (sync.test exige paridade).

## Item 1 — ADR 0012: reconciliação explícita de memória (de mem0 + RFC IETF)
Crie `.engrama/decisions/0012-reconciliacao-de-memoria.md` (e a cópia espelhada em `template/.engrama/decisions/` se a convenção do repo for manter ADRs no template — confirme olhando se template/.engrama/decisions existe e como os outros ADRs estão lá; replique o padrão). Decisão: ao registrar um fato/ADR/página nova, marcar explicitamente a **operação de reconciliação** contra a memória existente, inspirado no ADD/UPDATE/DELETE/NOOP do mem0 e no `Obsoletes:`/`Updates:` das RFCs do IETF. Defina o campo de frontmatter **opcional** `reconcilia: <OP> <slug-alvo>` com `OP ∈ {ADD, UPDATE, DELETE, NOOP}`:
- `ADD` = fato/decisão genuinamente novo (slug-alvo opcional/ausente).
- `UPDATE <slug>` = complementa/ajusta uma página existente sem invalidá-la.
- `DELETE <slug>` = supersede/invalida (casar com o `status: superseded` + ponteiro que o lint já exige).
- `NOOP <slug>` = reafirma sem mudança material (raro; útil pra registrar que algo foi reavaliado).
Contexto/decisão/alternativas/consequências/status. Honesto: é **disciplina + campo validável**, não automação — a detecção de duplicata é humana/`grep`, não um motor. Recomendado (convenção) para ADRs que afetam governança; opcional no resto. **Dogfood:** ponha um `reconcilia:` coerente no frontmatter do próprio 0012.

## Item 2 — Campo no schema
Em `.engrama/CLAUDE.md` (schema, seção "Frontmatter obrigatório"/convenções): documente `reconcilia:` como campo **opcional** com o enum e a semântica. Se fizer sentido, uma menção curta no `CLAUDE.md` raiz (gate) — só se não inflar. Espelhe no `template/.engrama/CLAUDE.md`.

## Item 3 — lint.sh: validação do `reconcilia:` + staleness + nomear órfãs
No `.engrama/scripts/lint.sh` (raiz; depois `bash bin/sync-template.sh`):
1. **Validar `reconcilia:` quando presente** (ausente = ok, é opcional): `OP` deve estar no enum; para `UPDATE/DELETE/NOOP` o slug-alvo deve resolver a uma página existente (reuse o resolvedor de wikilink/slug que já existe). Malformado = **erro bloqueante**; ausente = silêncio.
2. **Staleness (warning NÃO-bloqueante):** para páginas com `status: active` em `governance/`, `specs/`, `decisions/`, avise se a última modificação for > 90 dias. **Use a data do último commit que tocou o arquivo (`git log -1 --format=%ct -- <file>`), NÃO o mtime do filesystem** (clone reseta mtime). Aceite override `ENGRAMA_NOW=<epoch>` p/ teste determinístico (default: `date +%s`). Staleness é **warning**: imprime mas **não** muda o exit code (separe o canal de warning do de erro). Se hoje nada estiver stale (repo recém-tocado), tudo bem — é um check latente.
3. **Nomear a métrica de órfãs:** a detecção de páginas órfãs que já existe é a métrica de "densidade de enlaces" — só adicione um comentário/nota no `usage()`/cabeçalho nomeando-a como tal (cosmético).

## Item 4 — gaps/metricas-de-engrama.md (proposed)
Crie `.engrama/gaps/metricas-de-engrama.md` com `status: proposed`. Registre: métricas **já implementadas** (densidade de enlaces = órfãs; staleness = recém-adicionada) e as **abertas como pesquisa futura** (cobertura, coerência semântica) — deixando EXPLÍCITO que NÃO entram como infra de runtime (sem DB/embeddings); markdown-puro tem teto (falsos-positivos). Linke o ADR 0012.

## Item 5 — testes
Estenda `tests/contract/lint.test.sh` (ou o arquivo de teste do lint) provando sensibilidade: (a) `reconcilia: UPDATE <slug-existente>` passa; `reconcilia: XPTO ...` e `reconcilia: UPDATE slug-inexistente` bloqueiam; ausência é ok. (b) staleness: com `ENGRAMA_NOW` setado p/ um futuro distante, um arquivo active dispara o warning MAS o exit fica 0 (não-bloqueante). Siga o padrão bloqueia/libera dos testes existentes.

## Item 6 — index + sync
Atualize `.engrama/index.md` (ADR 0012 + gaps/metricas). Rode `bash bin/sync-template.sh` p/ propagar lint.sh + schema. 

## Saída
Liste arquivos tocados. Rode `bash tests/run.sh`, `bash .engrama/scripts/lint.sh` (no próprio repo — deve ficar verde, sem stale hoje), `shellcheck -S info` (incl. lint.sh), `bash tests/contract/sync.test.sh`. Diga o veredito de mérito sobre o ADR 0012.
