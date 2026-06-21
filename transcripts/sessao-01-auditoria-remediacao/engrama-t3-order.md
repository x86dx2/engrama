Você é o EXECUTOR (Executor Crítico). Tier T4 (o coração do enforcement + mudança de gramática do ledger). Critique antes de executar. cwd = raiz do repo "engrama", branch `absorcao/t3-atestacao`.

OBJETIVO: mitigar o furo R1 (auto-aprovação local: hoje uma linha `confirmo` na branch libera QUALQUER diff naquela branch+categoria, e um `confirmo` velho vale para um diff novo). Absorção do walrus (prova verificável > convenção). Solução: **vincular a crítica ao conteúdo do diff** (diff-binding) por hash, de forma BACKWARD-COMPATIBLE. SEJA HONESTO: isto prova que a crítica cobre ESTE diff; NÃO prova identidade independente do crítico (isso exigiria assinatura/chave que o `codex exec` não expõe) — documente esse teto.

ORDEM (5 entregas):

A) `engrama-diff-hash.sh` (raiz, bash portável, `set -u`): imprime um FINGERPRINT ESTÁVEL do diff staged, EXCLUINDO o próprio ledger. Use uma base estável a formatação de patch: `git diff --cached --raw -z -- . ':(exclude).engrama/qa/criticas-do-executor.md'` (os blob-shas do --raw são estáveis) passado por `sha256sum`/`shasum -a 256` (detecte qual existe — macOS tem `shasum`, Linux `sha256sum`). Saída: `sha256:<hex>` ou só `<hex>` (você decide; seja consistente com o gate). Fonte ÚNICA do cálculo — o gate e o crítico chamam ISTO, nunca recomputam à mão.

B) `.engrama/scripts/critique-gate.sh` — diff-binding BACKWARD-COMPATIBLE:
   - Estenda a gramática do ledger: o campo 4 (ref) pode conter, opcionalmente, um token `sha256:<hex>`.
   - Lógica por categoria (mantendo o parsing por campo já existente):
     * entrada com `sha256:<hex>` que **bate** com o fingerprint atual (via `engrama-diff-hash.sh`) → match FORTE (libera).
     * entrada com `sha256:<hex>` que **NÃO bate** → vínculo obsoleto: NÃO conta como OK (e idealmente bloqueia com mensagem "crítica vinculada a outro diff").
     * entrada SEM `sha256:` → comportamento LEGADO atual (libera se veredito OK por campo) — preserva G1–G7/R2–R5/fuzz.
   - **Modo estrito (CI/opt-in):** se `ENGRAMA_REQUIRE_DIFF_BIND=1`, então SÓ o match forte conta (entradas sem hash não satisfazem). Default (sem a env) = backward-compatible.
   - Se mexer no gate: rode `sync-template.sh` e mantenha `sync.test.sh` verde.

C) `tests/gate/diffbind.test.sh` (padrão das suítes, fail-fast): prove
   (i) entrada com hash que bate o diff staged → LIBERA;
   (ii) hash que NÃO bate (ou arquivo editado após a crítica) → BLOQUEIA;
   (iii) entrada SEM hash → comportamento legado preservado (libera com veredito OK);
   (iv) `ENGRAMA_REQUIRE_DIFF_BIND=1` exige hash (entrada sem hash NÃO satisfaz → bloqueia);
   (v) o fingerprint é estável: recomputar duas vezes sobre o mesmo staged dá o mesmo hash, e muda quando um arquivo (não-ledger) muda.

D) NÃO regredir: `tests/run.sh` inteiro segue verde (G1–G7, R2–R5, fuzz 200, lint, sync, ci, session, contract). As suítes existentes usam ledger SEM hash → caminho legado → inalteradas. Se a fuzz tiver um oracle que precise saber do hash, mantenha-o coerente (o caminho sem-hash é o atual).

E) `.engrama/decisions/0011-diff-binding-atestacao-verificavel.md` (ADR novo, schema do Engrama: frontmatter type=decision/status=active/touches/date/source_refs): Contexto (R1), Decisão (diff-binding backward-compat + modo estrito em CI), Alternativas (sha256 do patch textual — rejeitado por instabilidade; assinatura criptográfica — o teto ideal, mas exige chave/identidade que o `codex exec` não expõe hoje), Consequências (uma crítica vale para 1 diff; editar após a crítica invalida; legado preservado; **honesto: prova cobertura do diff, NÃO independência do crítico**). Linke [[gaps/auditoria-e-plano-de-remediacao]] e [[decisions/0006-governanca-nao-se-autoaprova]]. Propague ao template (genericizado: `{{REPO_PATH}}`/`{{DATA}}`, sem refs a este repo) e atualize `index.md` (raiz e template) + `classify()` se `engrama-diff-hash.sh` precisar entrar como `gate`.

FRONTEIRAS: não toque install/bootstrap; não mude a prosa de outros ADRs; portabilidade BSD(shasum)/GNU(sha256sum). Não comite.

ACEITE (cole as saídas): `engrama-diff-hash.sh` roda e dá hash estável; `bash tests/run.sh` verde incl. diffbind.test; prova manual dos 5 casos de (C); `shellcheck` limpo nos arquivos novos/alterados; `sync.test.sh` verde; `bash lint.sh` verde (ADR novo com frontmatter + wikilinks ok); ADR 0011 honesto sobre o teto (não promete independência).

RESPONDA nos 6 itens do Executor. Em português.
