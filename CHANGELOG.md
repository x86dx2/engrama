# Changelog

Todas as mudanças relevantes deste pack. Formato baseado em
[Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/); versionamento
[SemVer](https://semver.org/lang/pt-BR/).

## [Não lançado]

### Mudado
- **Estrutura reorganizada (padrão do ai-memory/Akita):** o root passou a conter
  só metadados/manifests; o tooling e os guias foram para pastas por preocupação.
  `install.sh`/`bootstrap.sh`/`sync-template.sh`/`critique-gate-ci.sh` → **`bin/`**;
  `lint.sh`/`engrama-diff-hash.sh` → **`.engrama/scripts/`** (junto do gate, deixando
  o `.engrama/` autocontido e distribuível); `INSTALL.md`/`INSTANTIATE.md` → **`docs/`**.
  Comandos de instalação agora usam `bash bin/install.sh` / `bash bin/bootstrap.sh`.

### Adicionado
- `CONTRIBUTING.md` (fluxo branch→PR→CI→merge + modelo de governança) e `SECURITY.md`.
- Suíte de testes portável (zero-dep) em `tests/`: `tests/gate/` (comportamento do
  gate de crítica) e `tests/contract/` (instalador/bootstrap), com runner `tests/run.sh`.
- CI em `.github/workflows/ci.yml` (matriz ubuntu + macOS): `shellcheck` + `tests/run.sh`.
- `LICENSE` (MIT) e este `CHANGELOG.md`.

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
- **Diff-binding — modo estrito DESLIGADO:** o fingerprint diverge entre o gate local
  (`git diff --cached`) e o gate-CI (repo sintético). Até unificar, o estrito fica off;
  o gate-contra-PR exige a crítica registrada, não o `sha256` exato. Ver ADR 0011.
- **EX4 (portabilidade/vendor):** `source_refs` absolutos; nomes de modelo `gpt-5.x`
  e o canal `codex exec` hardcoded (vs "por função, não por vendor").

### Pendente
- **`{{ENGRAMA_VERSION}}`** injetado no `.engrama` instalado + tag/release SemVer.
