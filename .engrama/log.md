# Log — Memória factual append-only

Mais recente no topo. Cabeçalho: `## [YYYY-MM-DD] {tipo} | título`. Logar **antes** de cada commit não-trivial. O item mais recente no topo **é** o checkpoint vivo (estado de retomada) — ver [[governance/continuidade-de-sessao]].

Tipos comuns: `decision` · `ingest` · `update` · `slice` · `fix` · `chore` · `audit` · `phase`.
Permite `grep "^## \[" log.md | tail -N` para varrer o histórico.

---

## [2026-06-21] feat | PR-D — atritos do adotante no bootstrap (P1 da auditoria de prontidao)
- Branch `feat/p1-atritos-do-adotante`. Executor via `exec-bridge.sh` (codex-session 019eeca7, veredito `ajuste-menor`). Orquestrador auditou + reexecutou + smoke proprio em /tmp.
- **Origem:** auditoria multiagente de prontidao de bootstrap (72 agentes, 0 bloqueadores, ready-with-caveats). Esta fatia fecha o P1 (atritos que confundem o adotante).
- **Freio ativo do Executor (ADR 0004) consertou minha ordem:** propus auto-semear `dispensada` no ledger do projeto novo por `branch+categoria`. O Executor objetou — isso abriria QUALQUER commit futuro de governance/gate naquela branch (regressao do gate). Ajuste aceito: a dispensa do bootstrap sai **vinculada por `sha256`** ao diff staged do instalador; cobre so o snapshot inicial; editar algo sensivel antes do 1o commit re-bloqueia. Compativel com ADR 0006 (escopo minimo, rotulada como dispensa-da-Autoridade-via-instalador).
- **Item 1 (classify imperativo):** comentario do `classify()` (raiz + gerador do template no sync) agora diz que mapear superficie sensivel do dominio e OBRIGATORIO antes do 1o commit de dominio; o que nao entra no `case` passa SEM revisao. INSTALL/INSTANTIATE Passo 3 viram verificacao obrigatoria com exemplos por stack.
- **Item 2 (auto-teste falso-verde):** INSTALL Passo 6 / INSTANTIATE Passo 4 — o self-test agora roda em branch descartavel deterministica (a entrada do bootstrap na main cobriria governance e dava falso-verde).
- **Item 3 (deadlock galinha-e-ovo):** `bin/bootstrap.sh` semeia a dispensa vinculada por sha256 + aviso PROEMINENTE no stdout; documentado no INSTALL Passo 5. Provado: 1o commit do alvo passa sem intervencao manual; 2a mudanca sensivel re-bloqueia.
- **Item 4 (dica repo-fresco):** o bloqueio do gate ganha dica quando o ledger esta vazio/stub.
- **Eu (git):** `chmod +x` no hook versionado do template (era 100644 -> git pulava o pre-commit em clone fresco; agora 100755).
- **QA (ADR 0005):** suite verde (+G2B/C12/C13 novos); lint/shellcheck/sync exit 0; smoke proprio em /tmp confirmou o binding da dispensa. Ledger com sha256 + codex-session.

## [2026-06-21] feat | PR-C — quickstart + diff-binding multi-commit acionavel + gitleaks sem Node
- Branch `feat/quickstart-diffbind-gitleaks`. Executor via `exec-bridge.sh` (codex-session 019eeb2e, veredito `concordo`). Orquestrador auditou e reexecutou os gates.
- **Transparencia provada de ponta a ponta:** o wrapper consertado no PR-B capturou o **corpo completo** da resposta do Executor desta run (nao so o session-id). A correcao saiu da teoria.
- **Item 5 (quickstart):** `## Quickstart (TL;DR)` no topo do README — atalho honesto de *adocao* do template (cp `template/.` -> raiz; lint), nao "subir um app". O Executor pegou um overclaim proprio (prometia `tests/run.sh`, que `template/` nao entrega) e cortou.
- **Item 6 (diff-binding multi-commit):** caveat virou **acionavel** — `::notice::` nao-bloqueante na CI quando o PR tem >1 commit + recomendacao explicita de squash no `CONTRIBUTING.md`. A logica do gate nao foi tocada.
- **Item 7 (gitleaks sem Node):** troquei `gitleaks/gitleaks-action@v2` por binario **fixado (v8.30.1) + verificado por checksum** e scan sem `GITHUB_TOKEN` — mata o warning de deprecacao do Node 20. Release/asset confirmados em fonte primaria (gh api) antes de fixar.
- **QA (ADR 0005):** suite verde; lint exit 0; shellcheck exit 0; `ci.yml` YAML valido. Download do gitleaks so roda na CI (nao exercitavel local) — sera provado pelo required-check.
- Encerra a lista de pendencias triviais (itens 5-7). Atestacao dogfoodada: ledger leva `sha256` + `codex-session`.

