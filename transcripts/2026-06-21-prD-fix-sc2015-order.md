# Ordem ao Executor — fix de CI no PR-D (SC2015)

Branch atual: `feat/p1-atritos-do-adotante` (PR #9 aberto, CI vermelho). Sandbox: workspace-write. **NÃO comitar.**

A CI (shellcheck mais novo que o local) bloqueou em `bin/bootstrap.sh` linha 188:
```
diff_hash="$(cd "$ROOT" && bash ./.engrama/scripts/engrama-diff-hash.sh --cached 2>/dev/null || true)"
```
→ **SC2015** (`A && B || C` não é if-then-else; C pode rodar mesmo com A verdadeiro). Exit 1 no job `test` (ubuntu+macos).

Tarefa mínima, sem mudar comportamento:
1. Reescreva essa linha (e qualquer gêmea no código novo que você adicionou — `seed_bootstrap_dispensa`/`stage_bootstrap_snapshot`) para **não** cair no antipadrão `A && B || C`. Sugestão: isolar num subshell, ex.:
   `diff_hash="$( (cd "$ROOT" && bash ./.engrama/scripts/engrama-diff-hash.sh --cached) 2>/dev/null )" || diff_hash=""`
   (ou um `if`/bloco explícito) — o importante é o `|| fallback` recair sobre o subshell inteiro, não sobre o `&&` interno.
2. Rode `shellcheck -S info bin/*.sh .engrama/scripts/*.sh .engrama/githooks/pre-commit tests/run.sh tests/gate/*.test.sh tests/contract/*.test.sh` e garanta **zero** achados em `bin/bootstrap.sh` (e nada novo introduzido). Se o seu shellcheck local não acusar SC2015 (versão antiga), inspecione visualmente que nenhuma linha tem `cmd && cmd || cmd` que possa ser lido como if-then-else.
3. Rode `bash tests/run.sh` (deve seguir verde, incl. C12/C13) e `bash .engrama/scripts/lint.sh`.

Saída: a linha (ou linhas) tocada(s), e a evidência do shellcheck -S info limpo + suite verde.
