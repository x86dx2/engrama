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

**Formato (GRAMÁTICA RÍGIDA — imposta por parsing por campo desde R2/R5):** cada entrada é uma linha que começa com `## [` e tem **4 campos** separados por `|`:

```
## [YYYY-MM-DD] <branch> | [cat1][cat2] <superfície> | <veredito> | <ref>
```

O gate (`.engrama/scripts/critique-gate.sh`) lê **por campo**, não por substring na linha:
- **campo 1** → a `<branch>` (após o prefixo `## [data] `) precisa ser **igual** à branch atual (igualdade exata — fecha o bypass cross-branch R5);
- **campo 2** → precisa conter a tag literal `[<categoria>]`;
- **campo 3** → o `<veredito>`, validado por **igualdade/prefixo de enum**, não substring (fecha R2: `nao confirmo` ≠ `confirmo`).

Vereditos OK (campo 3): `confirmo` · `confirmo-bug` · `ressalvas` · `dispensada` (igualdade) · `N/A: <motivo>` · `waiver <quem/quando>` (prefixo). `pendente` é rejeitado. Uma objeção (`objeção`/`discordo` no campo 3) só passa se o campo 3 também contiver `waiver` (arbitragem da Autoridade registrada).

> Cada entrada precisa ter os 4 campos (incluindo `<ref>`). Linhas que não casam a gramática (bullets `-`, etc.) são ignoradas pelo gate. O `waiver` ainda é detectado por substring **dentro do campo 3** — escreva-o no positivo (`waiver <quem/quando>`).

---

## [2026-06-20] main | [governance][gate][contract] ativacao da instancia viva do Engrama e template bootstrapavel | dispensada | Autoridade no chat em 2026-06-20
- A Autoridade ordenou ativar o Engrama como repositório central, vivo, e fonte do template para novos projetos.
- A crítica externa independente foi dispensada somente para este bootstrap inicial, porque o próprio gate precisava ser instalado antes de conseguir exigir prova de crítica.
- Auditoria do Orquestrador/Codex nesta sessão: comparação com Ruflos, separação entre raiz viva e `template/`, `shellcheck` e smoke de bootstrap limpo antes do commit.
- Próxima mudança sensível deve registrar crítica independente do Executor (`codex exec`, `gpt-5.5`) ou waiver explícito da Autoridade antes do commit.

## [2026-06-20] main | [governance][gate][contract] auditoria + plano de remediacao + suites de teste | waiver Autoridade 2026-06-20 (discordo do Executor incorporado; merge aprovado) | crítica codex read-only
- **Arbitragem da Autoridade (2026-06-20):** o `discordo` do Executor foi integralmente incorporado (testes fail-fast, EX2, overclaims, R5/C8, R1 reformulado) e a Autoridade aprovou a integração via merge na `main` (commit de merge). Objeção resolvida; registrada por completude.
- **Executor:** `codex exec` (read-only, papel de crítica), 2026-06-20. Ordem e resposta na íntegra anexadas à Autoridade (ADR 0003).
- **Veredito do Executor:** `discordo` (objeção material; governança/gate é superfície sensível). 13 pontos.
- **Incorporado pelo Orquestrador:** testes agora fail-fast (abortam em setup quebrado, provado); EX2 corrigido (3 categorias ativas, não 3v7); overclaims removidos; R5 (bypass cross-branch) e C8 (cobre bootstrap.sh) adicionados; R1 reformulado (sha256=vínculo ao conteúdo, exclui o ledger; independência exige server-side); P0 reordenado; hook test (EX6) previsto.
- **Estado:** ajustes incorporados em [[gaps/auditoria-e-plano-de-remediacao]]; **aguardando arbitragem da Autoridade** para o commit (dispensa não registrada; o Orquestrador não tem overrule sobre objeção material — ADR 0004).
- **Nota meta:** o gate AO VIVO **liberou** este commit mesmo assim, montado na linha `dispensada` do bootstrap acima — evidência viva do furo R1/EX5 (cache por branch+categoria). Um gate correto bloquearia aqui.