## [2026-06-21] feat | PR-B — teste do hook + lint completo + FIX do wrapper (resposta nao capturada)
- Branch `feat/hook-test-lint-completo`. Executor invocado **via `exec-bridge.sh`** (codex-session 019eeb13). Orquestrador auditou.
- **Item 2:** `tests/gate/hook.test.sh` (6 casos: git commit, --no-verify, status, ls, sem python3 fail-closed, JSON malformado).
- **Item 4:** lint estendido — paginas orfas, gaps de numeracao de ADR, status invalido, TODO/FIXME/XXX em doc normativo. Sensibilidade provada; o Executor achou+corrigiu um TODO real em continuidade-de-sessao.
- **Licao (loop falha->regra) da PROPRIA transparencia:** o `exec-bridge.sh` (PR-A) capturava o session-id mas **NAO o corpo da resposta** (o output_text final do assistant nao vem no stream --json, so no session file). Recuperei a resposta desta run do session file; **corrigi o wrapper** (fallback que extrai do `~/.codex/sessions/<id>.jsonl`); adicionei o caso **E7** que pega a regressao (provado: falha sem o fix). O stub do teste antigo nao replicava o formato real -> por isso o bug passou.
- Suite 282 asserts verde; shellcheck/lint/markdownlint limpos. Transcripts desta run versionados.
- **PROXIMO:** PR-C (quickstart + diff-binding multi-commit + node gitleaks).

## [2026-06-21] feat | PR-A — transparencia do executor-bridge (ADR 0003 mecanizado) + session-id
- Branch `feat/transparencia-executor-bridge`. Executor (`codex exec`, ajuste-menor); Orquestrador auditou (test stub, smoke, markdownlint).
- **Transparencia (item 1):** `.engrama/scripts/exec-bridge.sh` invoca o codex e SALVA ordem+resposta+`codex-session` em `transcripts/` (versionado, publico — decisao da Autoridade). Captura o session-id real de `~/.codex/sessions/*.jsonl` (fallback `derived`). Os ~33 transcripts DESTA sessao foram preservados de `/tmp` em `transcripts/sessao-01-.../`.
- **Atestacao (item 3):** o ledger (campo 4) aceita `codex-session:<id>` como evidencia fraca de execucao real (NAO prova identidade — teto do R1). ADR 0003/0011 atualizados.
- **Licao (loop falha->regra):** minha ORDEM pos o wrapper em `bin/` (que e source-only pela reorg); o Executor seguiu e distribuiu via `template/bin/`, quebrando o "`.engrama/` autocontido". Corrigi: movido p/ `.engrama/scripts/` (com o gate/hook/lint/diff-hash) — `bin/` volta a ser so source-only. `transcripts/` excluido do markdownlint (evidencia, nao doc autoral).
- Suite 267 asserts verde (exec-bridge.test 6); shellcheck/lint/markdownlint limpos.
- **PROXIMO:** PR-B (teste do hook + lint completo) e PR-C (quickstart + multi-commit + node), agora invocando o Executor VIA exec-bridge (dogfood da transparencia).

