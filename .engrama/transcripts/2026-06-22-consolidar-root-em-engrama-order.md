# ORDEM — consolidar raiz em .engrama/ (escopo A+B)

Você é o **Executor Crítico** (codex exec). Leia criticamente ANTES de executar; se discordar
materialmente (4 gatilhos), NÃO execute e devolva objeção. Caso contrário, execute e devolva os
6 itens da resposta mínima (leitura · crítica · veredito · execução · evidências · pendências).

## 1) Objetivo da fatia

Consolidar a raiz do pack movendo DOIS itens "do engrama" para dentro de `.engrama/`, atualizando
TODAS as referências ativas, mantendo suíte/lint/sync/shellcheck/markdownlint verdes e o template
em paridade raiz↔template. Motivação: a raiz do adotante hoje mostra `bin/` e `transcripts/` como
ruído; ambos são internos do engrama e devem morar sob `.engrama/`.

ESCOPO APROVADO PELA AUTORIDADE = **A + B apenas**. O `.markdownlint-cli2.yaml` **NÃO se move**
(decisão da Autoridade: é config de projeto, e mover o glob `**/*.md` arriscaria parar de lintar
README/docs). Você só ATUALIZA o `ignores:` dele (ver Parte B).

## 2) Estado factual conhecido

- Repo `engrama`: instância viva + template distribuível. Branch nova `feat/consolidar-root-em-engrama`
  a partir de `b3926c5`, limpa.
- `classify()` do gate ativa as categorias `governance · gate · contract`. A CI roda diff-binding em
  **modo estrito** (`ENGRAMA_REQUIRE_DIFF_BIND=1`).
- `template/bin/` contém **apenas** `critique-gate-ci.sh`. `template/transcripts/` contém **apenas** `README.md`.
- O `lint.sh` varre `.engrama/**/*.md` (linha ~117, `find .engrama -type f -name '*.md'`) para extrair
  wikilinks — hoje os transcripts ficam FORA de `.engrama/`, por isso não são varridos.
- O `exec-bridge.sh` grava o transcript da invocação ATUAL em `transcripts/` (raiz) — ver fronteira em §4.

## 3) Escopo da execução

### Parte A — `bin/critique-gate-ci.sh` → `.engrama/scripts/critique-gate-ci.sh`
- Mover (git mv preferido) na RAIZ: `bin/critique-gate-ci.sh` → `.engrama/scripts/critique-gate-ci.sh`.
- Mover no TEMPLATE: `template/bin/critique-gate-ci.sh` → `template/.engrama/scripts/critique-gate-ci.sh`.
  Como era o único arquivo, `template/bin/` deve **deixar de existir**.
- Atualizar TODAS as referências ativas ao path antigo. Comece por estas e complete com grep próprio
  (`grep -rn 'bin/critique-gate-ci' .` e `grep -rn 'critique-gate-ci' .`):
  - `.github/workflows/ci.yml` (raiz): `bash ./bin/critique-gate-ci.sh …` e o `shellcheck … bin/critique-gate-ci.sh`.
  - `template/.github/workflows/ci.yml`: idem.
  - `bin/sync-template.sh`: qualquer path/asserção de paridade do gate-CI (provável hardcode).
  - `bin/install.sh`: o `run_integrity_smoke()` lista `"$root/bin/critique-gate-ci.sh"` → novo path.
  - `.engrama/scripts/critique-gate.sh`: comentário que cita `critique-gate-ci.sh` (sem path — revisar texto).
  - `tests/contract/sync.test.sh`, `tests/gate/ci.test.sh`: paths esperados.
  - Docs/prosa: `README.md` (árvores ASCII + links), `docs/INSTALL.md`, `docs/INSTANTIATE.md`,
    `CHANGELOG.md`, `.engrama/decisions/0006-governanca-nao-se-autoaprova.md` (raiz e template).
- Confirme que o destino continua classificado como `gate`: `.engrama/scripts/*.sh` (raiz) e
  `template/.engrama/scripts/*.sh` (template) já caem em `gate` no `classify()`. Não deixe o gate-CI órfão de categoria.

### Parte B — `transcripts/` → `.engrama/transcripts/`
Você edita o CÓDIGO e as referências; o diretório `transcripts/` VIVO DA RAIZ é movido pelo
ORQUESTRADOR pós-run (ver §4). Faça:
- `.engrama/scripts/exec-bridge.sh` (raiz): `TRANSCRIPTS_DIR="$REPO_ROOT/transcripts"` →
  `"$REPO_ROOT/.engrama/transcripts"`; e os prefixos `order_rel="transcripts/…"` /
  `response_rel="transcripts/…"` → `.engrama/transcripts/…`.
- `template/.engrama/scripts/exec-bridge.sh`: idem.
- `.engrama/scripts/lint.sh` (raiz) **e** `template/.engrama/scripts/lint.sh`: EXCLUIR `.engrama/transcripts/`
  da varredura `find .engrama -type f -name '*.md'` (use `-path './.engrama/transcripts/*' -prune -o … -print`
  ou filtro equivalente robusto). Sem isso, wikilinks `[[…]]` verbatim dentro dos transcripts viram
  "links quebrados" e o lint quebra.
