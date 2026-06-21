Você é o EXECUTOR (Executor Crítico). Tier T4 (refactor estrutural grande, com cascata de paths). Critique antes de executar. cwd = raiz do repo "engrama", branch `reorg/estrutura-akita`.

OBJETIVO: reorganizar a estrutura para o padrão do ai-memory (Akita): ROOT só com metadados/manifests; tooling e docs em pastas por preocupação. Use `git mv` para preservar histórico. NÃO comite. NÃO quebre nenhum teste (a suíte `tests/run.sh` é a rede). Faça SMOKE de install no fim.

=== A) MOVES (git mv) ===
Tooling do PACK (só repo-fonte) -> `bin/`:
  install.sh -> bin/install.sh
  bootstrap.sh -> bin/bootstrap.sh
  sync-template.sh -> bin/sync-template.sh
  critique-gate-ci.sh -> bin/critique-gate-ci.sh
Scripts da INSTÂNCIA (distribuídos) -> `.engrama/scripts/`:
  lint.sh -> .engrama/scripts/lint.sh
  engrama-diff-hash.sh -> .engrama/scripts/engrama-diff-hash.sh
Guias detalhados -> `docs/`:
  INSTALL.md -> docs/INSTALL.md
  INSTANTIATE.md -> docs/INSTANTIATE.md
Espelho no template (git mv):
  template/lint.sh -> template/.engrama/scripts/lint.sh
  template/engrama-diff-hash.sh -> template/.engrama/scripts/engrama-diff-hash.sh
ROOT fica com: README.md LICENSE CHANGELOG.md CLAUDE.md AGENTS.md .gitignore .markdownlint-cli2.yaml engrama.values.example (+ CONTRIBUTING.md/SECURITY.md novos) + as pastas.

=== B) CASCATA de paths (atualize TODAS) ===
1. `.engrama/scripts/lint.sh`: o REPO_ROOT NÃO pode mais ser o dir do script (agora é .engrama/scripts/). Use `REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"` (dois níveis acima) — mantém portabilidade sem depender de git. Reteste o caso L8 (clone p/ outro path).
2. `.engrama/scripts/engrama-diff-hash.sh`: usa `git rev-parse --show-toplevel` -> já portável, sem mudança (confirme).
3. `.engrama/scripts/critique-gate.sh`: a referência `DIFF_HASH_SCRIPT="$REPO_ROOT/engrama-diff-hash.sh"` -> `"$REPO_ROOT/.engrama/scripts/engrama-diff-hash.sh"`. E `classify()`: a linha de tooling muda — `bootstrap.sh|install.sh|...|engrama.values.example) addcat gate` vira `bin/*) addcat gate` + `engrama.values.example) addcat gate`; lint.sh/engrama-diff-hash.sh já casam `.engrama/scripts/*.sh) addcat gate`; remova refs a `template/engrama-diff-hash.sh`/`template/lint.sh` (agora sob `template/.engrama/scripts/*.sh`); docs: `README.md|INSTALL.md|INSTANTIATE.md) addcat governance` vira `README.md) addcat governance` + `docs/*) addcat governance`. Rode `sync-template.sh` depois para propagar ao template.
4. `bin/install.sh`: `TEMPLATE="$HERE/template"` -> `"$HERE/../template"`. O `find`/rsync e o relatório de placeholders seguem relativos ao ROOT do alvo (não mudam).
5. `bin/bootstrap.sh`: `INSTALLER="$HERE/install.sh"` -> continua `"$HERE/install.sh"` (ambos em bin/). Confirme que as heurísticas usam `$ROOT` (do alvo), não `$HERE`.
6. `bin/sync-template.sh`: todas as refs `$HERE/.engrama/...` e `$HERE/template/...` -> `$HERE/../.engrama/...` e `$HERE/../template/...`. AGORA deve sincronizar TODOS os scripts da instância: `.engrama/scripts/{critique-gate.sh, critique-gate-hook.sh, session-context.sh, lint.sh, engrama-diff-hash.sh}` (não mais lint.sh do root). Mantenha a composição por seções do gate + a reaplicação das vars-placeholder/classify do template. `sync.test.sh` tem que ficar verde e idempotente.
7. `bin/critique-gate-ci.sh`: refs ao gate (`.engrama/scripts/critique-gate.sh`) e ao diff-hash (`.engrama/scripts/engrama-diff-hash.sh`) e ao ledger — ajuste; usa `$HERE`/repo-root conforme — garanta que funcione chamado como `bin/critique-gate-ci.sh`.
8. `.github/workflows/ci.yml`: shellcheck -> `shellcheck bin/*.sh .engrama/scripts/*.sh .engrama/githooks/pre-commit tests/run.sh tests/gate/*.test.sh tests/contract/*.test.sh`; `bash lint.sh` -> `bash .engrama/scripts/lint.sh`; o step do gate-contra-PR `bash ./critique-gate-ci.sh` -> `bash ./bin/critique-gate-ci.sh`.
9. TESTES (atualize os paths hardcoded):
   - `tests/gate/critique-gate.test.sh` e `tests/gate/diffbind.test.sh`: `DIFF_HASH_SRC="$REPO_ROOT/engrama-diff-hash.sh"` -> `.engrama/scripts/engrama-diff-hash.sh`; e onde copiam o helper p/ o repo sintético, copie p/ `.engrama/scripts/`.
   - `tests/gate/ci.test.sh`: se referencia `critique-gate-ci.sh`, -> `bin/critique-gate-ci.sh`.
   - `tests/contract/bootstrap.test.sh`: `install.sh`/`bootstrap.sh` -> `bin/install.sh`/`bin/bootstrap.sh`.
   - `tests/contract/lint.test.sh`: `lint.sh` -> `.engrama/scripts/lint.sh` (inclusive o caso L8 do clone).
   - `tests/contract/sync.test.sh`: caminhos do gate/helper/sync conforme acima.