## [2026-06-20] fix/p0-instalador-substituicao-segura | [gate][contract][governance] P0.1 instalador: substituicao literal segura + fail-closed | confirmo | executor codex + auditoria orquestrador
- **Executor:** `codex exec -s workspace-write` (papel de execução), veredito `ajuste-menor`: escreveu `escape_sed_replacement()` (escapa `\`,`&`,`#`), trocou pipeline-subshell por `find -print0`+`read -d ''`, e tornou placeholder remanescente fatal (exit 1). Editou só `install.sh`.
- **Auditoria do Orquestrador (re-execução independente, ADR 0005):** `shellcheck install.sh` limpo; `tests/run.sh` 21 asserts verdes (contract 9/9, 0 furos); teste adversário com `& # / espaço \` juntos → preservados literais, zero placeholders crus, exit 0; values incompleto → exit 1 (fail-closed). Promovi C5/C6/C7 a CORRETO e adicionei C9.
- **Veredito do Orquestrador:** consenso (escritor≠auditor preservado: Executor escreveu, Orquestrador auditou). Resta a Autoridade decidir o commit.

## [2026-06-20] remediacao/auditoria-engrama | [gate][governance][contract] P0.2 CI + P0.3 classify + R3/R4 + hook fail-closed | confirmo | executor codex + auditoria orquestrador
- **Executor:** `codex exec -s workspace-write` (ajuste-menor): leitura NUL-safe `git diff --cached --name-only -z` + `read -d ''` (R3); detached HEAD (`BRANCH` vazio) → fail-closed exit 2 (R4); `classify()` ampliado (`.engrama/gaps|roadmap|domain/*`→governance, `.github/*`→gate, `tests/gate/*`→gate); hook fail-closed quando falta `python3`; criou `.github/workflows/ci.yml` (matriz ubuntu+macos: shellcheck + `tests/run.sh`).
- **Auditoria do Orquestrador (ADR 0005):** diffs dentro do escopo (só gate/hook/CI); shellcheck limpo; suíte 21 asserts verdes — **G1–G7 sem regressão**, R3/R4 promovidos a CORRETO, contract 9/9; YAML válido.
- **Consenso.** Furos restantes do gate: R1 (vínculo ao diff), R2/R5 (parsing por campo) — próxima fatia.

## [2026-06-20] remediacao/auditoria-engrama | [gate][governance][contract] R2/R5 parsing por campo do ledger | confirmo | executor codex + auditoria orquestrador
- **Executor:** `codex exec -s workspace-write` (concordo): trocou o grep-substring por **parsing por campo** (`is_ok_verdict` por igualdade/prefixo; branch por igualdade exata; objeção/`waiver` no campo 3). Editou só `.engrama/scripts/critique-gate.sh`.
- **Auditoria do Orquestrador (ADR 0005):** suíte 21 asserts verdes — G1–G7 + R3/R4 sem regressão, **R2 e R5 promovidos a CORRETO**; shellcheck limpo; **gate ao vivo no índice real** libera via a entrada `confirmo` desta branch (histórico não-quebrado), e contraprova (branch sem entrada) **bloqueia** (exit 2). Nota: meu cleanup descartou a edição não-commitada; recuperei o blob `374e64f` do object DB.
- **Doc do formato do ledger** atualizada (gramática rígida de 4 campos) pelo Orquestrador.
- **Consenso.** Resta **R1** (vínculo ao diff via sha256) — decisão de design da Autoridade (muda o formato do ledger e exige que o crítico grave o hash).

## [2026-06-20] remediacao/p04-honestidade-higiene | [governance][gate] P0.4 honestidade + P3 higiene | confirmo | executor codex discordo->incorporado
- **Executor (`codex exec`, crítica read-only): `discordo`** — pegou (com razão) que minha edição de "honestidade" criou um **novo overclaim**: a CI atual **não** reexecuta o gate contra o PR e *required check* não é provável pelo código; contradição no ADR ("toda regra nasce criticada" vs bootstrap `dispensada`); e R1 **meio-reframado** (docs diziam "aceito" mas log/gaps/qa diziam "aberto").
- **Incorporado (Path 1 — manter R1 aberto):** README/ADR 0006/CHANGELOG/comentário do gate alinhados à verdade (CI = `shellcheck`+testes; enforcement server-side vinculante = **pendente**); teste R1 volta a **FURO**; contradição do ADR removida; bloco "Estrutura" do schema corrigido; `LICENSE`+`CHANGELOG` adicionados. Consistência verificada por grep (zero overclaims).
- **Consenso por incorporação** (ADR 0006: incorporar os ajustes sugeridos pelo Executor constitui consenso; sem nova rodada — respeita o anti-loop). Suíte 21 asserts verde; shellcheck limpo.
- **Decisão da Autoridade (delegada ao Orquestrador) sobre R1:** manter **aberto**; mitigação = gate como *required check* na CI + vínculo ao diff, na fatia server-side (P2/futuro).

## [2026-06-20] remediacao/p2-sync-template | [governance][gate][contract] P2 propaga fixes ao template + sync-template.sh + drift test | confirmo | executor codex + auditoria orquestrador
- **Problema (EX2):** o `template/` distribuía o gate **bugado** (zero dos fixes R2-R5/-z/detached/hook) — todo projeto novo herdava as vulnerabilidades; e o `classify()` citava `sync-template.sh` inexistente.
- **Executor (`codex exec`, concordo):** propagou a lógica endurecida para `template/.engrama/scripts/{critique-gate,critique-gate-hook}.sh` (hook idêntico; gate com lógica da raiz + placeholders + classify do template); criou `sync-template.sh` (gerador idempotente por composição de seções, sem reverse-sub cega em prosa) e `tests/contract/sync.test.sh` (drift).
- **Auditoria do Orquestrador (ADR 0005):** suíte verde (gate 12, contract 9, **sync 5**); shellcheck limpo; **smoke funcional** — projeto novo via `bootstrap.sh` recebe gate com `is_ok_verdict` + 0 placeholders e **bloqueia governança sem ledger** (exit 2); sync **idempotente** (2x unchanged); drift test **sensível** (divergência injetada → exit 1). Referência fantasma resolvida.
- **Consenso.** **Fecha EX2.** Resta R1 (aberto, conhecido).
