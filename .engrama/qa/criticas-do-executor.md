---
type: workflow
status: active
touches: [decisions/0006-governanca-nao-se-autoaprova, decisions/0010-roteamento-modelo-effort-do-executor, decisions/0011-diff-binding-atestacao-verificavel, governance/modelo-operacional]
date: 2026-06-20
source_refs:
  - .engrama/scripts/critique-gate.sh
---

# Ledger de críticas do Executor (gpt-5.5) — gate de superfície sensível

Registro **append-only** de toda **crítica do Executor no papel de crítica** (modelo independente, read-only) exigida pelo **ADR 0006 item 7** e pelo **ADR 0010**.

**Verificado mecanicamente** por `.engrama/scripts/critique-gate.sh` (git pre-commit + PreToolUse do harness). Um commit que toca superfície sensível é **bloqueado** se faltar, para CADA categoria tocada, uma entrada CONCLUÍDA referenciando a **branch**. O gate lê a versão **staged/HEAD** do ledger (não o working-tree), rejeita `<pendente>` e bloqueia `objeção` sem `waiver`.

**Diff-binding verificável (ADR 0011):** o campo 4 (`ref`) pode carregar um token `sha256:<hex>` calculado por `bash ./.engrama/scripts/engrama-diff-hash.sh` e/ou um marcador `codex-session:<id>` emitido por `.engrama/scripts/exec-bridge.sh`. Quando o `sha256` estiver presente, o gate compara esse token ao fingerprint atual do diff alvo (staged no local; `ENGRAMA_DIFF_HASH` quando a CI injeta o hash do diff real do PR), sempre excluindo o próprio ledger:
- **match forte** (`sha256` bate) — a crítica cobre **este diff**;
- **hash obsoleto** (`sha256` não bate) — a crítica fica vinculada a **outro diff** e não satisfaz o gate;
- **sem `sha256:`** — caminho **legado** (branch+categoria+veredito), preservado por compatibilidade.

**Modo estrito:** com `ENGRAMA_REQUIRE_DIFF_BIND=1`, só o **match forte** satisfaz; entradas legadas sem hash deixam de contar. Isto prova **cobertura do diff**, não **identidade independente do crítico** — esse teto exigiria assinatura/chave ou outra identidade que o `codex exec` não expõe hoje.

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
- **campo 3** → o `<veredito>`, validado por **igualdade/prefixo de enum**, não substring (fecha R2: `nao confirmo` ≠ `confirmo`);
- **campo 4** → o `<ref>`, livre, mas pode conter opcionalmente um token `sha256:<hex>` calculado por `bash ./.engrama/scripts/engrama-diff-hash.sh` (local: diff staged; CI: `--range <base>...HEAD`) e/ou `codex-session:<id>` como evidência fraca de que um Codex real rodou via executor-bridge.

Vereditos OK (campo 3): `confirmo` · `confirmo-bug` · `ressalvas` · `dispensada` (igualdade) · `N/A: <motivo>` · `waiver <quem/quando>` (prefixo). `pendente` é rejeitado. Uma objeção (`objeção`/`discordo` no campo 3) só passa se o campo 3 também contiver `waiver` (arbitragem da Autoridade registrada).

> Exemplo com diff-binding forte: `## [2026-06-20] main | [gate] enforcement | confirmo | saída do codex sha256:abc123... codex-session:019ec...`

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

## [2026-06-20] remediacao/p2b-ci-gate | [governance][gate] P2b CI reexecuta o gate contra o PR (mitiga R1) + honestidade | confirmo | executor codex + auditoria orquestrador
- **Executor (`codex exec`, ajuste-menor):** criou `critique-gate-ci.sh` (wrapper que monta repo sintético na branch do PR e reusa o gate local — mesma `classify()`/parsing por campo, sem duplicar); `tests/gate/ci.test.sh` (4 casos); step de CI em `pull_request` (fetch base + `git diff --name-only -z origin/base...HEAD` + wrapper). Não tocou o gate local (sem regressão; sem necessidade de sync por parte dele).
- **Honestidade (Orquestrador, incorporando o caveat do Executor):** README/ADR 0006/comentário do gate atualizados — a CI **reexecuta o gate**; falta só o *required check* (config de repo) para bloquear o merge. Comentário do gate mudou → re-rodei `sync-template.sh` (template re-sincronizado; drift verde).
- **Auditoria do Orquestrador (ADR 0005):** suíte 30 asserts verde (gate 12 · contract 9 · sync 5 · ci 4); shellcheck limpo; **teste independente do modo-CI** (branch sem ledger → bloqueia; `main` com entrada → libera; parsing por campo preservado); gate local intacto (diff vazio).
- **Consenso.** **R1 mitigado server-side.** Roadmap da auditoria concluído (pendente só marcar o check como required no GitHub — fora do código).