- `.markdownlint-cli2.yaml` (raiz) **e** `template/.markdownlint-cli2.yaml`: trocar no `ignores:`
  `transcripts` → `.engrama/transcripts` e `template/transcripts` → `template/.engrama/transcripts`.
- Mover (git mv) `template/transcripts/README.md` → `template/.engrama/transcripts/README.md` e corrigir
  o link interno relativo dentro dele (era `../.engrama/qa/…`; agora o irmão é `../qa/…`).
  `template/transcripts/` deve deixar de existir.
- Prosa/refs ativas: `.engrama/decisions/0003-executor-bridge-orquestrador-invoca-executor.md` (raiz+template),
  `docs/INSTANTIATE.md`, e qualquer outra ref ativa a `transcripts/` que o grep encontrar
  (`grep -rn 'transcripts/' .`). Atualizar para `.engrama/transcripts/`.
- Tests: `tests/contract/exec-bridge.test.sh`, `tests/contract/bootstrap.test.sh` — paths esperados → `.engrama/transcripts/`.

## 4) Restrições e fronteiras (o que NÃO tocar)

- **NÃO mova, delete ou edite o diretório `transcripts/` DA RAIZ nem seu conteúdo** (inclui o
  `transcripts/README.md` da raiz e os transcripts históricos). Motivo: o `exec-bridge.sh` grava o
  transcript DESTA invocação em `transcripts/` durante a execução — se você mover esse diretório no meio
  da run, racha o próprio par ordem/resposta. O Orquestrador realoca o histórico da raiz DEPOIS da run.
- **NÃO edite o conteúdo de transcripts históricos** (verbatim/append-only) — nem raiz nem template.
- **NÃO edite entradas históricas** de `.engrama/log.md` nem do ledger `.engrama/qa/criticas-do-executor.md`
  (são append-only; quem cita `transcripts/`/`bin/critique-gate-ci.sh` em registros passados fica como está).
- **NÃO mova `.markdownlint-cli2.yaml`** (só edita o `ignores:`).
- **NÃO** rode `git commit`, `git config`, `git push`, nem altere a identidade git ou config do repo real.
  `git mv`/edição no working tree da fatia é permitido. Se precisar de smoke de bootstrap/instalador,
  rode SÓ em `mktemp` com `git -C` (regra pós-incidente; nunca no repo real).
- Não introduza dependências novas; mantenha shell portátil (o shellcheck do CI é `-S info`).

## 5) Critérios de aceite

1. `bin/critique-gate-ci.sh`, `template/bin/`, `template/transcripts/` **não existem mais**; arquivos em
   `.engrama/scripts/critique-gate-ci.sh`, `template/.engrama/scripts/critique-gate-ci.sh`,
   `template/.engrama/transcripts/README.md`.
2. `exec-bridge.sh` (raiz+template) gravam futuros transcripts em `.engrama/transcripts/`.
3. `lint.sh` (raiz+template) exclui `.engrama/transcripts/` da varredura.
4. `.markdownlint-cli2.yaml` (raiz+template) ignora `.engrama/transcripts` e `template/.engrama/transcripts`.
5. ZERO referência ativa quebrada a `bin/critique-gate-ci.sh` ou a `transcripts/` (exceto verbatim
   histórico e entradas históricas de log/ledger, intocados).
6. Paridade raiz↔template preservada.

## 6) Validações esperadas (rode e cole a saída real)

- `bash ./tests/run.sh`  (suíte completa)
- `bash ./.engrama/scripts/lint.sh; echo "lint exit=$?"`
- `bash ./bin/sync-template.sh && bash ./bin/sync-template.sh`  (idempotente; 2ª vez sem mudança)
- `bash ./tests/contract/sync.test.sh`
- `shellcheck -S info` nos `.sh` que você tocou
- grep provando zero refs ativas quebradas: `grep -rn 'bin/critique-gate-ci' . | grep -v '\.git/'` e
  `grep -rn '(^|[^.])transcripts/' .` revisados (sobram só verbatim/histórico)

## 7) Riscos já conhecidos

- **Self-write do transcript desta run** → tratado pela fronteira §4 (Orquestrador move o histórico da raiz).
- **`lint.sh` varre `.engrama/**`** → exclusão obrigatória de `.engrama/transcripts/` (Parte B).
- **`template/bin/` órfão** → conferir que nenhum gerador/sync recria `template/bin/`; se `sync-template.sh`
  cria o dir, ajuste-o.
- **`sync-template.sh` com path do gate-CI hardcoded** → atualizar, senão o drift test quebra.
- **classify()** → garantir gate-CI ainda `gate` no destino.

## 8) O que depende de aprovação da Autoridade

- Apenas o merge do PR (branch protection server-side). O escopo A+B já foi aprovado. Nada mais pendente.

## 9) Próximo passo seguro após a execução

O Orquestrador: re-roda os gates (auditoria ADR 0005); realoca `transcripts/` da raiz →
`.engrama/transcripts/` (incl. o par desta run) e ajusta o README da raiz; registra a crítica no ledger
(sha256 forte + codex-session); loga; comita; abre PR para a Autoridade.

## 10) Modelo/tier

`codex exec` no default do adaptador (as runs anteriores rodaram sem `--model` explícito), sandbox
`workspace-write`. Effort alto: refactor mecânico amplo, multi-arquivo, com paridade e gates — exige
rastreio cuidadoso de referências, não criatividade.
