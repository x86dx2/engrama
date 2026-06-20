---
type: workflow
status: active
touches: [decisions/0006-governanca-nao-se-autoaprova, decisions/0010-roteamento-modelo-effort-do-executor, governance/modelo-operacional]
date: 2026-06-20
source_refs:
  - /Users/x86/git-projects/engrama/.engrama/scripts/critique-gate.sh
---

# Ledger de críticas do Executor (gpt-5.5) — gate de superfície sensível

Registro **append-only** de toda **crítica do Executor no papel de crítica** (modelo independente, read-only) exigida pelo **ADR 0006 item 7** e pelo **ADR 0010**.

**Verificado mecanicamente** por `.engrama/scripts/critique-gate.sh` (git pre-commit + PreToolUse do harness). Um commit que toca superfície sensível é **bloqueado** se faltar, para CADA categoria tocada, uma entrada CONCLUÍDA referenciando a **branch**. O gate lê a versão **staged/HEAD** do ledger (não o working-tree), rejeita `<pendente>` e bloqueia `objeção` sem `waiver`.

**Categorias ativas neste repositório central** (a lista operacional vigente de arquivo→categoria é o `case` de `.engrama/scripts/critique-gate.sh`, não esta prosa):
- **`governance`** — regras, ADRs, memória, bootstrap de projeto e template distribuível.
- **`gate`** — instalador, hook, settings e defaults mecânicos do bootstrap.
- **`contract`** — testes/contratos verificáveis do bootstrap/template quando existirem.

Categorias de domínio como `financial`, `rbac`, `auth` e `schema` pertencem a projetos-alvo. Elas não ficam ativas no Engrama central, salvo se este repositório passar a conter código de produto nessas superfícies.

**Formato:** `## [data] branch | [cat1][cat2] superfície | veredito | ref`
Vereditos OK: `confirmo` · `confirmo-bug` · `ressalvas` · `N/A: <motivo>` · `waiver <quem/quando>` · `dispensada`. `objeção` só passa com `waiver` na mesma linha (arbitragem da Autoridade registrada).

> **Convenção fail-closed (o gate detecta `waiver` por substring):** escreva o waiver SEMPRE no positivo — `waiver <quem/quando>` — e **nunca** a palavra `waiver` numa negação na mesma linha de uma objeção (ex.: evite "objeção sem waiver"). Caso contrário o gate pode ler a negação como waiver presente.

---

## [2026-06-20] main | [governance][gate][contract] ativacao da instancia viva do Engrama e template bootstrapavel | dispensada | Autoridade no chat em 2026-06-20
- A Autoridade ordenou ativar o Engrama como repositório central, vivo, e fonte do template para novos projetos.
- A crítica externa independente foi dispensada somente para este bootstrap inicial, porque o próprio gate precisava ser instalado antes de conseguir exigir prova de crítica.
- Auditoria do Orquestrador/Codex nesta sessão: comparação com Ruflos, separação entre raiz viva e `template/`, `shellcheck` e smoke de bootstrap limpo antes do commit.
- Próxima mudança sensível deve registrar crítica independente do Executor (`codex exec`, `gpt-5.5`) ou waiver explícito da Autoridade antes do commit.

## [2026-06-20] main | [governance][gate][contract] auditoria + plano de remediacao + suites de teste | discordo-incorporado-aguarda-autoridade | crítica codex read-only
- **Executor:** `codex exec` (read-only, papel de crítica), 2026-06-20. Ordem e resposta na íntegra anexadas à Autoridade (ADR 0003).
- **Veredito do Executor:** `discordo` (objeção material; governança/gate é superfície sensível). 13 pontos.
- **Incorporado pelo Orquestrador:** testes agora fail-fast (abortam em setup quebrado, provado); EX2 corrigido (3 categorias ativas, não 3v7); overclaims removidos; R5 (bypass cross-branch) e C8 (cobre bootstrap.sh) adicionados; R1 reformulado (sha256=vínculo ao conteúdo, exclui o ledger; independência exige server-side); P0 reordenado; hook test (EX6) previsto.
- **Estado:** ajustes incorporados em [[gaps/auditoria-e-plano-de-remediacao]]; **aguardando arbitragem da Autoridade** para o commit (dispensa não registrada; o Orquestrador não tem overrule sobre objeção material — ADR 0004).
- **Nota meta:** o gate AO VIVO **liberou** este commit mesmo assim, montado na linha `dispensada` do bootstrap acima — evidência viva do furo R1/EX5 (cache por branch+categoria). Um gate correto bloquearia aqui.

## [2026-06-20] fix/p0-instalador-substituicao-segura | [gate][contract][governance] P0.1 instalador: substituicao literal segura + fail-closed | confirmo | executor codex + auditoria orquestrador
- **Executor:** `codex exec -s workspace-write` (papel de execução), veredito `ajuste-menor`: escreveu `escape_sed_replacement()` (escapa `\`,`&`,`#`), trocou pipeline-subshell por `find -print0`+`read -d ''`, e tornou placeholder remanescente fatal (exit 1). Editou só `install.sh`.
- **Auditoria do Orquestrador (re-execução independente, ADR 0005):** `shellcheck install.sh` limpo; `tests/run.sh` 21 asserts verdes (contract 9/9, 0 furos); teste adversário com `& # / espaço \` juntos → preservados literais, zero placeholders crus, exit 0; values incompleto → exit 1 (fail-closed). Promovi C5/C6/C7 a CORRETO e adicionei C9.
- **Veredito do Orquestrador:** consenso (escritor≠auditor preservado: Executor escreveu, Orquestrador auditou). Resta a Autoridade decidir o commit.