10. DOCS (atualize comandos e árvores): `README.md` (árvore do pack + `bash ./install.sh`->`bash bin/install.sh`, `bootstrap.sh`->`bin/bootstrap.sh`; links p/ docs/INSTALL.md, docs/INSTANTIATE.md), `docs/INSTALL.md`, `docs/INSTANTIATE.md`, `.engrama/CLAUDE.md` (bloco "Estrutura": scripts/ agora lista critique-gate + hook + session-context + lint + engrama-diff-hash; idem no template), `bootstrap-do-projeto.md` (comandos canônicos se citarem install.sh).

=== C) METADADOS NOVOS (root) ===
- `CONTRIBUTING.md`: fluxo de contribuição = branch -> PR -> CI verde -> merge; resumo do modelo de governança (Executor critica antes do commit; gate); como rodar `bash tests/run.sh` e `bash .engrama/scripts/lint.sh`. Conciso.
- `SECURITY.md`: como reportar vulnerabilidade (sem endpoint real — diga "abra issue privada/contato do mantenedor"); escopo honesto (gate local é cooperativo; enforcement vinculante = required check no CI); política de não commitar secrets. Conciso, honesto (princípio 12).

=== FRONTEIRAS ===
NÃO mude a LÓGICA do gate (só paths/classify) nem a prosa normativa dos ADRs/governance (só atualize referências de caminho). CLAUDE.md/AGENTS.md/README/LICENSE/CHANGELOG ficam no ROOT. Portabilidade BSD/GNU. NÃO comite.

=== ACEITE (cole TODAS as saídas) ===
- `git status` mostrando os renames (R) e os novos arquivos.
- `bash tests/run.sh` -> TODAS VERDES (todas as suítes; mesma contagem de antes + nada quebrado).
- `shellcheck bin/*.sh .engrama/scripts/*.sh` -> limpo.
- `bash .engrama/scripts/lint.sh` -> exit 0; e a PROVA de portabilidade (clone p/ outro path + lint exit 0).
- `bash bin/sync-template.sh` rodado 2x -> idempotente; `sync.test.sh` verde.
- SMOKE DE INSTALL (o mais importante): `bash bin/bootstrap.sh /private/tmp/eg-reorg-smoke-$$` -> rc 0; o projeto-alvo recebe `.engrama/scripts/{critique-gate.sh,lint.sh,engrama-diff-hash.sh}`, `0` placeholders crus, e o gate instalado BLOQUEIA governança sem ledger. Cole as evidências.
- nenhum path órfão: `grep -rnE '(\.\./)?(install|bootstrap|sync-template|critique-gate-ci|lint|engrama-diff-hash)\.sh' --include='*.sh' --include='*.yml' --include='*.md' . | grep -vE 'bin/|\.engrama/scripts/|docs/|tests/'` -> idealmente vazio (ou só ocorrências legítimas).

RESPONDA nos 6 itens do Executor. Em português.
