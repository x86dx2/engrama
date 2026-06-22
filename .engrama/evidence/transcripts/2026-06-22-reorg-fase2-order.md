# ORDEM (FASE 2 = EXECUÇÃO, workspace-write) — reorg de .engrama/ por contexto (opção B)

A FASE 1 (crítica read-only, codex-session 019eef98, veredito `ajuste-menor`) já rodou; os gaps dela estão
INCORPORADOS abaixo. **Agora é EXECUÇÃO.** Critique a ordem (item 2) e, salvo objeção material, execute.

## 1. Objetivo
Reorganizar `.engrama/` por contexto (opção B). Sem adotantes externos: só importam esta instância viva (root)
+ `template/`. Refactor MECÂNICO grande, preservando 100% do comportamento verde (suíte, lint, sync, markdownlint, gate).

## 2. Estrutura alvo
```
.engrama/
├── CLAUDE.md  index.md  log.md  VERSION  .gitignore     # FICAM no topo (path fixo: schema/nav/checkpoint/versão)
├── memory/    ← governance/ decisions/ domain/ specs/ project/ gaps/ roadmap/
├── engine/    ← scripts/ githooks/
└── evidence/  ← qa/ transcripts/
```
Mesma forma em `template/.engrama/`. **`roadmap/` é canônico → `memory/roadmap/`** (não há dir físico; é só referência em classify/CLAUDE/index/README). **`VERSION` (root e template) FICA no topo.**

## 3. Movimento (git mv preferido; pode ser mv + deixar o Orquestrador stagear)
- `.engrama/{governance,decisions,domain,specs,project,gaps}` → `.engrama/memory/…` (+ refs de `roadmap/` → `memory/roadmap/`).
- `.engrama/{scripts,githooks}` → `.engrama/engine/…`
- `.engrama/{qa,transcripts}` → `.engrama/evidence/…`
- Igual em `template/.engrama/` (pastas que existirem).
- **NÃO** mova/edite o diretório `transcripts/` VIVO do root nem seu conteúdo — o Orquestrador realoca pós-run (o exec-bridge grava o transcript desta run nele).

