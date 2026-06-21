Você é o EXECUTOR (Executor Crítico). Tier T3. Critique antes de executar. cwd = raiz do repo "engrama", branch `fix/source-refs-relativos`.

PROBLEMA (item 6 / EX4): os `source_refs` no frontmatter usam caminhos ABSOLUTOS (`/Users/x86/git-projects/engrama/...` na raiz; `{{REPO_PATH}}/...` no template), que NÃO sobrevivem a clone/move/CI — contradizem a promessa de portabilidade. O `lint.sh` hoje só TOLERA isso resolvendo o sufixo. OBJETIVO: migrar `source_refs` para caminhos RELATIVOS à raiz do repo.

ORDEM:
A) Em TODOS os `.engrama/**/*.md` da RAIZ: nos blocos `source_refs:`, trocar `/Users/x86/git-projects/engrama/<X>` por `<X>` (relativo à raiz; ex.: `.engrama/scripts/critique-gate.sh`). NÃO toque outros usos de caminho fora de `source_refs`.
B) Em TODOS os `template/.engrama/**/*.md`: nos `source_refs:`, trocar `{{REPO_PATH}}/<X>` por `<X>` (relativo). Mantenha `{{REPO_PATH}}` onde ele indica a RAIZ do repo fora de source_refs (ex.: `SOURCE_OF_TRUTH_REPO: {{REPO_PATH}}` no schema, e `{{DATA}}`/outros placeholders).
C) SCHEMA `.engrama/CLAUDE.md` (raiz E template): a regra normativa "linka **caminho absoluto** via `source_refs`, nunca copia" → "linka **caminho relativo à raiz do repo** via `source_refs`, nunca copia". E o exemplo de frontmatter (`source_refs: - /Users/.../...` na raiz; `- {{REPO_PATH}}/...` no template) → relativo (`- .engrama/...`). O comentário "# caminhos absolutos no repo" → "# caminhos relativos à raiz do repo".
D) `.engrama/scripts/lint.sh`: a checagem de `source_refs` deve validar caminhos RELATIVOS (existência sob a raiz do repo). Pode MANTER o fallback p/ absolutos legados (compat), mas o caminho primário agora é relativo. Garanta que o lint fica VERDE no repo real após a migração e continua PORTÁVEL (clone p/ outro path → lint exit 0 — o caso L8).
E) TESTES: `tests/contract/lint.test.sh` — se algum fixture/caso usa source_ref absoluto, cubra também o RELATIVO (válido) e mantenha um caso de source_ref QUEBRADO (relativo inexistente) que o lint pega. Mantenha TODAS as suítes verdes.
F) Rode `bin/sync-template.sh` se mexer no gate/helper (aqui provavelmente não muda os scripts sincronizados, mas confirme `sync.test.sh` verde).

FRONTEIRAS: NÃO mude a lógica do gate; NÃO toque prosa normativa além da regra de source_refs e do exemplo de schema; portabilidade BSD/GNU. Não comite.

ACEITE (cole as saídas):
- `grep -rl '/Users/x86' .engrama --include='*.md'` → VAZIO (zero absolutos na raiz); `grep -rl '{{REPO_PATH}}/' template/.engrama --include='*.md'` → vazio nos source_refs (só onde for SOURCE_OF_TRUTH_REPO/raiz legítima, se houver).
- `bash .engrama/scripts/lint.sh` → exit 0; PROVA de portabilidade (clone p/ outro path → lint exit 0).
- `bash tests/run.sh` → TODAS VERDES; `shellcheck` limpo; `sync.test.sh` verde.
- SMOKE: `bash bin/bootstrap.sh /private/tmp/eg-sr-$$` → o projeto-alvo tem `source_refs` RELATIVOS (sem `/Users` nem `{{REPO_PATH}}`); `grep -r '/Users\|{{REPO_PATH}}' "$alvo/.engrama"` nos source_refs → vazio.

RESPONDA nos 6 itens do Executor. Em português.
