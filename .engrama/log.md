# Log — Memória factual append-only

Mais recente no topo. Cabeçalho: `## [YYYY-MM-DD] {tipo} | título`. Logar **antes** de cada commit não-trivial. O item mais recente no topo **é** o checkpoint vivo (estado de retomada) — ver [[memory/governance/continuidade-de-sessao]].

Tipos comuns: `decision` · `ingest` · `update` · `slice` · `fix` · `chore` · `audit` · `phase`.
Permite `grep "^## \[" log.md | tail -N` para varrer o histórico.

---

## [2026-06-27] decision | PROPOSTA (proposed) — pagina workflow fluxo-operacional (fluxograma do engrama) + governa namespace memory/workflows/
- Branch `feat/workflow-fluxo-operacional`. A Autoridade pediu o fluxograma do engrama "com todos os caminhos" e escolheu versiona-lo como **pagina workflow no .engrama** (passar pelo gate).
- **Conteudo:** `.engrama/memory/workflows/fluxo-operacional.md` (type workflow, `proposed`) com 2 Mermaid inline (fluxo principal + ingestao 2 fases) + legenda + assets (`engrama-fluxo.{mmd,png}`, `engrama-ingest.{mmd,png}`). E **visualizacao** dos normativos (cadeia/modelo/continuidade) — em divergencia prevalece o normativo.
- **Lacuna fechada:** `memory/workflows/` era o UNICO namespace de memoria fora do `classify()`. Governei no runtime (`.engrama/engine/scripts/critique-gate.sh`) E no template via o **gerador** `emit_template_gate_classify()` em `bin/sync-template.sh` (a fonte certa — NAO o arquivo gerado) + re-rodei `bin/sync-template.sh`; `lint.sh` tambem cobre o namespace (frontmatter + orfas), copiado verbatim ao template.
- **Freio ativo (ADR 0004) em acao:** 1a critica = **`discordo` MATERIAL** (gatilho 4, codex-session `019f0a31`) — pegou que minha 1a tentativa editou o gate do template **a mao** (seria apagado pelo gerador no proximo sync) e que eu afirmei falsamente "sync nao sincroniza classify" (o `bin/sync-template.sh` regenera o gate). **Concordei com a objecao (sem impasse a arbitrar -> sem escalonamento) e incorporei TUDO:** correcao na fonte (gerador do sync); schema fechado (`.engrama/CLAUDE.md` + template: estrutura + Tipos); lint cobrindo o namespace; fidelidade do diagrama (no inicial = governanca/index; **desenhei o break-glass** -> "todos os caminhos" honesto).
- **Re-critica (codex-session `019f0a3e`): `confirmo`** — sem achado material novo; objecao #1 resolvida e DURAVEL (recompos o gate gerado, SHA bateu); schema/lint/diagrama cobertos com paridade byte-a-byte no template. **Consenso.** PROXIMO: commit com diff-binding + PR -> aprovacao da Autoridade (na aprovacao do merge, pagina -> `active`).