## [2026-06-21] feat | PR4 — versionamento 0.1.0 + vendor/model-names honestos (EX4 parte 2)
- Branch `feat/versionamento-vendor`. Executor (`codex exec`, concordo); Orquestrador auditou (smoke com VERSION, vendor honesto, suite verde).
- **Versionamento (item 8):** `VERSION`=0.1.0 (fonte de verdade); `bin/bootstrap.sh` semeia `ENGRAMA_VERSION`; `template/.engrama/VERSION`={{ENGRAMA_VERSION}} -> projeto-alvo registra a versao instalada; teste C10 prova. CHANGELOG cortado em release `[0.1.0] - 2026-06-21`.
- **Vendor honesto (item 7):** ids de modelo `gpt-5.x` relabelados de "PADRAO" para "EXEMPLO/confirme no seu codex exec" (nao verificados); nova secao "Camada de adaptadores de vendor" em papeis-e-alcadas (EXECUTOR_CMD/modelos/.claude sao adaptador trocavel; nucleo vendor-agnostico).
- **PROXIMO:** apos o merge, criar a tag git `v0.1.0`. Com isso TODAS as pendencias levantadas estao fechadas.

## [2026-06-21] fix | PR3 — EX4(parte 1): source_refs absolutos -> relativos (portabilidade)
- Branch `fix/source-refs-relativos`. Executor (`codex exec`, ajuste-menor); Orquestrador auditou (zero absolutos, portabilidade por clone, smoke com refs relativos).
- Migrou os `source_refs` de TODOS os `.engrama/**/*.md` (raiz: `/Users/...`-><X>; template: `{{REPO_PATH}}/`-><X>) para **relativos à raiz**; corrigiu 3 paths fora de source_refs (`SOURCE_OF_TRUTH_REPO: .`, regra/exemplo do schema, prosa do infra-runbook); `lint.sh` valida relativo (compat com absoluto legado).
- **Prova:** `grep /Users` e `{{REPO_PATH}}/` em `.engrama/**.md` = vazio; lint exit 0 no repo e em clone p/ outro path; suite verde; smoke (bootstrap) -> projeto-alvo com source_refs relativos, lint exit 0.
- **PROXIMO:** PR4 (EX4 parte 2: vendor/model-names honestos + {{ENGRAMA_VERSION}}/release).

## [2026-06-21] fix | PR2 — diff-binding: fingerprint unificado (local==CI) + modo estrito RELIGADO
- Branch `fix/diffbind-fingerprint`. Executor (`codex exec`, ajuste-menor); Orquestrador auditou (igualdade --cached==--range provada do zero, inclusive com rename; estrito ponta-a-ponta).
- **Bug do item 4 fechado:** `engrama-diff-hash.sh` ganhou `--range <gitrange>`; o `bin/critique-gate-ci.sh` computa o fingerprint sobre o **diff REAL do PR** (`--range base...HEAD`) e injeta no gate via `ENGRAMA_DIFF_HASH`; o gate respeita esse override. Local (`--cached`) e CI (`--range`) agora produzem o MESMO hash.
- **`ENGRAMA_REQUIRE_DIFF_BIND=1` RELIGADO no CI.** ADR 0011/template + ledger-doc + README/SECURITY/CHANGELOG/gaps atualizados ("Corrigido"). Borda honesta: PR multi-commit liga ao diff cumulativo `base...HEAD`; fluxo recomendado = squash.
- Suíte verde (diffbind 9, ci 4, +todas); shellcheck/lint limpos. **Esta entrada usa o caminho forte** (sha256 vinculado).
- **PROXIMO:** PR3 (source_refs portaveis/EX4), PR4 (vendor/model-names + {{ENGRAMA_VERSION}}).

## [2026-06-21] docs | PR1 — honestidade: required check ATIVO + estrito off; higiene de docs
- Repo **publicado como PUBLIC** em github.com/x86dx2/engrama (a entrada de criacao registrou 'private'; tornei publico com autorizacao da Autoridade — registrado aqui para a memoria nao ficar stale). **Branch protection ATIVA**: required checks (job `test` que embute o gate-contra-PR, + markdown, gitleaks) → enforcement vinculante no merge. **GHSA private vulnerability reporting habilitado**.
- README/ADR 0006/CHANGELOG/gaps: reconciliados (required check ATIVO, nao "pendente"); ressalva do **modo estrito do diff-binding desligado** (bug de fingerprint). ADR 0007/0010 marcados dormentes; tetos (R1/EX4/diff-binding) consolidados no gaps. template ADR 0011 ganhou a limitacao conhecida.
- SECURITY.md corrigido (canal GHSA real; `.env` agora gitignored de fato + negado no harness). `.gitignore` += `.env`/`.env.*`.
- **Executor (codex) criticou (ajuste-menor): incorporado** — pegou 2 overclaims novos no SECURITY.md (.env nao-gitignored; GHSA) e o stale no gaps. lint/markdownlint/suite verdes.
- **PROXIMO:** PR2 (fix do fingerprint do diff-binding + religar estrito), PR3 (source_refs portaveis/EX4), PR4 (vendor/model-names + {{ENGRAMA_VERSION}}).