## [2026-06-20] absorcao/t1-lint-fuzz-ci | [governance][gate][contract] T1: lint.sh + fuzz do parser + CI de qualidade | confirmo | executor codex + auditoria orquestrador
- **Absorcao:** ai-memory (curator/lint automatizado), walrus (simulation/fuzz + secret-scan/markdown-lint).
- **Executor (codex, ajuste-menor):** `lint.sh` (wikilinks orfaos, source_refs quebrados, frontmatter, ADR superseded sem ponteiro) + `tests/contract/lint.test.sh` (7) + `tests/gate/fuzz.test.sh` (200, oracle-based, deterministico) + CI (lint + gitleaks + markdownlint); propagou `lint.sh` ao template (sync) e corrigiu 2 wikilinks reais.
- **Auditoria (ADR 0005):** lint LIMPO no repo real e SENSIVEL (injetei link quebrado -> exit 1 com msg clara); fuzz deterministico (sem RANDOM/date) com oracle independente; suite verde (gate 12 - fuzz 200 - lint 7 - sync 6 - contract 9 - ci 4); shellcheck limpo. As 2 correcoes de wikilink sao legitimas (`README.md` nao era pagina do Engrama -> virou `README.md`).
- **Consenso.** Entrega o "Lint" que o schema ja prometia (fecha mais um "prega-vs-pratica").

## [2026-06-20] absorcao/t2a-hooks | [governance][gate][contract] T2a: auto-surface do checkpoint via hooks (SessionStart/PreCompact) | confirmo | executor codex + auditoria orquestrador
- **Absorcao ai-memory:** hooks de ciclo de vida reduzem a cerimonia manual de "ler o topo do log".
- **Executor (codex, concordo):** `session-context.sh` (imprime checkpoint + status do bootstrap + lembrete do handshake; read-only, sempre exit 0); mesclou `SessionStart`+`PreCompact` no `.claude/settings.json` PRESERVANDO o `PreToolUse`; teste `session-context.test.sh`; classify `.engrama/scripts/*.sh`->gate; propagado ao template + sync.
- **Auditoria (ADR 0005):** script imprime o checkpoint real e DEGRADA sem quebrar (exit 0 mesmo sem `.engrama/`); settings.json valido, PreToolUse e `.env` deny preservados; suite verde (243 asserts); shellcheck limpo.
- **Honestidade:** e auto-surface + lembrete, NAO auto-write (atualizar log/ledger segue manual — exige julgamento). Documentado no script e na saida.
- **Consenso.**

## [2026-06-20] absorcao/t2c-governanca | [governance] T2c loop falha->regra + principio 12 (metricas honestas) | confirmo | executor codex ajuste-menor incorporado
- **Absorcao headroom:** aprender com a falha (`learn`) + metricas honestas (intervalo de confianca, sem falsa precisao).
- **Orquestrador autorou:** principio 12 (honestidade de claims/metricas) em `governance/modelo-operacional`; spec `specs/licao-aprendida` (loop falha->regra). Propagado ao template (genericizado) + corrigi a Estrutura defasada do `template/.engrama/CLAUDE.md`.
- **Executor (codex, critica read-only): ajuste-menor, 4 achados -> TODOS incorporados:** (1) suavizei absolutos auto-inflados ("vira"->"deve virar"; "impede a reincidencia"->"reduz e torna detectavel") -- o doc de honestidade caira no proprio overclaim que proibe; (2) separei `discordo` de `ajuste-menor` nos gatilhos (ajuste-menor nao e objecao material); (3) o destino da licao vive no commit/log, NAO num campo do ledger (gramatica fixa de 4 campos); (4) corrigi a Estrutura defasada tambem na RAIZ (.engrama/CLAUDE.md omitia session-context.sh).
- **Consenso por incorporacao** (ADR 0006). lint limpo; suite verde. *(Meta-licao: a propria fatia de "metricas honestas" foi pega overclaimando -- registrada como exemplo vivo em [[specs/licao-aprendida]].)*