## [2026-06-27] update | ativacao do ADR 0015 + 3 specs (flip proposed -> active) pos-merge do PR #17
- Branch `chore/ativar-adr-0015`. O PR #17 (ADR 0015 absorcao Superpowers) foi **mergeado** (merge commit `29e15f7`), mas os arquivos entraram como `status: proposed`. A opcao aprovada pela Autoridade previa specs `active` no merge -> este flip honra isso.
- **Flip:** `status: proposed -> active` em ADR 0015 + `tdd-red-green-refactor` + `planejamento-de-fatia` + `depuracao-sistematica`; removidos os marcadores "proposed" do `index.md`/`specs/README.md`; secao Status do ADR atualizada (aprovada no #17, critica 019f0a08).
- **Binding:** so flip de status, ZERO conteudo novo. Crítica do conteudo ja feita (codex-session 019f0a08, ressalvas incorporadas, consenso) e aprovada pela Autoridade no merge do #17. Ledger registra **`N/A: ativacao mecanica`** vinculado ao diff (decisao da Autoridade: "flip", sem re-critica redundante).
- **PROXIMO:** push + PR + merge (alcada da Autoridade). Pos-merge, ADR 0015 + 3 specs ficam `active` na `main`.

## [2026-06-27] decision | PROPOSTA (proposed) — absorcao seletiva da metodologia Superpowers como specs (ADR 0015)
- Branch `feat/absorcao-seletiva-superpowers`. **Proposta a pedido da Autoridade**, em resposta a "este projeto agrega valor a governanca se incorporado? (obra/Superpowers)".
- **Diagnostico:** Superpowers e craft/workflow, nao governanca; onde toca governanca o Engrama ja e mais forte (code-review = gate mecanico + papeis + diff-binding; verification = ADR 0005). Valor real = camada de METODO.
- **ADR 0015 (`proposed`, `reconcilia: ADD`):** absorver como **specs markdown, nao runtime** — [[memory/specs/tdd-red-green-refactor]] (UPDATE test-writing), [[memory/specs/planejamento-de-fatia]] (UPDATE executor-order), [[memory/specs/depuracao-sistematica]] (UPDATE licao-aprendida); verification-before-completion reforca ADR 0005 sem spec nova. **Rejeita explicitamente:** subagent-driven-development que escreve codigo (quebra ADR 0002/0008 + validacao cruzada), iteracao autonoma de horas (vs freio ativo/2a confirmacao/nao-autoaprova), abstracao cross-platform (dilui independencia Orquestrador<->Executor) e incorporacao como runtime/plugin (fere "canonico=markdown, tooling=descartavel").
- **Critica do Executor (ADR 0006, read-only, codex-session `019f0a08`, source stream):** veredito **`ressalvas`** (ajuste-menor; SEM objecao material). Confirmou: `reconcilia: UPDATE` corretos (nada de DELETE/merge); specs adicionam metodo sem mexer em papeis/alcadas/gate; rejeicao de subagent-escreve-codigo + runtime/plugin correta. **5 ressalvas TODAS incorporadas:** (1) +rejeicao explicita de plano-com-codigo (ADR 0008); (2) rejeicao de cross-platform reescrita p/ "fluidez de papeis / runtime que apaga o bridge" (Engrama e vendor-agnostico por desenho; papeis por funcao); (3) re-ancorada "horas sem checkpoints" no ADR 0004 ATIVO (0009 e `proposed`/inativa); (4) spec de depuracao blindou papeis (Orquestrador audita/exige regra; correcao de codigo volta ao Executor); (5) `source_refs`/`touches` alinhados.
- **NAO commitado.** Consenso (ressalvas incorporadas). **PROXIMO:** aprovacao da Autoridade -> commit com diff-binding (ledger bound ao sha256 do diff + `codex-session:019f0a08`); na aprovacao ADR + 3 specs -> `active`.

## [2026-06-27] release | fechamento da release 0.2.0 — PR #16 + re-bind do diff COMBINADO (critica fresca do agregado)
- Branch `feat/disciplina-de-release-0.2.0` **PR-ready** virou **PR #16** (push + PR contra `main`). Fatias 1-3 ja committadas (`f68b56b`/`e2a2ee6`/`6f58c42`).
- **Gate de PR pegou furo real (nao-flake):** o `critique-gate-ci.sh` em modo estrito roda sobre o diff COMBINADO `origin/main...HEAD`; as 3 fatias foram criticadas individualmente mas faltava critica vinculada ao agregado (critica das partes != do todo). Precedente: re-bind do PR #14.
- **Critica fresca do agregado (Executor read-only, codex-session `019f0995`, source stream):** veredito **`ressalvas`** (nao-bloqueante). Conferiu: sem contradicao inter-fatias; agregado-de-conteudo = `c2752cf0`; CHANGELOG 0.2.0 cobre `v0.1.0..HEAD`; secao 0.1.0 == `git show v0.1.0:CHANGELOG.md` (por hash); paridade raiz<->template (bridge+hasher); release-gate root-only.
- **2 ressalvas dispositadas como follow-up (NAO reabrem 0.2.0):** (1) `bin/release-gate.sh` parser de waiver usa heredoc/tempfile (falha em sandbox read-only; CI tem /tmp; gate saiu 0); (2) `engrama.values.example` + `docs/INSTANTIATE.md` mostram `ENGRAMA_VERSION=0.1.0` (caminho automatico le VERSION=0.2.0). Registradas em [[memory/gaps/follow-ups-pos-0.2.0]].
- **Binding (sem `--no-verify`, mantendo as 3 fatias):** o commit de evidencia (transcript+log+ledger+gap) muda o fingerprint do agregado (inclui o transcript desta critica; exclui o ledger). Entrada substantiva [governance][gate][contract] vinculada ao novo sha256 + auto-vinculacao `N/A` do commit de evidencia (satisfaz o gate local).
- **PROXIMO:** push -> CI verde (4 required checks) -> merge (alcada da Autoridade; `required_approving_review_count=0`, basta CI) -> **tag `v0.2.0`**.

## [2026-06-24] feat | fatia 3 — release 0.2.0 (VERSION + CHANGELOG) + restauracao do anacronismo 0.1.0
- Branch `feat/disciplina-de-release-0.2.0`. Fatias 1 (`f68b56b`) e 2 (`e2a2ee6`) committadas. Esta fecha o ciclo da disciplina de release.
- **Bump:** `VERSION` 0.1.0 -> 0.2.0; `CHANGELOG` ganhou `## [0.2.0] - 2026-06-24` + nova `## [Nao lancado]`. **Restauracao do anacronismo 0.1.0:** o path-rewrite da reorg (#15) reescreveu paths historicos na entrada `## [0.1.0]` (`.engrama/scripts/`->`engine/scripts/` etc.); restaurei ao texto exato da tag `v0.1.0` (Executor confirmou paridade bit-a-bit).
- **Freio ativo do Executor (ADR 0004) em acao:** 1a critica = **`discordo` MATERIAL** (gatilho 4, contradicao com estado real/princ. 12) — a entrada 0.2.0 subcontava o delta real desde `v0.1.0` (so #14/#15/ADR0013/0014; faltavam PR-A..PR-H + ADR 0012). **Concordei com a objecao (sem impasse a arbitrar) e incorporei:** reescrevi a 0.2.0 cobrindo todo `v0.1.0..HEAD` (#6-#15 + fatias). Re-critica = `ressalvas` (movi/removi o item de diff-binding mal-datado — ADR 0011 ja era de 0.1.0; nuance temporal inerente ao commit de release). Consenso.
- **Dogfood do release-gate:** com bump+CHANGELOG, o gate passa a APROVAR pos-commit (payload mudou + VERSION mudou + 1o heading versionado = 0.2.0) — antes do bump ele derrubaria o job `test`.
- **Auditoria (ADR 0005):** suite TODAS VERDES; lint=0; restauracao 0.1.0 == `git show v0.1.0:CHANGELOG.md`. Ledger com sha256 + codex-session (critica+re-critica).
- **PROXIMO:** branch **PR-ready**. Push/PR/merge + **tag `v0.2.0`** = alcada da Autoridade (branch protection). Fatia 4 (disciplina-no-template) = decisao separada da Autoridade.

## [2026-06-24] feat | fatia 2 — release-gate repo-central-only (ADR 0014)
- Branch `feat/disciplina-de-release-0.2.0`. Fatia 1 (bridge-hardening, ADR 0013) ja committada (`f68b56b`). Esta e a fatia 2 do plano de disciplina de release.
- **Desenho fechado (Executor read-only, `019efa28`, `pronto para FASE 2`):** pegou 3 catches do meu pedido — `bin/release-gate.sh` root-only (NAO `engine/scripts/`, que vaza pelo sync-template), `.markdownlint-cli2.yaml` na superficie distribuivel, flags explicitas no hasher.
- **Execucao (Executor workspace-write, `019efa34`, `ajuste-menor`):** `bin/release-gate.sh` (modos ci/warn; exit 0/1/2), manifest root-only `.engrama/release-surface.manifest`, escape `.engrama/evidence/qa/release-waivers.md` (`sem-release` bound-by-hash), `engrama-diff-hash.sh` com flags OPT-IN (`--manifest/--include/--exclude`; default legado intacto), step na CI (job `test`, PR+ubuntu), testes `release-gate.test` 11 + `release-surface.test` 4 + extensoes em diffbind/bootstrap.
- **Risco #1 (nao quebrar o critique-gate):** mitigado — `D10`/`D11` provam `--cached`/`--range` batendo o fingerprint legado bit-a-bit; default volta ao legado por construcao (wrapper); critique-gate exit 0 na auditoria.
- **Governanca (ADR 0006, `019efa4c`):** ADR 0014 + nota CONTRIBUTING; veredito `ressalvas` (3 pontos de honestidade) TODOS incorporados (CI "vinculante"->"derruba job test, bloqueia merge se required-check"; source_refs +release-surface.test; +obrigacao de sincronia do manifest + recalc com origin/<base>).
- **Auditoria (ADR 0005):** suite TODAS VERDES; shellcheck -S info limpo; lint=0; escopo SEM VERSION/CHANGELOG; release-gate fora do template (RS2/RS4). Ledger com sha256 + 3 codex-session.
- **PROXIMO:** fatia 3 — bump `VERSION` 0.2.0 + `CHANGELOG` (data real; restaurar verdade historica do 0.1.0). ATENCAO: a CI derrubaria o job `test` ate o bump (payload mudou nas fatias 1-2) — fatia 3 precede o push. Depois, fatia 4 (disciplina-no-template, decisao separada).

## [2026-06-24] fix | break-glass exec-bridge (schema codex 0.142.0) + re-run critica FASE 1 da disciplina de release 0.2.0
- Branch `feat/disciplina-de-release-0.2.0` (em paridade com main; nada commitado ainda). Sessao de abertura: gate lido, handshake feito.
- **Sintoma:** o par de transcripts `2026-06-22-release-disciplina-critica-*` tinha **resposta vazia** (session `derived`, model `unknown`). Causa-raiz diagnosticada: o **`codex-cli 0.142.0` mudou o schema do `--json`** — resposta agora em `item.completed`/`item.type==agent_message`/`.item.text`; session em `thread.started`/`.thread_id`. O `exec-bridge.sh` parseava o schema ANTIGO (`response_item`/`message`/`output_text`), entao descartava a resposta em silencio. **Canal de governanca quebrado por version-drift, sem teste de contrato pegando** — mesma classe da licao do PR-B.
- **Break-glass (sob ordem explicita da Autoridade; escopo minimo; pendente review retroativo do Executor):** o Orquestrador editou `extract_response_text` (runtime + template via `sync-template`, em paridade) para suportar os dois schemas; `extract_session_id` ja pegava `thread.started` pelo branch `.thread_id`; model fica `unknown` (schema novo nao emite model em nenhum evento — captura via `--model` arg ou hardening). **Provado end-to-end:** smoke pelo bridge -> session real do stream + corpo `PONG` (nao mais vazio); shellcheck -S info + bash -n OK.
- **Re-run da critica FASE 1 (read-only) pelo bridge reparado** (codex-session `019ef9f9...`, source `stream`): capturada na integra. **Veredito do Executor: `discordo` com o plano como escrito** — 2 furos materiais: (1) escape `sem-release` sem binding ao diff; (2) espelhar a disciplina no template sem definir a semantica de release do adotante (template so carrega `.engrama/VERSION` do pack, nao `VERSION` de projeto). + 7 pontos ancorados em arquivo:linha (superficie incompleta/larga, referencia local = merge-base nao tag, lint.sh compartilhado nao deve carregar release, data real no 0.2.0, buracos de teste, espelhamento de prosa raiz<->template, historico de changelog desprotegido).
- **Decisao da Autoridade:** (a) **aceito integral** o redesenho do Executor para a FASE 2 (gate **repo-central-only** `release-gate.sh` + CI vinculante + local merge-base + escape **bound-by-hash** a la ADR 0011 + superficie ajustada [+githooks +.claude/settings.json, -sync-template.sh] + data real + testes ampliados); (b) **fold do bridge-hardening nesta branch**. Ordem das fatias: **[1] bridge-hardening** (teste de contrato vs schema real + ADR + licao + review retroativo do break-glass) -> **[2] release-gate repo-central** -> **[3] release 0.2.0** (restaura verdade historica do 0.1.0) -> **[4] disciplina-no-template** (decisao separada).
- **Fatia 1 (bridge-hardening) CONCLUIDA:** Executor (workspace-write, codex-session `019efa06`, `ajuste-menor`) escreveu o teste de contrato com o stream REAL do 0.142.0 — `E2` (captura agent_message, ignora `error`, session do thread_id), `E3A` (NAO-VACUO: parser legado fica vazio no mesmo stream), `E3B` (compat retroativa), `E7`/`E8` alinhados; review retroativo do break-glass sem objecao material. ADR **0013** (resiliencia a version-drift + dual-parse + teste de contrato; `reconcilia: UPDATE 0003`) + licao + index autorados pelo Orquestrador. Critica de governanca do Executor (ADR 0006, read-only, codex-session `019efa1a`): veredito `ressalvas` (4 pontos de honestidade) — **todos incorporados** (ADD->UPDATE 0003; "fixture real"->eventos reais inline; "log e ledger"->+transcripts; "3a ocorrencia"->2a confirmada+precursor PR-A). Auditoria do Orquestrador (ADR 0005): suite TODAS VERDES (exec-bridge 10 asserts incl. E3A/E3B; sync 21); shellcheck -S info limpo; lint=0; escopo respeitado (zero arquivo de release tocado). `.engrama/.obsidian/` (cruft do editor) -> `.gitignore`.
- **PROXIMO:** apos o commit da fatia 1 -> fatia 2 (release-gate repo-central-only: `release-gate.sh` + CI vinculante + escape bound-by-hash, redesenho do Executor aprovado pela Autoridade) -> fatia 3 (release 0.2.0) -> fatia 4 (disciplina-no-template, decisao separada).

## [2026-06-22] refactor | reorg de .engrama/ por contexto: memory/ + engine/ + evidence/ (opcao B)
- Branch `feat/reorg-engrama-por-contexto`. FASE 1 critica READ-ONLY (codex-session 019eef98, `ajuste-menor`) + FASE 2 execucao (codex-session 019eeffb, `ajuste-menor`). Orquestrador auditou.
- **Decisao da Autoridade:** ninguem usa o pack alem desta instancia + template, entao o custo de migracao de adotantes saiu da conta -> reorg viavel. A pedido da Autoridade, separei **critica de acao**: critica read-only do plano ANTES de mutar, veredito mostrado, OK, e so entao execucao.
- **A FASE 1 (read-only) pegou 4 gaps reais** que meu plano omitia: harness `.claude/settings.json`, wrapper `critique-gate-hook.sh`, ~34+29 paths literais em prosa, `roadmap/` canonico, `template/.engrama/VERSION` no topo — + riscos de ordering. Todos incorporados antes da execucao. Prova viva do valor de separar critica de acao.
- **Estrutura:** topo fixo `{CLAUDE.md,index.md,log.md,VERSION,.gitignore}`; `memory/{governance,decisions,domain,specs,project,gaps,roadmap}`; `engine/{scripts,githooks}`; `evidence/{qa,transcripts}`. Espelhado no template. `roadmap/` = namespace canonico (sem dir fisico).
- **Reescrita:** ~183 wikilinks + source_refs (path-based) + ~63 docs com paths literais em prosa + classify/lint/exec-bridge/diff-hash/gate/hook/settings + sync-template (vars + heredoc do classify) + CI + install/bootstrap + toda a suite. Ledger e log.md: so cabecalho; entradas historicas intactas (append-only).
- **Bug achado+corrigido pelo Executor na FASE 2:** o guard de re-exec do bridge herdava `ENGRAMA_BRIDGE_REEXEC/HERE` do ambiente e pulava a copia estavel; blindou com `ENGRAMA_BRIDGE_SELF` (so honra reexec se o processo E a copia apontada) + ajustou REPO_ROOT p/ o novo depth de engine/scripts.
- **Orquestrador (pos-run):** realocou transcripts vivo -> evidence/transcripts (60 .md); `git config core.hooksPath .engrama/engine/githooks` (o antigo virou morto).
- **QA (ADR 0005):** suite TODAS VERDES; lint=0; markdownlint 0/77; sync idempotente + sync.test 21; shellcheck -S info limpo; grep de completude = zero path antigo em superficie ATIVA (so historico/verbatim em log.md + evidence/transcripts). 174 arquivos, +1458/-1080.

## [2026-06-22] fix | endurecer exec-bridge.sh contra auto-edicao (re-exec de copia estavel) — dobrado no PR #14
- Branch `feat/consolidar-root-em-engrama` (mesmo PR #14, squash p/ 1 commit). Executor via copia estavel do bridge (codex-session `019eef66`, veredito `ajuste-menor`). Orquestrador auditou.
- **Fecha a licao da fatia anterior:** o crash cosmetico (`codex_rc: unbound variable`) vinha de editar o `exec-bridge.sh` enquanto ele era o script em execucao (bash relê por offset de byte). **Fix:** guard no topo que re-executa de uma **copia estavel** em tempfile (`ENGRAMA_BRIDGE_REEXEC`/`ENGRAMA_BRIDGE_HERE`, `HERE` resolve REPO_ROOT sob re-exec), com `trap` de cleanup do tempfile. Comportamento (transcript/session/model/fallbacks) intacto.
- **Dogfood da propria mitigacao:** apliquei o fix rodando o Executor **de uma copia estavel** (`.exec-bridge-stable.sh`, removida pos-run) — a run saiu exit 0, sem o crash da fatia anterior.
- **Teste E8** (`tests/contract/exec-bridge.test.sh`): stub de codex sobrescreve o `exec-bridge.sh` do working tree DURANTE a run (assert `mutated during contract test` prova a corrupcao real) e exige bridge exit 0 + transcripts intactos. Nao-vacuo: sem o guard, falharia.
- **Ajuste-menor do Executor sobre meu esboco:** `trap` no processo pai (EXIT/HUP/INT/TERM) p/ o cleanup; teste edita o bridge **in-place** (nao rename) p/ exercer o modo de falha por offset/inode.
- **QA (ADR 0005):** suite TODAS VERDES (exec-bridge 8 incl. E8; sync 21); paridade S3CA (template identico, guard presente); lint exit 0; shellcheck -S info limpo; reproduzi E8 isolado (CORRETO).

## [2026-06-22] refactor | consolidar raiz em .engrama/ — move bin/critique-gate-ci.sh + transcripts/ (limpa o root do adotante)
- Branch `feat/consolidar-root-em-engrama`. Executor via `exec-bridge.sh` (codex-session `019eef11`, veredito `ajuste-menor`). Orquestrador auditou + 2 micro-fixes (carve-out typo/lint).
- **Origem:** a Autoridade viu `bin/` e `transcripts/` na raiz do `../finance` recem-bootstrapado e perguntou por que coisa do engrama mora fora de `.engrama/`. Diagnostico: 4 itens sao OBRIGATORIOS na raiz (CLAUDE.md/AGENTS.md/.claude/.github — convencao de Claude Code/Codex/GitHub); 3 eram discricionarios. A Autoridade aprovou mover **A+B** e manter `.markdownlint-cli2.yaml` na raiz (escopo C vetado: risco de glob parar de lintar README/docs).
- **A:** `bin/critique-gate-ci.sh` -> `.engrama/scripts/` (raiz+template); `template/bin/` deixa de existir. **B:** `transcripts/` -> `.engrama/transcripts/`; `exec-bridge.sh` grava futuros transcripts la; `lint.sh` ganha prune de `.engrama/transcripts/`; `.markdownlint-cli2.yaml` ignores atualizados; `template/transcripts/README.md` -> `template/.engrama/transcripts/`. Refs atualizadas em ci.yml (raiz+template), sync-template.sh, install.sh, ADR 0003/0006, README/CHANGELOG/docs, 4 suites.
- **Armadilha 1 (bridge):** o Executor editou `exec-bridge.sh` enquanto ele era o script em execucao — bash re-le por offset de byte e o tail crashou (`codex_rc: unbound variable`, exit 1) DEPOIS de capturar a resposta. Trabalho intacto; crash cosmetico. **Licao:** fatia que edita o proprio bridge deveria rodar de uma copia. **Armadilha 2 (auto-move):** o Orquestrador (dono do git, evidencia≠codigo) realocou o `transcripts/` vivo da raiz pos-run, fora da run do Executor, p/ nao rachar o par desta run.
- **Micro-fix do Orquestrador (auditoria pegou):** o prune do lint veio `-path './.engrama/transcripts'` (com `./`) — NO-OP, pois `find .engrama` emite `.engrama/...` sem `./`. O verde do Executor nao pegou porque os transcripts ainda nao estavam dentro de `.engrama/`. Provei isolado, corrigi p/ `-path '.engrama/transcripts'` (raiz, re-sync ao template) + corrigi 3 paths no README realocado. Carve-out typo/lint (escritor≠auditor preservado p/ o refactor).
- **QA (ADR 0005) no estado FINAL (54 transcripts dentro de .engrama/):** lint exit 0 (0 transcripts varridos — prova o prune); suite verde; sync 21; shellcheck -S info limpo; markdownlint 0 erros em 77 arquivos (ignores cobrem ambos transcripts/); zero ref ativa quebrada.
- **PROXIMO:** commit + push + abrir PR (merge depende da Autoridade — branch protection).

## [2026-06-21] feat | PR-H — absorcao mem0/Honcho: nomear padroes (domain) + spec de ingestao (fecha a absorcao)
- Branch `feat/absorcao-domain-ingestao`. Executor via `exec-bridge.sh` (codex-session da run prH, veredito `ajuste-menor`). Orquestrador auditou.
- **Segunda fatia da absorcao (docs).** Nomeia padroes que o engrama JA pratica + formaliza o fluxo de ingestao. Zero infra.
- **Framework (raiz+template):** `specs/ingestao-memoria-dois-fases.md` (Fase I candidato -> Fase II reconciliacao via grep + arvore ADD/UPDATE/DELETE/NOOP, casa com ADR 0012; teto honesto: dedup humano+grep ~500-1000 fatos) · secao memoria quente/fria em `continuidade-de-sessao.md` (de Honcho working/long-term, **explicitamente SEM decay** — consolidacao manual via ADR) · nota de contraste estrutural no ADR 0006 · workflow Ingest alinhado no schema.
- **Instancia-so (raiz):** 3 paginas `domain/` nomeando padroes vivos — `validacao-cruzada-estrutural` (engrama supera mem0: papeis separados vs mesmo-modelo-extrai-e-valida; teto R1) · `escopo-e-identidade` (namespacing mem0 user/session/agent/org -> papel/branch/categoria/codex-session) · `ponto-de-vista-e-representacao` (auto-rep vs rep-do-Executor, de Honcho theory-of-mind; so nomeia, nao resolve R1). Todas com `reconcilia: ADD` (dogfood do ADR 0012).
- **Decisao framework/instancia:** domain/ fica so na instancia viva (o adotante cria as suas); o template referencia em PROSA (nao wikilink) p/ nao quebrar o lint do adotante. O Executor (ajuste-menor) estendeu os catalogos espelhados (index/specs-README raiz+template) p/ nao deixar drift.
- **QA (ADR 0005):** suite verde; lint exit 0 (sem orfa/wikilink quebrado — paginas linkadas no index); sync 21. Confirmei: reconcilia: ADD nas 3 domain pages, source_refs relativos, template sem link quebrado p/ domain.
- **Conclusao:** absorcao Honcho/mem0 fechada (PR-G feature + PR-H docs). Ganho real = maturacao de disciplina/doc (a infra de runtime nao encaixa por arquitetura). O grosso do valor o engrama ja tinha.

## [2026-06-21] feat | PR-G — absorcao mem0/Honcho: reconciliacao de memoria + metricas (ADR 0012)
- Branch `feat/absorcao-reconciliacao-metricas`. Executor via `exec-bridge.sh` (codex-session da run prG, veredito `concordo`, mérito do ADR 0012 favorável). Orquestrador auditou + provou empiricamente.
- **Origem:** analise multiagente de absorcao (Honcho/mem0, 25 candidatos -> 8 aprovados na critica de coerencia). Esses sao sistemas de memoria de RUNTIME; o ganho real e de PADRAO/disciplina, nao infra. Esta fatia implementa o cluster "operacoes de memoria + metricas".
- **ADR 0012 (de mem0 + RFC IETF Obsoletes/Updates):** campo de frontmatter **opcional** `reconcilia: <ADD|UPDATE|DELETE|NOOP> <slug>` — marca se um fato/ADR e novo, complementa, supersede ou reafirma. Disciplina validavel, NAO deduplicacao automatica (limite honesto documentado). O Executor rejeitou a alternativa "obrigatorio em toda pagina" (manteve opcional). Dogfood: o proprio 0012 usa `reconcilia: ADD`.
- **lint.sh:** valida `reconcilia:` quando presente (enum + slug resolve a pagina existente; malformado = erro bloqueante; ausente = ok); **staleness** como WARNING nao-bloqueante (> 90d sem commit em governance/specs/decisions `active`, via `git log %ct` — clone-stable, nao mtime; override `ENGRAMA_NOW` p/ teste); nomeou a deteccao de orfas como metrica de densidade de enlaces. Canal de warning separado do de erro (exit so depende de ERRORS).
- **gaps/metricas-de-engrama.md (proposed):** registra metricas implementadas (densidade de enlaces, staleness) + abertas como pesquisa (cobertura, coerencia semantica) — explicitamente SEM infra de runtime. Fica so na instancia viva (template nao carrega gaps/).
- **QA (ADR 0005):** suite verde (lint.test 22, sync 21); lint/shellcheck(-S info) exit 0; provei: staleness com `ENGRAMA_NOW` futuro emite 23 warnings mas exit 0; reconcilia com alvo inexistente bloqueia (exit 1). Schema/lint espelhados no template (ADR 0012 manual, pois sync-template nao propaga ADRs).
- **PROXIMO:** PR-H (paginas domain/ que nomeiam padroes ja vivos + spec de ingestao + working/long-term).

## [2026-06-21] feat | PR-F — polimento de docs/install do bootstrap (P2/P3, fecha a remediacao)
- Branch `feat/p3-docs-install-polish`. Executor via `exec-bridge.sh` (codex-session da run prF, veredito `concordo`). Orquestrador auditou + smoke proprio.
- **Fecha a lista P2/P3 da auditoria de prontidao.** Itens:
  - **Placeholders:** tabela do Passo 2 do INSTANTIATE reconciliada com os 17 placeholders reais do template (faltavam CMD_DEV/BUILD/TEST + FINALIDADE), exemplos vindos de `engrama.values.example` (apontado como inventario canonico). O Executor tambem cortou exemplos `Ruflos` herdados na tabela.
  - **install.sh:** smoke de integridade (`bash -n` nos 5 scripts criticos + dry-run do `engrama-diff-hash.sh` provando `sha256:<hex>`), nao-abortante; checklist final ganhou Passo 7 (enforcement server-side: push + branch protection) e Passo 8 (revisar/apagar o exemplo seed do log/ledger).
  - **CONTRIBUTING:** nota de que ADRs `0001-0011` sao referencia do framework; os do projeto comecam em `0012`.
  - **CLAUDE.md (raiz+template):** bullet de que universais (governance/gate/contract) nascem protegidas e adaptar `classify()` ao dominio segue obrigatorio.
- **Isolamento (regra pos-incidente):** Executor nao mexeu no git do repo real; identidade reverificada antes de gravar.
- **QA (ADR 0005):** suite verde; lint/shellcheck(-S info)/sync exit 0; meu smoke via `bin/bootstrap.sh` em /tmp mostrou o bloco de integridade (5 OK + sha256) e os Passos 7/8.
- **Conclusao:** com PR-D+E+F, os P1/P2/P3 da auditoria de prontidao estao fechados (menos os itens dropados por contradizerem arquitetura: docs/values.example no template; mover ADRs 0001-0011). O bootstrap fica `ready` operacional.

## [2026-06-21] feat | PR-E — enforcement server-side PORTATIL no template (P2 da auditoria)
- Branch `feat/p2-enforcement-server-side`. Executor via `exec-bridge.sh` (codex-session 019eecc5, veredito `concordo`). Orquestrador auditou + reexecutou.
- **Fecha o P2:** um projeto recem-bootstrapado nascia so com o freio LOCAL (burlavel). Agora o `template/` entrega o enforcement server-side: `template/.github/workflows/ci.yml` (ENXUTO/portatil — jobs gate+markdown+gitleaks, sem `tests/run.sh` do framework), `template/bin/critique-gate-ci.sh` (identico a raiz, portatil), `template/.markdownlint-cli2.yaml`.
- **Paridade garantida:** `sync-template.sh` + `sync.test.sh` (21 asserts) sincronizam o gate-CI e o pin do gitleaks (v8.30.1) raiz<->template; o ci.yml do template NAO e identico a raiz (por design) mas o contrato exige que exista + referencie o gate-CI + nao drifte no pin.
- **Honestidade (princ. 12):** README vira "template QUASE auto-contido" (entrega freio local + CI; branch protection e passo MANUAL no GitHub do adotante). INSTALL/INSTANTIATE ganham passo "ativar enforcement server-side" com `gh api` concreto (required check no job `gate`, exigir PR, bloquear force-push). ADR 0006 (raiz cita job `test`; template cita job `gate` — o Executor acertou a distincao) ganha a ressalva de que o modo estrito e OFF por padrao LOCALMENTE; o freio vinculante e server-side.
- **LICAO (loop falha->regra) — incidente de isolamento:** durante o PR-D, um smoke de agente rodou `git config`+`git commit` no REPO REAL (nao em /tmp), contaminando minha identidade (-> "Test User") e deixando o commit do PR-D (da45576, ja mergeado) mis-atribuido + um commit-lixo no main local. Detectei via soft-reset, resetei o main local pro origin/main correto, restaurei a identidade e limpei o lixo. **Regra:** (1) ordens ao Executor proibem explicitamente mutacao git no repo real — smoke so em `mktemp` com `git -C`; (2) o Orquestrador reverifica `git config user.email` antes de cada commit. No PR-E a regra valeu: identidade ficou intacta.
- **QA (ADR 0005):** suite verde (sync 21 asserts); lint/shellcheck(-S info)/sync exit 0; `template/.github/workflows/ci.yml` validado com parser YAML real (ruby). O workflow do template so roda de fato num repo adotante — nao exercivel localmente.

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
