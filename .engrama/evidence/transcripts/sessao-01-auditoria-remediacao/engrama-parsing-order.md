Você é o EXECUTOR (Executor Crítico). Tier T4 (coração do sistema: o parsing do gate). Critique antes de executar. cwd = raiz do repo "engrama", branch `remediacao/auditoria-engrama`.

CONTEXTO: a suíte `tests/gate/critique-gate.test.sh` tem G1–G7 (CORRETO, devem continuar verdes), R3/R4 (já corrigidos, CORRETO) e R1/R2/R5 (furos). Esta fatia corrige **R2 e R5**. NÃO mexa em R1.

ORDEM:
1. OBJETIVO: trocar o matching do ledger de "grep de substring na linha inteira" por **PARSING POR CAMPO**, fechando R2 (`nao confirmo` libera porque casa o substring `confirmo`) e R5 (entrada de OUTRA branch que cita o nome da branch atual no texto livre libera). SEM regredir G1–G7 nem R3/R4.
2. ESTADO FACTUAL: hoje, em `.engrama/scripts/critique-gate.sh` (loop por categoria, ~linhas 80–95), o gate faz `grep -F " $BRANCH "` na linha inteira e detecta veredito por `grep -iE "$OK_TOKENS"` (substring). Formato do header de cada entrada do ledger: `## [YYYY-MM-DD] <branch> | [tag1][tag2] <superficie> | <veredito> | <ref>`.
3. ESCOPO: editar APENAS `.engrama/scripts/critique-gate.sh` (a lógica de matching). Pode adicionar uma função de parsing.
4. GRAMÁTICA a implementar (por linha do ledger que comece com `## [`):
   - separe a linha por `|`; campo1=`## [data] <branch>`, campo2=tags+superficie, campo3=veredito, campo4=ref.
   - extraia a branch do campo1 removendo o prefixo `## [YYYY-MM-DD] ` e dando trim.
   - uma entrada CONTA para (categoria <cat>, branch atual) SE: branch_extraida == BRANCH (igualdade EXATA → fecha R5) **E** campo2 contém a substring literal `[<cat>]` **E** o veredito (campo3, trim) é um token OK por **igualdade exata** (`confirmo`, `confirmo-bug`, `ressalvas`, `dispensada`) **ou prefixo** (`N/A:`, `waiver`) — NUNCA por substring solto (`nao confirmo` ≠ `confirmo` → fecha R2).
   - OBJEÇÃO: se campo3 (trim, case-insensitive) começa com `objec`/`objeç`/`discordo` e NÃO há `waiver` no campo3 → a categoria fica BLOQUEADA (preserva G3).
   - linhas que não casam a gramática (bullets `-`, separadores) são ignoradas.
   - preserve: rejeição de `pendente` (G4); leitura via `git show :LEDGER` staged/HEAD (G7); branch space-exact (G5 — agora por igualdade de campo, ainda mais forte).
5. FRONTEIRAS (não tocar): NÃO edite `tests/**` (a quebra de R2/R5 é o sinal; o Orquestrador promove). NÃO edite a doc do ledger (`.engrama/qa/criticas-do-executor.md`) — o Orquestrador atualiza o formato. NÃO implemente R1 (sha256/vínculo ao diff). NÃO toque install/bootstrap/template/governance/ADR/hook/CI.
6. CRITÉRIOS DE ACEITE:
   - `bash tests/gate/critique-gate.test.sh`: G1–G7 e R3/R4 seguem `[ok]`; **R2 e R5 agora DIVERGEM `[XX]`** (passaram a BLOQUEAR). R1 segue `[ok]` FURO.
   - `bash tests/contract/bootstrap.test.sh`: 9/9 verde.
   - **NÃO QUEBRAR O HISTÓRICO REAL:** as entradas reais em `.engrama/qa/criticas-do-executor.md` para a branch `remediacao/auditoria-engrama` com `confirmo` precisam continuar VÁLIDAS. Prove: `git add -A` num arquivo sensível qualquer + rode `bash .engrama/scripts/critique-gate.sh` → deve LIBERAR (exit 0) pela entrada confirmo desta branch. (Depois desfaça o stage.)
   - `shellcheck .engrama/scripts/critique-gate.sh` limpo.
7. VALIDAÇÕES: cole shellcheck + `bash tests/run.sh` + a prova do gate ao vivo (item acima).
8. DEPENDE DA AUTORIDADE: o commit.
9. PRÓXIMO PASSO: Orquestrador promove R2/R5, atualiza a doc do formato do ledger, e leva ao commit.
10. TIER: T4, effort alto.

RESPONDA nos 6 itens do Executor. Em português.