## [2026-06-21] reorg | Estrutura reorganizada (padrao ai-memory/Akita) — root limpo
- Branch `reorg/estrutura-akita` (via PR — branch protection ativa). Executor (`codex exec`) moveu; Orquestrador auditou (root limpo, suite 250 verde, smoke de install independente passou).
- **Root** agora so metadados/manifests. **`bin/`**: install/bootstrap/sync-template/critique-gate-ci. **`docs/`**: INSTALL/INSTANTIATE. **`.engrama/scripts/`**: gate+hook+session-context+lint+engrama-diff-hash (autocontido e distribuivel).
- Cascata inteira atualizada (classify, CI, refs cruzadas, root-detection do lint, ~7 suites, README/schema/docs). +CONTRIBUTING +SECURITY.
- **PROXIMO PASSO SEGURO:** abrir PR; CI verde (gate-contra-PR + tests) -> merge. Push direto na main esta bloqueado (correto).

## [2026-06-21] fix | CI verde no GitHub — lint portavel (licao EX4) + markdownlint tolerante
- Repo publicado (privado) em github.com/x86dx2/engrama; 1o CI falhou -> consertado nesta fatia (loop falha->regra).
- **lint.sh portavel:** source_refs resolvidos relativo a raiz do repo (antes: caminhos absolutos /Users/... quebravam em /home/runner/...). Caso L8 (clone p/ outro path) trava a regressao.
- **markdownlint:** config renomeado p/ `.markdownlint-cli2.yaml` + tolerante ao estilo da casa e aos wikilinks (MD052 falso-positivo). Rodado o tool REAL: 0 erros em 67 arquivos.
- gitleaks ja passava. shellcheck/lint/suite verdes (249 asserts).
- **PROXIMO:** branch protection na main esta BLOQUEADA pelo plano (privado em conta free exige GitHub Pro) -> reportar opcoes a Autoridade.

## [2026-06-20] feat | T3 (absorcao walrus) — diff-binding: atestacao verificavel (mitiga R1)
- Branch `absorcao/t3-atestacao`. Executor (`codex exec`, ajuste-menor); Orquestrador auditou (backward-compat + 5 casos do zero + honestidade do ADR).
- **diff-binding:** o ledger pode carregar `sha256:<hex>` (via `engrama-diff-hash.sh`, fingerprint estavel do `git diff --cached --raw` excluindo o ledger). Hash bate -> libera; arquivo editado apos a critica -> BLOQUEIA (vinculo obsoleto); modo estrito `ENGRAMA_REQUIRE_DIFF_BIND=1` (CI) exige o hash. Entradas sem hash = legado (backward-compat: G1-G7/R2-R5/fuzz intactas).
- **ADR 0011** (honesto): prova cobertura DESTE diff; NAO prova independencia de identidade do critico (assinatura/chave = teto, codex nao expoe). CI estrita reexecuta o gate contra o diff real do PR.
- **R1 mitigado** (nao eliminado): o caminho forte + CI estrita fecham "1 confirmo libera a branch toda" e "confirmo velho vale diff novo"; o legado local segue cooperativo (documentado).
- Suite 249 asserts verde; shellcheck/lint limpos.
- **Este commit dogfooda o diff-binding:** entrada de ledger vinculada por sha256.

## [2026-06-20] feat | T2c (absorcao headroom) — loop falha->regra + principio 12 (metricas honestas)
- Branch `absorcao/t2c-governanca`. Orquestrador autorou; Executor (`codex exec`) criticou (`ajuste-menor`, 4 achados) -> incorporados.
- **Principio 12** (honestidade de claims/metricas) em modelo-operacional + spec **licao-aprendida** (toda falha relevante vira regra duravel: gate/lint/teste/ADR). Propagado ao template.
- **Ironia incorporada:** o Executor pegou meu doc de honestidade caindo no proprio overclaim ("vira"/"impede") -> suavizado para o verificavel. Virou exemplo vivo na propria spec.
- Tambem fechei 2 drifts de prosa raiz<->template (Estrutura do schema em ambos agora bate com a arvore real).
- lint limpo; suite verde (gate 12 + fuzz 200 + contract 9 + lint 7 + session 3 + sync 8 + ci 4).
- **PROXIMO:** T3 (atestacao verificavel do R1: diff-binding + artefato de critica + doc honesta do limite).