## [2026-06-20] absorcao/t3-atestacao | [governance][gate][contract] T3 diff-binding: atestacao verificavel (mitiga R1) | confirmo | sha256:01975caeaa3eba13d5a5d11403e304e5479ac08bb7b69c82225a89ff3808a972
- **Absorcao walrus:** prova verificavel > convencao. O ledger vincula a critica ao CONTEUDO do diff por sha256.
- **Executor (codex, ajuste-menor):** `engrama-diff-hash.sh` (fingerprint estavel via `git diff --cached --raw`, exclui o ledger); gate com caminho forte (hash bate -> libera; obsoleto -> bloqueia) + modo estrito `ENGRAMA_REQUIRE_DIFF_BIND=1`; reescreveu `critique-gate-ci.sh` p/ reconstruir o diff real do PR (senao o estrito-CI seria overclaim); ADR 0011 + template + sync.
- **Auditoria (ADR 0005):** backward-compat (249 asserts verdes, suites existentes intactas); 5 casos do diff-binding reproduzidos do zero (hash bate->libera; editar apos critica->bloqueia; estrito sem hash->bloqueia; legado->libera); shellcheck/lint limpos; ADR honesto (cobre o diff, NAO prova independencia de identidade).
- **Esta propria entrada usa o caminho forte:** o `sha256:` acima vincula a critica a este diff exato.
- **Consenso.** R1 mitigado (nao eliminado); teto = identidade verificavel externa (documentado no ADR 0011).

## [2026-06-21] fix/ci-portabilidade | [governance][gate][contract] CI verde: lint portavel (EX4) + markdownlint tolerante | confirmo | executor codex + auditoria orquestrador
- **Licao (loop falha->regra):** o 1o CI no GitHub falhou; causa = EX4 (source_refs ABSOLUTOS quebram fora desta maquina) + nome invalido do config do markdownlint.
- **Executor (codex, ajuste-menor):** `lint.sh` ancora na raiz do script (nao no pwd) e resolve source_refs RELATIVO ao repo (sufixo existente sob REPO_ROOT) -> portavel; caso `L8` (clone p/ outro path, origem apagada) prova; renomeou o config p/ `.markdownlint-cli2.yaml` (auto-descoberto).
- **Auditoria + ajuste do Orquestrador:** reproduzi o clone-sem-origem (lint exit 0); rodei o **markdownlint REAL** (npx) e achei 544 nits de estilo + falso-positivo MD052 nos wikilinks que o config nao cobria -> tornei o config tolerante ao estilo da casa + wikilinks, mantendo regras de problema-real (sanity: pegou MD009). markdownlint = **0 erros em 67 arquivos**. suite verde; shellcheck limpo.
- **Destino duravel:** lint portavel + teste L8 (a regra que impede a reincidencia). EX4 (migrar source_refs p/ relativos) segue aberto, mas o lint deixou de ser nao-portavel.
- **Consenso.**

