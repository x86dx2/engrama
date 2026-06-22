# ORDEM (FASE 1 = CRÍTICA READ-ONLY) — reorg de .engrama/ por contexto (opção B)

**IMPORTANTE: esta é uma passada de CRÍTICA, sandbox READ-ONLY. NÃO execute, NÃO mova arquivos, NÃO edite nada.**
Sua tarefa é **criticar o PLANO abaixo** antes de qualquer mutação: apontar riscos, gaps, superfícies de
referência que eu esqueci, ordering, e dar um veredito (`concordo` | `ajuste-menor` | `discordo`) sobre se o
plano está sólido para uma FASE 2 de execução. Liste explicitamente **toda referência hardcoded a path que eu
NÃO mapeei**. Não basta concordar — cace o que falta.

## Objetivo
Reorganizar `.engrama/` por contexto (decisão da Autoridade, opção B). Sem adotantes externos: só importam
**esta instância viva (root) + o `template/`**. É um refactor MECÂNICO grande (move pastas + reescreve paths
e wikilinks), preservando 100% do comportamento (gate, lint, sync, suíte, markdownlint) verde.

## Estrutura alvo
```
.engrama/
├── CLAUDE.md  index.md  log.md  .gitignore     # FICAM no topo (schema/nav/checkpoint quente; hook+gate leem por path fixo)
├── memory/      ← governance/ decisions/ domain/ specs/ project/ gaps/   (conhecimento curado)
├── engine/      ← scripts/ githooks/                                      (maquinário)
└── evidence/    ← qa/ transcripts/                                        (evidência append-only)
```
Mesma estrutura no `template/.engrama/` (mas o template não tem domain/gaps; tem decisions 0001-0011, governance, specs, project).

## Mapa de movimento (git mv preferido; mas no sandbox read-only você NÃO move — só critica)
- `.engrama/governance` → `.engrama/memory/governance` · idem `decisions`, `domain`, `specs`, `project`, `gaps`
- `.engrama/scripts` → `.engrama/engine/scripts` · `.engrama/githooks` → `.engrama/engine/githooks`
- `.engrama/qa` → `.engrama/evidence/qa` · `.engrama/transcripts` → `.engrama/evidence/transcripts`
- Igual no `template/.engrama/` (as pastas que existem lá).
- **`transcripts/` vivo do root:** o exec-bridge grava o transcript DESTA run nele; na FASE 2 o ORQUESTRADOR realoca o histórico (não o Executor), como na consolidação.

## Superfícies de referência a reescrever (FASE 2) — critique a COMPLETUDE desta lista
**Wikilinks/source_refs (path-based, `resolve_wikilink_target` = `$ROOT/.engrama/<slug>.md`):**
- 183 wikilinks no root + ~180 no template: `[[governance/x]]`→`[[memory/governance/x]]`, `[[decisions/00NN]]`→`[[memory/decisions/00NN]]`, `[[specs/x]]`→`[[memory/specs/x]]`, `[[project/x]]`→`[[memory/project/x]]`, `[[gaps/x]]`→`[[memory/gaps/x]]`, `[[domain/x]]`→`[[memory/domain/x]]`, `[[qa/x]]`→`[[evidence/qa/x]]`. `source_refs:` análogos.

**Maquinário (root) — depois roda `sync-template.sh` p/ propagar aos 9 do template:**
- `engine/scripts/critique-gate.sh`: `classify()` (todos os `.engrama/...`), `LEDGER=".engrama/evidence/qa/criticas-do-executor.md"`, path do `engrama-diff-hash.sh` (`.engrama/engine/scripts/...`).
- `engine/scripts/engrama-diff-hash.sh`: exclusão do ledger → `.engrama/evidence/qa/...`.
- `engine/scripts/lint.sh`: globs hardcoded (`list_orphan_candidates`, `is_engrama_page`, `list_markdown_files`) → `.engrama/memory/...`; prune → `.engrama/evidence/transcripts`; `resolve_wikilink_target` continua `$ROOT/.engrama/<slug>.md` (os slugs já levam o novo prefixo).
- `engine/scripts/exec-bridge.sh`: `TRANSCRIPTS_DIR` → `.engrama/evidence/transcripts`.
- `engine/scripts/session-context.sh`: paths de `log.md` (FICA `.engrama/log.md`) e bootstrap (`.engrama/memory/project/bootstrap-do-projeto.md`).
- `engine/scripts/critique-gate-ci.sh`: paths.
- `engine/githooks/pre-commit`: caminho do gate → `.engrama/engine/scripts/critique-gate.sh`.

