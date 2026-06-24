# Changelog

Todas as mudanças relevantes deste pack. Formato baseado em
[Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/); versionamento
[SemVer](https://semver.org/lang/pt-BR/).

## [Não lançado]

## [0.2.0] - 2026-06-24

Cobre todo o intervalo desde `v0.1.0` (PRs #6–#15 + as fatias da disciplina de release desta branch).

### Adicionado
- **Transparência do executor-bridge (ADR 0003, PR-A/#6):** `.engrama/engine/scripts/exec-bridge.sh`
  mecaniza a invocação do `codex exec` e versiona ordem + resposta + `codex-session` em
  `evidence/transcripts/`.
- **Reconciliação de memória (ADR 0012, PR-G/#12):** campo opcional
  `reconcilia: ADD|UPDATE|DELETE|NOOP` validado pelo lint; métricas de densidade de enlaces
  e de staleness (warning não-bloqueante).
- **Domain + spec de ingestão em duas fases (PR-H/#13):** nomeia padrões já praticados
  (validação cruzada, escopo/identidade, ponto-de-vista) e formaliza o fluxo de ingestão.
- **Enforcement server-side portátil no template (PR-E/#10):** `template/.github/workflows/ci.yml`
  enxuto + `critique-gate-ci.sh` + `.markdownlint-cli2.yaml`, com paridade raiz↔template
  garantida por `sync-template.sh` + `sync.test`.
- **Gate de release repo-central-only (ADR 0014, fatia 2):** `bin/release-gate.sh`
  (modos `ci`/`warn`) + manifest `.engrama/release-surface.manifest` + escape `sem-release`
  bound-by-hash em `.engrama/evidence/qa/release-waivers.md` + step na CI; `engrama-diff-hash.sh`
  ganhou filtros opt-in (`--manifest`/`--include`/`--exclude`) com o caminho default intacto.

### Mudado
- **Reorganização de `.engrama/` por contexto (#15):** `memory/` (conhecimento) +
  `engine/` (scripts + githooks) + `evidence/` (qa + transcripts); topo fixo
  (`CLAUDE.md`/`index.md`/`log.md`/`VERSION`/`.gitignore`); espelhada no template.
  Os scripts passaram de `.engrama/scripts/` para `.engrama/engine/scripts/`.
- **Consolidação da raiz em `.engrama/` (#14):** `bin/critique-gate-ci.sh` e `transcripts/`
  movidos para dentro de `.engrama/` (raiz do adotante mais limpa).
- **Atritos do adotante no bootstrap (PR-D/#9):** `classify()` imperativo (mapear a
  superfície sensível do domínio é obrigatório antes do 1º commit); auto-teste em branch
  descartável; deadlock galinha-e-ovo resolvido (dispensa do bootstrap vinculada por `sha256`);
  dica do gate em repo recém-criado.
- **Polimento de docs/install do bootstrap (PR-F/#11):** tabela de placeholders reconciliada
  com o template; smoke de integridade no `install.sh`; checklist com enforcement server-side.
- **Quickstart + gitleaks sem Node (PR-C/#8):** TL;DR de adoção no README; diff-binding
  multi-commit acionável (`::notice::` na CI + recomendação de squash); gitleaks por binário
  fixado + verificado por checksum (elimina o warning de Node 20 deprecado).

### Corrigido
- **`exec-bridge` resiliente a version-drift do `codex` (ADR 0013, fatia 1):** o `codex-cli 0.142.0`
  mudou o schema do `--json` (`item.completed`/`agent_message`) e o bridge — escrito para o
  schema antigo — descartava a resposta do Executor em silêncio. Agora faz dual-parse
  (novo + antigo) e tem teste de contrato exercitando o stream real (não-vácuo).
- **Endurecimento do `exec-bridge` contra auto-edição em runtime (#14):** re-execução a
  partir de uma cópia estável, imune a editar o próprio script durante a run.
- **Captura da resposta do bridge + teste do hook + lint completo (PR-B/#7):** o wrapper
  capturava o `session-id` mas não o corpo da resposta → corrigido com fallback do session
  file; teste do hook (6 casos) e lint estendido (órfãs, numeração de ADR, status, TODO).
- **Anacronismo no CHANGELOG (fatia 3):** a entrada `## [0.1.0]` havia sido reescrita pelo
  path-rewrite da reorg (paths `.engrama/engine/scripts/` que não existiam no 0.1.0);
  restaurada à verdade histórica da release (tag `v0.1.0`).

## [0.1.0] - 2026-06-21

### Mudado
- **Estrutura reorganizada (padrão do ai-memory/Akita):** o root passou a conter
  só metadados/manifests; o tooling e os guias foram para pastas por preocupação.
  `install.sh`/`bootstrap.sh`/`sync-template.sh`/`critique-gate-ci.sh` → **`bin/`**;
  `lint.sh`/`engrama-diff-hash.sh` → **`.engrama/scripts/`** (junto do gate, deixando
  o `.engrama/` autocontido e distribuível); `INSTALL.md`/`INSTANTIATE.md` → **`docs/`**.
  Comandos de instalação agora usam `bash bin/install.sh` / `bash bin/bootstrap.sh`.
- **Adaptadores de vendor documentados honestamente:** `EXECUTOR_CMD`, ids de modelo
  e `.claude/settings.json` passam a ser descritos como **camada concreta e trocável**.
  Os valores `gpt-5.x` permanecem como exemplos/configuração atual do pack, com
  ressalva explícita para confirmar o id real no namespace do `codex exec`.

### Adicionado
- `CONTRIBUTING.md` (fluxo branch→PR→CI→merge + modelo de governança) e `SECURITY.md`.
- Suíte de testes portável (zero-dep) em `tests/`: `tests/gate/` (comportamento do
  gate de crítica) e `tests/contract/` (instalador/bootstrap), com runner `tests/run.sh`.
- CI em `.github/workflows/ci.yml` (matriz ubuntu + macOS): `shellcheck` + `tests/run.sh`.
- `LICENSE` (MIT) e este `CHANGELOG.md`.
- `VERSION` na raiz como fonte de verdade do pack, seed de `ENGRAMA_VERSION` no
  bootstrap, e `.engrama/VERSION` instalado no projeto-alvo para registrar a versão
  efetivamente adotada.

### Corrigido
- **Instalador (`install.sh`):** substituição de placeholders deixou de quebrar com
  valores contendo `#`, `&` ou `\` (escape literal) e passou a ser **fail-closed**
  (aborta `exit!=0` se a substituição falhar ou sobrar placeholder), em vez de
  reportar sucesso com a instalação crua.
- **Gate (`critique-gate.sh`):**
  - leitura NUL-safe (`-z`) — paths não-ASCII deixam de escapar a classificação (R3);
  - `detached HEAD` agora é **fail-closed** (R4);
  - parsing do ledger **por campo** em vez de substring — fecha o falso-positivo de
    `nao confirmo` (R2) e o bypass de entrada cross-branch (R5);
  - `classify()` passou a cobrir `tests/gate/`, `tests/contract/`, `.github/` e
    `.engrama/{gaps,roadmap,domain}/`.
- **Hook (`critique-gate-hook.sh`):** fail-closed quando `python3` falta ou o parse falha.
- **Diff-binding / CI:** o fingerprint foi unificado entre local e CI pela mesma
  fonte única (`engrama-diff-hash.sh`): local usa o diff staged; CI usa
  `--range <base>...HEAD` sobre o **diff real do PR** e volta a rodar com
  `ENGRAMA_REQUIRE_DIFF_BIND=1`.

### Documentação
- README e ADR 0006: linguagem de enforcement alinhada à verdade — o hook local é um
  freio **cooperativo** (burlável por `--no-verify` / fora do harness); a CI **reexecuta
  o gate contra o diff do PR** e esse check **está marcado como *required*** no branch
  protection → **enforcement vinculante no merge** (R1 mitigado server-side). Bootstrap
  chicken-and-egg explicitado (crítica inicial `dispensada`).
- Schema (`.engrama/CLAUDE.md`): bloco "Estrutura" corrigido (inclui `specs/`, `qa/`,
  `scripts/`, `githooks/`; marca `domain/`, `gaps/`, `roadmap/` como criadas por projeto).

### Conhecido / aberto
- **R1 (identidade do crítico):** o gate prova **cobertura do diff**, não **identidade
  independente** do crítico (teto: assinatura/chave que o `codex exec` não expõe). O
  *required check* na CI mitiga o lado server-side. Ver ADR 0006/0011.
- **Diff-binding em PR multi-commit:** o binding da CI cobre o **diff cumulativo**
  de `base...HEAD`, não cada commit isoladamente. O fluxo recomendado continua sendo
  squash/PR de 1 commit. Ver ADR 0011.