## 4. Reescrita de referências — COMPLETA (gaps da FASE 1 inclusos). Faça TUDO + grep final por `.engrama/{governance,decisions,domain,specs,project,gaps,roadmap,scripts,githooks,qa,transcripts}/`
**a) Wikilinks + source_refs** (resolver = `$ROOT/.engrama/<slug>.md`): `[[governance/x]]`→`[[memory/governance/x]]`, decisions/specs/project/gaps/domain→`memory/…`, `[[qa/x]]`→`[[evidence/qa/x]]`. (~183 root + ~180 template.)
**b) Paths literais em PROSA/comandos** nas docs internas (a FASE 1 contou ~34 ativos no root + ~29 no template): governance/index.md, modelo-operacional.md, cadeia-de-comando.md, papeis-e-alcadas.md; ADRs 0003/0006/0011; specs/README, licao-aprendida, ingestao; domain/*, gaps/*; e pares no template.
**c) Maquinário (root → depois roda sync-template):**
  - `engine/scripts/critique-gate.sh`: `classify()` (todos `.engrama/…` → memory/engine/evidence; inclui `.engrama/roadmap/*`→`memory/roadmap/*`, `.engrama/scripts/*.sh`→`.engrama/engine/scripts/*.sh`, `.engrama/githooks/*`→`.engrama/engine/githooks/*`, `.engrama/qa/*`→`.engrama/evidence/qa/*`); `LEDGER=".engrama/evidence/qa/criticas-do-executor.md"`; path do `engrama-diff-hash.sh`.
  - `engine/scripts/engrama-diff-hash.sh`: exclusão do ledger → `.engrama/evidence/qa/…` **(crítico p/ ordering, ver §5)**.
  - `engine/scripts/lint.sh`: `list_orphan_candidates`/`is_engrama_page`/`list_markdown_files` (globs → `.engrama/memory/…`); prune → `.engrama/evidence/transcripts`; `resolve_wikilink_target` segue `$ROOT/.engrama/<slug>.md`.
  - `engine/scripts/exec-bridge.sh`: `TRANSCRIPTS_DIR` → `.engrama/evidence/transcripts`.
  - `engine/scripts/session-context.sh`: log.md fica `.engrama/log.md`; bootstrap → `.engrama/memory/project/bootstrap-do-projeto.md`.
  - `engine/scripts/critique-gate-ci.sh`: paths.
  - `engine/githooks/pre-commit`: gate → `.engrama/engine/scripts/critique-gate.sh`.
**d) HARNESS (gap FASE 1):** `.claude/settings.json` (root **e** template) — PreToolUse/SessionStart/PreCompact apontam p/ `.engrama/scripts/…` → `.engrama/engine/scripts/…`; e **`critique-gate-hook.sh`** (root **e** template) — paths internos.
**e) `sync-template.sh` (gerador):** vars `ROOT_*`/`TEMPLATE_*` → novos paths (ex.: `template/.engrama/engine/scripts/…`, `template/.engrama/evidence/qa/…`); heredoc `emit_template_gate_classify` (classify do template) → novos paths (inclui roadmap→memory/roadmap, scripts→engine, qa→evidence). Rode `bash ./bin/sync-template.sh` no fim p/ propagar os 9 maquinários ao template.
**f) Gates/schema/nav:** root `CLAUDE.md` + `template/CLAUDE.md` (ordem de leitura: governance→`memory/governance`, project→`memory/project`; log/VERSION/schema ficam); `.engrama/CLAUDE.md` + template (árvore "Estrutura" + paths em prosa); `index.md` + template (wikilinks + estrutura); `AGENTS.md` root+template.
**g) CI + markdownlint:** `.github/workflows/ci.yml` root+template (`shellcheck .engrama/engine/scripts/*.sh`, `bash ./.engrama/engine/scripts/{critique-gate-ci,lint}.sh`, `.engrama/engine/githooks/pre-commit`); `.markdownlint-cli2.yaml` root+template (ignores → `.engrama/evidence/transcripts` + `template/.engrama/evidence/transcripts`).
**h) Install/bootstrap/docs:** `bin/install.sh` (smoke dos 5 scripts → engine/scripts; set de hooksPath → `.engrama/engine/githooks`); `bin/bootstrap.sh` (`seed_bootstrap_dispensa` ledger → evidence/qa; diff-hash; snapshot); `docs/INSTALL.md`, `docs/INSTANTIATE.md`, `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md`.
**i) Testes:** toda a suíte `tests/**` (paths esperados: `.engrama/scripts`→engine, `.engrama/qa`→evidence/qa, `.engrama/governance`→memory/governance, hooksPath, etc.).
**j) Ledger (header vivo):** reescreva SÓ o cabeçalho/instruções/source_refs (paths). **NÃO** edite as entradas históricas `## [...]` (append-only). Não acrescente entrada nova (o Orquestrador faz a entrada diff-bound).

## 5. Ordering crítico
- Atualize a exclusão do ledger no `engrama-diff-hash.sh` e o `LEDGER` do gate **para o novo path** como parte da fatia (o Orquestrador calcula o hash depois, já no path novo).
- `.claude/settings.json` + `critique-gate-hook.sh` devem ser atualizados na MESMA fatia do move de `engine/scripts` (senão o harness aponta p/ path morto).
- `VERSION` (root+template) permanece no topo.

## 6. Fronteiras (não tocar / não fazer)
- NÃO `git config`, NÃO `git commit`, NÃO `git push`. (hooksPath do repo real e o commit são do Orquestrador.)
- NÃO mover/editar `transcripts/` vivo do root nem conteúdo de transcripts históricos (verbatim).
- NÃO editar entradas históricas de `log.md` nem do ledger.
- `log.md`/`index.md`/`.engrama/CLAUDE.md`/`VERSION`/`.gitignore` FICAM no topo de `.engrama/`.
- Smoke (se precisar) só em `mktemp`/`git -C`. Shell portátil; shellcheck `-S info` limpo.

## 7. Critérios de aceite
1. Estrutura alvo aplicada (root+template), incl. refs de `memory/roadmap/`.
2. `bash ./tests/run.sh` verde; `bash ./.engrama/engine/scripts/lint.sh` exit 0; `bash ./bin/sync-template.sh` (2x) idempotente; `bash ./tests/contract/sync.test.sh` verde; `shellcheck -S info` limpo nos `.sh` tocados; markdownlint 0.
3. Grep "zero path antigo ATIVO": `grep -rn '\.engrama/\(governance\|decisions\|domain\|specs\|project\|gaps\|roadmap\|scripts\|githooks\|qa\|transcripts\)/' . --include='*.sh' --include='*.md' --include='*.yml' --include='*.json'` deve sobrar SÓ histórico/verbatim — **allowlist:** `.engrama/log.md` (e `.engrama/memory/.../` que é o novo!), entradas históricas do ledger, `.engrama/transcripts/**` (vivo, será realocado). NÃO conte os paths NOVOS (`memory/`, `engine/`, `evidence/`) como "antigos".

## 8. Validações esperadas (rode e cole a saída real)
- `bash ./tests/run.sh`
- `bash ./.engrama/engine/scripts/lint.sh; echo "lint=$?"`
- `bash ./bin/sync-template.sh && bash ./bin/sync-template.sh`
- `bash ./tests/contract/sync.test.sh`
- `shellcheck -S info` nos `.sh` tocados
- grep de completude (§7)

## 9. Resposta mínima
Os 6 itens (leitura · crítica · veredito · execução · evidências · pendências). Sandbox `workspace-write`, modelo default.
Lembre: o Orquestrador, pós-run, realoca o `transcripts/` vivo → `.engrama/evidence/transcripts/`, faz `git config core.hooksPath .engrama/engine/githooks`, adiciona a entrada diff-bound no ledger (novo path) e comita em 1 commit.
