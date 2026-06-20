# Changelog

Todas as mudanças relevantes deste pack. Formato baseado em
[Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/); versionamento
[SemVer](https://semver.org/lang/pt-BR/).

## [Não lançado]

### Adicionado
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
  freio **cooperativo** (burlável por `--no-verify` / fora do harness); o enforcement
  vinculante (gate como *required check* server-side) é **pendente**, pois a CI atual
  só roda `shellcheck` + testes, não o gate contra o PR. Bootstrap chicken-and-egg
  explicitado (crítica inicial `dispensada`).
- Schema (`.engrama/CLAUDE.md`): bloco "Estrutura" corrigido (inclui `specs/`, `qa/`,
  `scripts/`, `githooks/`; marca `domain/`, `gaps/`, `roadmap/` como criadas por projeto).

### Conhecido / aberto
- **R1 (auto-aprovação local):** o gate local não distingue prova independente de
  auto-atestado. **Furo aberto**; mitigação (gate como *required check* na CI +
  vínculo ao diff) é **pendente**. Ver ADR 0006 e
  `.engrama/gaps/auditoria-e-plano-de-remediacao.md`.

### Pendente
- **P2:** `sync-template.sh` (gerar `template/` a partir da raiz canônica) + check de CI —
  elimina o drift raiz↔template e a referência fantasma.
- **P3:** injeção de `{{ENGRAMA_VERSION}}` no `.engrama` instalado.