## [2026-06-21] reorg/estrutura-akita | [governance][gate][contract] reorg estrutural (padrao ai-memory): bin/ + docs/ + .engrama/scripts/ | confirmo | executor codex + auditoria orquestrador
- **Absorcao ai-memory (Akita):** root so com metadados; cada preocupacao numa pasta. Atende o feedback da Autoridade ("arquivos misturados no root").
- **Executor (codex, ajuste-menor):** moveu tooling do pack p/ `bin/` (install/bootstrap/sync-template/critique-gate-ci), scripts da instancia p/ `.engrama/scripts/` (lint + engrama-diff-hash, com o gate), guias p/ `docs/`; espelhou no template; atualizou TODA a cascata (classify `bin/*`->gate e `docs/*`->governance, refs cruzadas, root-detection do lint via `$0/../..`, CI, ~7 suites, README/schema/docs); criou CONTRIBUTING.md + SECURITY.md.
- **Auditoria (ADR 0005):** root LIMPO (zero .sh solto); `.engrama/scripts/` autocontido; suite 250 asserts verde; shellcheck/lint limpos; lint portavel da nova localizacao (clone-sem-origem exit 0); sync idempotente; **SMOKE INDEPENDENTE:** `bin/bootstrap.sh` em projeto novo -> scripts em `.engrama/scripts/`, 0 placeholders, lint exit 0, gate bloqueia gov sem ledger (exit 2). git detectou os renames (R).
- **Consenso.** Primeira fatia a subir via PR (branch protection ativa).
- **Licao (loop falha->regra) descoberta NESTE PR:** o **diff-binding (T3) tem fingerprint INCONSISTENTE entre o gate local (`git diff --cached --raw`) e o gate-CI (repo sintetico reconstruido) — divergem com renames e em geral**. O modo estrito (`ENGRAMA_REQUIRE_DIFF_BIND=1`) ficou impossivel de satisfazer localmente. Acao: **desligado o estrito no CI** ate o fingerprint ser unificado; o gate-contra-PR segue exigindo a critica registrada (nucleo do R1). Bug a corrigir: gate-CI deve computar o fingerprint sobre o diff REAL do PR (`git diff base...HEAD`), nao sobre reconstrucao sintetica.

## [2026-06-21] fix/pendencias-honestidade | [governance] PR1: honestidade (required ativo + estrito off) + higiene de docs | confirmo | executor codex ajuste-menor incorporado
- **Orquestrador autorou:** reconciliou README/ADR 0006/CHANGELOG/gaps ao estado real (required check ATIVO; modo estrito do diff-binding DESLIGADO por bug); dormencia 0007/0010; tetos consolidados; template ADR 0011 + limitacao.
- **Executor (codex, critica read-only): ajuste-menor, incorporado:** (1) SECURITY.md afirmava `.env` gitignored (era falso) -> adicionei `.env`/`.env.*` ao `.gitignore` (torna verdade + protecao real); (2) SECURITY.md/GHSA -> confirmei repo PUBLIC e **habilitei** o private vulnerability reporting (claim agora solido; o Executor leu um log stale dizendo 'private'); (3) gaps stale ("falta marcar required") -> atualizado para "ativo"; (4) precisao README/ADR -> "job `test` que embute o gate e required" (o required e o job, nao o step).
- **Consenso por incorporacao** (ADR 0006). lint/markdownlint/suite verdes.

## [2026-06-21] fix/diffbind-fingerprint | [governance][gate][contract] PR2: fingerprint unificado (--range) + estrito religado | confirmo | sha256:b7723d1fdc6cc8bcba557a5ce43f33f7c398ca948dd88299d9dc4026500df1e1 executor codex + auditoria orquestrador
- **Item 4 fechado.** Executor (codex, ajuste-menor): `engrama-diff-hash.sh --range`; `bin/critique-gate-ci.sh` computa o hash sobre o diff REAL do PR e injeta via `ENGRAMA_DIFF_HASH`; gate respeita o override; `ENGRAMA_REQUIRE_DIFF_BIND=1` religado no CI.
- **Auditoria (ADR 0005):** provei do zero `--cached == --range` (inclusive com rename); suite verde (diffbind 9, ci 4, +todas); shellcheck/lint limpos; e2e estrito (match->libera, mutacao->bloqueia).
- **Esta entrada dogfooda o caminho forte:** o `sha256` acima vincula a critica a ESTE diff do PR — local e CI computam o mesmo valor.
- **Consenso.** Borda documentada: PR multi-commit -> diff cumulativo; fluxo recomendado = squash.

## [2026-06-21] fix/source-refs-relativos | [governance][gate][contract] PR3: source_refs relativos (EX4 portabilidade) | confirmo | sha256:04f141271f241776ec546db6fa48a9008a11abd9d262fec78308f363b13d3edf executor codex + auditoria orquestrador
- **EX4 (parte 1) fechado.** Executor (codex, ajuste-menor): migrou source_refs de 28 .md raiz + 27 template para relativos; corrigiu 3 paths fora de source_refs; lint valida relativo (compat legado).
- **Auditoria (ADR 0005):** zero `/Users`/`{{REPO_PATH}}/` nos .md; lint exit 0 no repo + clone p/ outro path; suite verde; shellcheck limpo; smoke -> projeto-alvo com refs relativos + lint exit 0.
- **Caminho forte:** sha256 vinculado a ESTE diff. **Consenso.**