## [2026-06-20] feat | T2a (absorcao ai-memory) — auto-surface do checkpoint por hooks
- Branch `absorcao/t2a-hooks`. Executor (`codex exec`, concordo); Orquestrador auditou (degradacao segura, settings valido, suite verde).
- **session-context.sh** + hooks `SessionStart`/`PreCompact`: ao abrir/compactar a sessao, auto-surge o checkpoint (topo do log), status do bootstrap e lembrete do handshake — reduz a cerimonia manual de "ler o topo do log".
- **Honesto:** auto-surface + lembrete, NAO auto-write. Atualizar log/ledger continua exigindo julgamento.
- Suite 243 asserts verde; shellcheck limpo; PreToolUse do gate preservado.
- **PROXIMO:** T2c (loop falha->regra) + metricas honestas, depois T3 (atestacao verificavel do R1).

## [2026-06-20] feat | T1 (absorcao ai-memory/walrus) — lint.sh + fuzz do parser + CI de qualidade
- Branch `absorcao/t1-lint-fuzz-ci`. Executor (`codex exec`, ajuste-menor) escreveu; Orquestrador auditou (lint sensivel, fuzz deterministico/oracle, suite verde).
- **lint.sh**: entrega o workflow "Lint" que o schema prometia mas nao implementava (wikilinks orfaos, source_refs quebrados, frontmatter, ADR superseded). Ja pegou 2 wikilinks reais. Propagado ao template.
- **fuzz.test.sh**: 200 cenarios pseudo-aleatorios deterministicos com oracle independente — property test do parser do gate (absorcao walrus/simulation).
- **CI**: + `bash lint.sh`, **gitleaks** (secret scan) e **markdownlint** (absorcao ai-memory/walrus).
- Suite: 238 asserts verdes (gate 12 + fuzz 200 + lint 7 + sync 6 + contract 9 + ci 4); shellcheck limpo.
- **PROXIMO:** T2 (auto-captura por hooks + loop falha->regra) e T3 (atestacao verificavel do R1).

## [2026-06-20] fix | P2b — CI reexecuta o gate contra o PR (mitiga R1) + honestidade alinhada
- Branch `remediacao/p2b-ci-gate`. Executor (`codex exec`, ajuste-menor) criou `critique-gate-ci.sh` (wrapper que monta um repo sintético na branch do PR e reusa o gate local — mesma `classify()` + parsing por campo, zero duplicação); `tests/gate/ci.test.sh` (4 casos); e o step de CI em `pull_request`.
- **R1 mitigado server-side:** o controle passa a rodar num lugar não-burlável pelo autor. Falta só marcar o check como *required* no branch protection (config de repo) para bloquear o merge.
- **Docs alinhadas** (incorporando o caveat do próprio Executor): README/ADR 0006/comentário do gate deixam de dizer "pendente" e descrevem o estado real (CI roda o gate; required-check é o passo de config que falta). Gate re-sincronizado ao template.
- Auditoria do Orquestrador: suíte 30 asserts verde (gate 12 · contract 9 · sync 5 · ci 4); shellcheck limpo; teste independente do modo-CI (bloqueia sem ledger, libera com `confirmo`, parsing por campo preservado); gate local intacto.
- **ROADMAP CONCLUÍDO:** P0.1–P0.4, P2, P2b, P3 entregues; 7/8 furos fechados; R1 mitigado server-side (pendente só o required-check de repo). Ver [[gaps/auditoria-e-plano-de-remediacao]] (STATUS FINAL).
- **PRÓXIMO PASSO SEGURO:** Autoridade marca o check da CI como *required* no GitHub (fora do código); nada mais pendente no repo.

