# Log — Memória factual append-only

Mais recente no topo. Cabeçalho: `## [YYYY-MM-DD] {tipo} | título`. Logar **antes** de cada commit não-trivial. O item mais recente no topo **é** o checkpoint vivo (estado de retomada) — ver [[governance/continuidade-de-sessao]].

Tipos comuns: `decision` · `ingest` · `update` · `slice` · `fix` · `chore` · `audit` · `phase`.
Permite `grep "^## \[" log.md | tail -N` para varrer o histórico.

---

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