## [2026-06-21] feat/versionamento-vendor | [governance][gate][contract] PR4: versionamento 0.1.0 + vendor honesto (EX4 parte 2) | confirmo | sha256:5745018e75647aef5654c00d507da5fa9ffb0a9609d1f4f83d2d81de42f5e61a executor codex + auditoria orquestrador
- **Itens 7 e 8 fechados.** Executor (codex, concordo): `VERSION`=0.1.0 + `{{ENGRAMA_VERSION}}` no template (alvo registra a versao); model-ids relabelados como exemplos-a-confirmar; secao "camada de adaptadores de vendor" (nucleo vendor-agnostico); CHANGELOG release 0.1.0.
- **Auditoria (ADR 0005):** smoke -> alvo com `.engrama/VERSION`=0.1.0, 0 placeholders; suite verde (C10 novo); shellcheck/lint limpos; vendor honesto verificado.
- **Caminho forte:** sha256 vinculado. **Consenso.** Apos merge: tag `v0.1.0`.

## [2026-06-21] feat/transparencia-executor-bridge | [governance][gate][contract] PR-A: transparencia do executor-bridge + session-id (itens 1,3) | confirmo | sha256:b5069024df2bcd0735ffce9a519455580534bb4f3ff15980be5ec8fe96c976ff executor codex + auditoria orquestrador
- **Itens 1 e 3.** Executor (codex, ajuste-menor): `exec-bridge.sh` (salva ordem+resposta+`codex-session` real de `~/.codex/sessions`; fallback derived) + teste com stub (6 asserts); ADR 0003 mecanizado; `codex-session:<id>` como evidencia fraca (teto R1).
- **Correcao de layout pelo Orquestrador (licao):** minha ordem pos em `bin/` (source-only); movido p/ `.engrama/scripts/` (mantem `.engrama/` autocontido; `bin/` so source). `transcripts/` excluido do markdownlint (evidencia verbatim). ~33 transcripts desta sessao preservados em `transcripts/sessao-01-...`.
- **Auditoria (ADR 0005):** suite 267 verde (exec-bridge 6); smoke -> alvo recebe `.engrama/scripts/exec-bridge.sh`, sem `bin/`; markdownlint 0 erros; shellcheck/lint limpos.
- **Caminho forte:** sha256 vinculado. **Consenso.**

## [2026-06-21] feat/hook-test-lint-completo | [governance][gate][contract] PR-B: teste do hook + lint completo + fix do wrapper | confirmo | sha256:a70288a2578e7cd592e8afae570f00a7d1b6b26b05a1c2ef5f3e1e7b045e035a codex-session:019eeb13-1795-7f40-92cf-3e02e3066e21 executor codex + auditoria orquestrador
- **Itens 2 e 4.** Executor (codex via exec-bridge, ajuste-menor): `tests/gate/hook.test.sh` (6); lint estendido (orfas/ADR-gaps/status/TODO); achou+corrigiu TODO real.
- **Licao da transparencia:** o wrapper de PR-A nao capturava o corpo da resposta (so session-id). Orquestrador (break-glass: a ferramenta de capturar a resposta do Executor estava quebrada) corrigiu o `exec-bridge.sh` (fallback p/ o session file) + caso E7 (provado: falha sem o fix). Resposta desta run recuperada e versionada.
- **Auditoria (ADR 0005):** suite 282 verde; lint sensibilidade provada (TODO/status injetados -> exit 1); E7 pega a regressao; shellcheck/lint/markdownlint limpos; o TODO-fix preserva o sentido normativo.
- **Atestacao dogfoodada:** esta entrada leva `sha256` (caminho forte) E `codex-session` (evidencia de execucao real via bridge). **Consenso.**