## [2026-06-20] fix | P2 — propaga fixes do gate ao template + sync-template.sh + drift test (fecha EX2)
- Branch `remediacao/p2-sync-template`. Executor (`codex exec`, concordo) escreveu; Orquestrador auditou (smoke funcional + idempotência + sensibilidade do drift test).
- **Bug fechado (EX2):** o `template/` distribuía o gate **vulnerável** (sem R2-R5/-z/detached/hook fail-closed) — projeto novo herdava os furos. Agora o template carrega o gate endurecido (lógica da raiz + placeholders + classify de domínio).
- **`sync-template.sh`** (gerador idempotente, composição por seções) resolve a referência fantasma; **`tests/contract/sync.test.sh`** trava o drift (provado sensível) e roda na CI.
- **Smoke:** `bootstrap.sh /tmp/novo` → gate instalado tem `is_ok_verdict`, 0 placeholders, e bloqueia governança sem ledger.
- **Roadmap:** P0.1–P0.4, P2, P3 entregues; **7/8 furos** fechados. Resta só **R1** (aberto, consciente) + a fatia server-side opcional (gate como required check na CI).
- **PRÓXIMO PASSO SEGURO:** decisão da Autoridade sobre o commit/merge; opcional: P2b (step de CI rodando o gate contra o PR, que mitiga R1 de verdade).

## [2026-06-20] docs | P0.4 honestidade + P3 higiene (claims alinhados à verdade)
- Branch `remediacao/p04-honestidade-higiene`. Orquestrador autorou; Executor (`codex exec`) criticou (`discordo`) e os ajustes foram **incorporados** (Path 1).
- **Honestidade:** README/ADR 0006/comentário do gate deixam claro que o hook é **freio cooperativo local** (burlável); o enforcement vinculante (gate como *required check* server-side) é **pendente** — a CI atual só roda `shellcheck`+testes. Bootstrap chicken-and-egg explicitado.
- **R1 mantido ABERTO** (não "aceito"): coerência entre README/ADR/CHANGELOG/teste/log/gaps/qa restaurada (o Executor pegou meu reframe parcial).
- **Higiene:** `LICENSE` (MIT, confirmar titularidade), `CHANGELOG.md`, e correção do bloco "Estrutura" do schema (`.engrama/CLAUDE.md`).
- **PRÓXIMO PASSO SEGURO:** decisão da Autoridade sobre o commit; depois **P2** (`sync-template.sh` raiz→template + step de CI que reexecuta o gate contra o PR — fecha parte do R1) e injeção de `{{ENGRAMA_VERSION}}`.

## [2026-06-20] fix | R2/R5 — parsing por campo do ledger (gate deixa de usar grep-substring)
- Branch `remediacao/auditoria-engrama`. Executor (`codex exec`, concordo) trocou o matching por **parsing por campo**; Orquestrador auditou (21 asserts verdes; gate ao vivo no índice real validado; contraprova bloqueia).
- **R2 fechado** (`nao confirmo` não casa mais `confirmo` — veredito por enum no campo 3) e **R5 fechado** (branch por igualdade exata de campo, não substring na linha).
- Doc do formato do ledger atualizada (gramática rígida de 4 campos). Registrado em [[qa/criticas-do-executor]].
- **4 de 5 furos do gate corrigidos** (R2/R3/R4/R5). Resta **R1** (auto-aprovação / vínculo ao diff) — decisão de design.
- **PRÓXIMO PASSO SEGURO:** decisão da Autoridade sobre (a) o commit desta fatia e (b) o design de R1 (sha256 do diff no ledger + caveat de independência server-side). Depois: P2 (sync-template raiz↔template) e P3 (LICENSE/CHANGELOG/docs).

## [2026-06-20] fix | P0.2/P0.3 + R3/R4 + hook — endurecimento do gate + CI (executor-bridge)
- Branch `remediacao/auditoria-engrama`. Executor (`codex exec`) escreveu; Orquestrador auditou (21 asserts verdes, G1–G7 sem regressão).
- **CI** `.github/workflows/ci.yml` (matriz ubuntu+macos: shellcheck + `tests/run.sh`) — a primeira camada de enforcement não-burlável.
- **Gate endurecido:** R3 (non-ASCII via `-z` stream) e R4 (detached HEAD fail-closed) **corrigidos e promovidos**; `classify()` agora cobre `tests/gate/`, `.github/`, `.engrama/gaps|roadmap|domain/`; hook fail-closed sem `python3`.
- Registrado em [[qa/criticas-do-executor]]. Furos restantes: **R1** (vínculo ao diff), **R2/R5** (parsing por campo) — próxima fatia.
- **PRÓXIMO PASSO SEGURO:** decisão da Autoridade sobre o commit; depois a fatia final do gate (R2/R5 parsing por campo + R1 vínculo ao diff) e P2 (fonte única raiz↔template / `sync-template.sh`).

