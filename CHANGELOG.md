# Changelog

Todas as mudanças relevantes deste pack. Formato baseado em
[Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/); versionamento
[SemVer](https://semver.org/lang/pt-BR/).

## [Não lançado]

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