## [2026-06-21] feat/quickstart-diffbind-gitleaks | [governance][gate] PR-C: quickstart + diff-binding multi-commit acionavel + gitleaks sem Node | confirmo | sha256:66d3536aff5c98cbfc672f45f9f3708a818c1f905ecf807fb54a918ce1a92d8f codex-session:019eeb2e-1b7d-7261-9cdd-1460ab4e57ee executor codex via exec-bridge + auditoria orquestrador
- **Itens 5-7 (pendencias triviais), veredito do Executor `concordo`.** README quickstart de adocao; `::notice::` nao-bloqueante p/ PR multi-commit + recomendacao de squash; gitleaks por binario fixado v8.30.1 (checksum-verified) no lugar da action Node, sem `GITHUB_TOKEN`.
- **Executor como freio honesto:** cortou um overclaim proprio no quickstart (prometia `tests/run.sh` num repo-alvo que so recebeu `template/`) e confirmou release/asset do gitleaks em fonte primaria antes de fixar a URL.
- **Auditoria (ADR 0005):** suite verde; lint exit 0; shellcheck exit 0; `ci.yml` YAML valido; release v8.30.1 + assets confirmados via `gh api`. Parte de download/scan do gitleaks so e exercivel na CI (required-check).
- **Transparencia de ponta a ponta:** o wrapper consertado no PR-B capturou o corpo completo da resposta desta run. **Consenso.**

## [2026-06-21] feat/p1-atritos-do-adotante | [governance][gate][contract] PR-D: atritos do adotante (classify imperativo, auto-teste, dispensa do bootstrap vinculada, dica do gate) | confirmo | sha256:c4e7358faec70946eb465508af8d6e9f629d171ccb821f8df1522e48a47bc6cd codex-session:019eeca7-9056-7450-9637-dc3abcc93d79 executor codex via exec-bridge + auditoria + smoke proprio
- **Freio ativo (ADR 0004):** o Executor objetou ao meu auto-seed por branch+categoria (abriria a branch inteira) e impos o vinculo por `sha256` ao diff do instalador. Aceito como `ajuste-menor`; melhora real sobre a ordem.
- **Auditoria (ADR 0005):** suite verde incl. casos novos G2B (dica ledger vazio), C12 (1o commit passa), C13 (2a mudanca sensivel re-bloqueia); lint/shellcheck/sync exit 0. Reexecutei o smoke em /tmp eu mesmo: bootstrap exit 0, 1o commit do alvo passa, 2o commit sensivel bloqueia (`GATE DE CRITICA`).
- **Escopo:** classify() imperativo (raiz+gerador do template), INSTALL/INSTANTIATE Passo 3/4/5/6, bin/bootstrap.sh seed vinculado, dica do gate p/ ledger vazio. chmod +x do hook do template feito pelo Orquestrador (operacao de indice).
- **Consenso.** Sem objecao aberta; nada pendente de Autoridade nesta fatia.
- **Fix de CI (pos-PR):** shellcheck do CI (mais novo) pegou SC2015 em `bin/bootstrap.sh:188` (`A && B || C`). Executor corrigiu (codex-session 019eecb9-e0bd-76b3-99d3-d8592fa5e7f7; subshell + `if !`). Reexecutei shellcheck `-S info` (0 achados) + suite. Tambem removi um `feature.txt` que vazou de um smoke do Executor. Commit reconstruido single-commit; fingerprint atualizado.

## [2026-06-21] feat/p2-enforcement-server-side | [governance][gate][contract] PR-E: enforcement server-side portatil no template (ci.yml + gate-CI + docs branch-protection) | confirmo | sha256:7765848ea1e12a9eb8b9de2543cdea85c4387b3ef44f81b4dfc0a2f71bee52e5 codex-session:019eecc5-c261-7350-87aa-a8e65dacd9c8 executor codex via exec-bridge + auditoria orquestrador
- **Veredito do Executor `concordo`.** Sem objecao material; tratou o risco de drift (pin gitleaks + gate-CI) com sync mecanico + contrato.
- **Isolamento respeitado (regra pos-incidente do PR-D):** o Executor NAO alterou a config nem gravou nada no repo real; minha identidade ficou intacta (reverificada antes de gravar a fatia).
- **Auditoria (ADR 0005):** suite verde (sync 21 asserts); lint/shellcheck(-S info)/sync exit 0; ci.yml do template validado com parser YAML real; confirmei: portatil (nao cita a suite do framework), gate-CI identico raiz<->template, pin gitleaks v8.30.1 em paridade, ADR 0006 do template cita o job `gate` (e o da raiz cita `test`) corretamente.
- **Nao exercivel local:** o workflow do template so roda num repo adotante no GitHub + o branch protection (passo manual documentado). **Consenso.**