## [2026-06-20] fix | P0.1 — instalador: substituição literal segura + fail-closed (executor-bridge)
- Branch `fix/p0-instalador-substituicao-segura`. Executor (`codex exec`) corrigiu `install.sh`; Orquestrador auditou.
- **Bug fechado (era CRÍTICO):** valor com `#` quebrava o `sed -f` global (instalação 100% crua com exit 0); `&` corrompia. Agora: escape literal (`\`,`&`,`#`) + `find -print0`/`read -d ''` + **fail-closed** (aborta exit 1 se sobrar placeholder).
- **Provado:** `tests/contract` 9/9 verde (C5/C6/C7 promovidos a CORRETO; +C9 adversário); shellcheck limpo; teste manual com todos os especiais juntos + values incompleto.
- Crítica/execução do Executor registrada em [[qa/criticas-do-executor]]. Furos restantes (R1–R5, do gate) seguem para P1/P2.
- **PRÓXIMO PASSO SEGURO:** decisão da Autoridade sobre o commit desta branch; depois P0.2 (CI) + P0.3 (cabear `tests/`+`gaps/` no classify) e P1 (endurecer o gate).

## [2026-06-20] audit | Auditoria imparcial + plano de remediação + suítes de teste (dogfood do gate)
- Auditoria de 3 fontes (leitura, workflow 47 agentes, `codex`) **validada por testes**: `tests/gate/` (12 asserts, G1–G7+R1–R5) e `tests/contract/` (8 asserts, C1–C8) + `tests/run.sh`. shellcheck-limpas, fail-fast.
- **Provado correto:** G1–G7, C1–C4, C8 (inclui leitura staged do ledger e bootstrap.sh end-to-end).
- **Furos comprovados (8):** R1 auto-aprovação · R2 substring · R3 non-ASCII fail-open · R4 detached HEAD · R5 bypass cross-branch · C5 `&` corrompe · C6/C7 `#` quebra global + exit 0.
- **Executor-bridge real:** `codex exec` criticou o plano (veredito `discordo`, 13 pontos) → ajustes **incorporados**; registrado em [[qa/criticas-do-executor]]. Plano em [[gaps/auditoria-e-plano-de-remediacao]].
- **Gate ao vivo:** liberou o commit montado na linha `dispensada` do bootstrap (furo R1/EX5 demonstrado no repo real).
- **PRÓXIMO PASSO SEGURO:** decisão da Autoridade sobre o commit (governança não se autoaprova; Executor `discordo` incorporado, sem dispensa registrada). Depois: P0 do plano (corrigir instalador `#`/`&`, CI, cabear `tests/`+`gaps/` no classify, alinhar claims).

## [2026-06-20] decision | Engrama ativado como instância viva e template central
- Instalada governança ativa na raiz: `CLAUDE.md`, `AGENTS.md`, `.engrama/` e `.claude/settings.json`.
- `template/` permanece como artefato distribuível para novos projetos, sem estado local deste repositório e sem conteúdo específico do Ruflos.
- Bootstrap do projeto central concluído em [[project/bootstrap-do-projeto]]; Ruflos foi usado como base operacional, não como conteúdo de domínio.
- Gate central mapeado para `[governance]`, `[gate]` e `[contract]`; superfícies como `financial`, `rbac`, `auth` e `schema` ficam para projetos-alvo.
- Crítica do Executor: dispensada pela Autoridade somente para este bootstrap inicial; próximas mudanças sensíveis exigem crítica independente ou waiver explícito.
- **PRÓXIMO PASSO SEGURO:** validar `shellcheck bootstrap.sh install.sh`, executar smoke de bootstrap limpo e commitar a ativação central.