**`sync-template.sh` (gerador):** todas as vars `ROOT_*`/`TEMPLATE_*` (ex.: `template/.engrama/engine/scripts/...`), e o heredoc `emit_template_gate_classify` (paths do `classify()` do template).

**Config/git:** `git config core.hooksPath .engrama/engine/githooks` (root) + onde o `install.sh`/`bootstrap.sh` setam.

**Gates de entrada / schema / nav:**
- root `CLAUDE.md` + `template/CLAUDE.md`: ordem de leitura (governance→`memory/governance`, project→`memory/project`; log.md fica) e "Schema: `.engrama/CLAUDE.md`" (fica).
- `.engrama/CLAUDE.md` + template: a árvore "Estrutura".
- `.engrama/index.md` + template: wikilinks + a estrutura citada.
- `AGENTS.md` root+template: refs de path se houver.

**CI / lint / docs / instalador:**
- `.github/workflows/ci.yml` root+template: `shellcheck .engrama/engine/scripts/*.sh`, `bash ./.engrama/engine/scripts/{critique-gate-ci,lint}.sh`, `.engrama/engine/githooks/pre-commit`.
- `.markdownlint-cli2.yaml` root+template: ignores → `.engrama/evidence/transcripts` + `template/.engrama/evidence/transcripts`.
- `bin/install.sh`: smoke de integridade (paths dos 5 scripts), set de hooksPath, checagem de colisão (CLAUDE/AGENTS/.engrama — ok).
- `bin/bootstrap.sh`: `seed_bootstrap_dispensa` (ledger `.engrama/evidence/qa/...`), `engrama-diff-hash.sh` path, `stage_bootstrap_snapshot`.
- `docs/INSTALL.md`, `docs/INSTANTIATE.md`, `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md`: refs de path em prosa.
- TODA a suíte `tests/**`: paths esperados (`.engrama/scripts`, `.engrama/qa`, `.engrama/governance`, hooksPath, etc.) — provavelmente o maior volume depois dos wikilinks.

## Fronteiras (FASE 2)
- NÃO mover/editar o conteúdo de transcripts históricos (verbatim) nem entradas históricas de log/ledger.
- NÃO tocar o `transcripts/` vivo do root durante a run do Executor (o Orquestrador realoca).
- `log.md`, `index.md`, `.engrama/CLAUDE.md` FICAM no topo de `.engrama/`.
- Sem `git commit`/`git config`/`push` pelo Executor; smoke só em `mktemp`.

## Critérios de aceite (FASE 2)
- Estrutura alvo aplicada em root + template; suíte verde; lint exit 0; markdownlint 0; sync idempotente + sync.test verde; shellcheck -S info limpo; gate local+estrito exit 0; zero wikilink/source_ref quebrado; `git config core.hooksPath` atualizado e o pre-commit dispara.

## O QUE EU QUERO DESTA FASE 1 (read-only)
1. Veredito sobre o plano (`concordo`/`ajuste-menor`/`discordo`) com justificativa.
2. **Lista de toda referência hardcoded que eu NÃO mapeei** (cace em scripts, tests, docs, gerador).
3. Riscos/gotchas de ordering (ex.: o gate roda no commit lendo o ledger em `.engrama/evidence/qa/` — o próprio commit da reorg precisa que a entrada do ledger já esteja no novo path? o diff-hash exclui o ledger por path — se o path muda, a exclusão tem que mudar ANTES de calcular o hash do commit).
4. Recomendação de fatiamento: dá pra fazer em 1 commit só (atômico, senão lint/gate quebram no meio) ou você vê risco que justifique sub-fases?
5. Qualquer alternativa melhor que você enxergue.

NÃO execute. Só critique.
