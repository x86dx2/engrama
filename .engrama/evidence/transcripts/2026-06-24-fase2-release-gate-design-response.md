---
codex-session: 019efa28-771f-7920-83d0-69a45be633ef
codex-session-source: stream
model: unknown
sandbox: read-only
label: fase2-release-gate-design
---

Vou cumprir o gate do repositório primeiro: ler a governança em ordem, checar o estado factual no topo de `.engrama/log.md`, e só depois fechar o desenho do release-gate sem executar nada.
Papel: Executor Crítico. Alçada: análise read-only e crítica técnica; não executo nem edito nesta ordem. Estado factual: a fatia 1 foi concluída na branch `feat/disciplina-de-release-0.2.0`, o bridge foi endurecido em ADR 0013, e a próxima fatia aprovada pela Autoridade é exatamente o `release-gate` repo-central-only. Próximo passo seguro: inspecionar a superfície distribuível real (`classify()`, `sync-template.sh`, CI, scripts e testes atuais) para fechar a mecânica sem reabrir a decisão. Depende de aprovação da Autoridade: qualquer implementação da fatia 2, qualquer mudança de governança/ADR, e a decisão final sobre pontos onde houver ressalva material.
Agora vou cruzar os pontos onde essa política encosta no código real: gate atual, hash de diff, sync do template, CI da raiz, bootstrap/install e a malha de testes.
Já apareceu um ponto estrutural importante: `sync-template.sh` só sincroniza scripts/settings mecânicos, e o `classify()` da raiz ainda trata `VERSION`, `template/.engrama/VERSION` e `bin/*` como `gate`. Vou agora fechar a superfície distribuível real contra o que o instalador realmente entrega e contra o que a CI já faz hoje.
Fechei o desenho lógico. Vou só pinçar linhas de referência dos arquivos atuais para ancorar as ressalvas finais sem inventar nada fora do estado real do repo.
**A. Mecânica**
- Não usaria o `classify()` atual de [critique-gate.sh](/Users/x86/git-projects/engrama/.engrama/engine/scripts/critique-gate.sh:93) como fonte da superfície de release: ele é amplo demais (`bin/*`, `.engrama/engine/scripts/*.sh`) e conflita com o boundary repo-central-only. A fonte de verdade deve ser um manifest root-only próprio do release gate.
- Ajuste recomendado de path: `bin/release-gate.sh`, não `.engrama/engine/scripts/release-gate.sh`. Motivo: [sync-template.sh](/Users/x86/git-projects/engrama/bin/sync-template.sh:12) já trata `engine/scripts/` como pool distribuível; colocar o gate lá cria vazamento conceitual e falso-positivo. Se a Autoridade insistir no path sob `.engrama/engine/scripts/`, ele precisa ser carve-out explícito do sync e da superfície.
- Superfície exata do payload distribuível: `template/**`; `VERSION`; `.engrama/CLAUDE.md`; `.claude/settings.json`; `.markdownlint-cli2.yaml` (ajuste necessário: hoje ele é sincronizado ao template por `sync-template.sh`); `.engrama/engine/githooks/**`; `.engrama/engine/scripts/{critique-gate.sh,critique-gate-hook.sh,session-context.sh,lint.sh,engrama-diff-hash.sh,exec-bridge.sh,critique-gate-ci.sh}`; `bin/bootstrap.sh`; `bin/install.sh`.
- Metadados/tooling excluídos do payload: `CHANGELOG.md`; arquivo de escape; `bin/sync-template.sh`; o próprio `release-gate.sh` root-only.
- Entrada do script: `release-gate.sh --mode ci|warn [--base-ref <gitish>] [--print-hash]`. `ci` exige `--base-ref`; `warn` tenta autodetectar `origin/HEAD`, depois `origin/main|main|origin/master|master`, e cai para a tag mais recente; sem branch-base nem tag, apenas avisa e sai `0`.
- Referência do diff: CI usa `base-ref...HEAD`, como o gate atual da CI; local `warn` usa a mesma forma `base-ref...HEAD`. Isso é deliberadamente best-effort e HEAD-based; não tenta cobrir working tree cru.
- Detecção de “payload mudou”: parsear `git diff --raw -z`, olhando old-path e new-path; qualquer `A/M/D/R/C` em que um dos lados bata no manifest conta. Não confiar só em glob/pathspec para rename/delete.
- Acoplamento `VERSION ⇄ CHANGELOG`: ler `VERSION` da raiz; exigir em `CHANGELOG.md` exatamente um heading `## [<VERSION>] - YYYY-MM-DD`; exigir também que ele seja o primeiro heading versionado após `## [Não lançado]`.
- Regra de aprovação:
  - `payload_changed=false` e `VERSION` não mudou: passa.
  - `payload_changed=false` e `VERSION` mudou: só passa com `CHANGELOG` válido.
  - `payload_changed=true`: passa com `VERSION` mudado + `CHANGELOG` válido, ou com escape `sem-release` cujo `sha256` bata.
  - Qualquer outro caso: bloqueia em CI; em `warn`, só emite warning.
- Exit codes: `0` passou ou warning-only; `1` erro/configuração inválida; `2` violação de policy em `ci`.

**B. Escape**
- Arquivo root-only: `.engrama/evidence/qa/release-waivers.md`. Não vai para o template.
- Formato exato: `## [YYYY-MM-DD] <contexto> | sem-release | sha256:<64hex> | <motivo>`.
- O match semântico usa só `sem-release` + `sha256`; o `<contexto>` é factual, não normativo.
- O hash cobre só o payload distribuível filtrado pelo manifest, excluindo `VERSION`, `CHANGELOG.md`, o próprio `release-waivers.md` e o `release-gate.sh` root-only.
- Recalcular: `bash ./bin/release-gate.sh --print-hash --base-ref origin/main`.
- Recomendação: reutilizar `engrama-diff-hash.sh`, mas só se ele ganhar flags explícitas de include/exclude/manifest. Não criar um “modo release” implícito nem um segundo hasher independente.

**C. Integração**
- CI da raiz: adicionar um step no job `test` existente em [ci.yml](/Users/x86/git-projects/engrama/.github/workflows/ci.yml:11), restrito a `pull_request` e `matrix.os == 'ubuntu-latest'`, para herdar o required-check já existente sem mexer na branch protection.
- Ordem do job: `fetch base` antes do release-gate; o step roda `bash ./bin/release-gate.sh --mode ci --base-ref "origin/${{ github.base_ref }}"`.
- Local: não tocar no `lint.sh` compartilhado. O uso local é manual/root-only do mesmo script em `--mode warn`; no máximo documentar em `CONTRIBUTING.md`.
- Bootstrap/adotante: nada no template, nada no instalador, nada no hook. O placeholder `template/.engrama/VERSION` continua intocado; o adotante não ganha política de release por osmose.

**D. Matriz de testes**
- `tests/gate/release-gate.test.sh`: payload mudou sem bump nem escape → CI falha.
- `tests/gate/release-gate.test.sh`: payload mudou + bump de `VERSION` + heading correto no `CHANGELOG` → passa.
- `tests/gate/release-gate.test.sh`: payload mudou + `sem-release` com hash válido → passa.
- `tests/gate/release-gate.test.sh`: payload mudou + `sem-release` stale → falha.
- `tests/gate/release-gate.test.sh`: `VERSION` mudou sem heading `## [<VERSION>] - YYYY-MM-DD` → falha.
- `tests/gate/release-gate.test.sh`: PR só com `VERSION` + `CHANGELOG` → passa.
- `tests/gate/release-gate.test.sh`: delete em path do payload conta como mudança.
- `tests/gate/release-gate.test.sh`: rename entrando/saindo do payload conta como mudança.
- `tests/gate/release-gate.test.sh`: local `--mode warn` sem base branch nem tag não quebra; sai `0` com aviso de skip.
- `tests/contract/release-surface.test.sh` ou extensão de `sync.test.sh`: manifest bate com o conjunto realmente sincronizado por `sync-template.sh`, e o release gate root-only não é distribuído.
- Extensão de `bootstrap.test.sh`: projeto adotante continua instalando/bootstrappando sem `release-gate` e sem novo ponto de falha.

**E. ADR 0014**
- Problema: mudanças distribuíveis do pack podem entrar sem bump/release explícito.
- Decisão: gate repo-central-only, CI-blocking em PR, local warning-only.
- Superfície: manifest explícito; payload separado de metadados de release.
- Acoplamento: `VERSION` da raiz exige entry corrente no `CHANGELOG`.
- Escape: `sem-release` bound-by-hash, nunca livre por branch.
- Alternativas rejeitadas: `lint.sh` compartilhado; `sem-release` livre; default local por última tag; hasher separado para release; step novo no template/adotante.

**F. Fatiamento fino**
1. Definir path root-only + manifest + gramática do escape.
Valida: boundary repo-central-only fechado.
2. Generalizar `engrama-diff-hash.sh` com filtros explícitos.
Valida: hash único para CI/local, sem bifurcação perigosa.
3. Implementar `release-gate.sh`.
Valida: lógica de payload, bump, changelog, escape.
4. Plugar o step no job `test` da raiz.
Valida: enforcement vinculante sem nova regra de branch protection.
5. Adicionar suite `release-gate.test.sh` e contratos de superfície/bootstrap.
Valida: deletes/renames/fallbacks/adotante.
6. Autorar ADR 0014 e nota curta de uso local.
Valida: operação não depende de memória informal.

**Crítica fechada**
- `VERSION ⇄ CHANGELOG` fica corretamente root-only; não há caso legítimo para empurrar isso ao `lint.sh` compartilhado nesta fatia.
- Estender `engrama-diff-hash.sh` só “em modo release” sem flags explícitas é erro de desenho; vira divergência invisível com o critique-gate.
- O maior risco de falso-positivo hoje é a superfície ampla demais de [critique-gate.sh](/Users/x86/git-projects/engrama/.engrama/engine/scripts/critique-gate.sh:109); o maior risco de falso-negativo é esquecer que [sync-template.sh](/Users/x86/git-projects/engrama/bin/sync-template.sh:19) também distribui `.markdownlint-cli2.yaml`.
- A disciplina memória-dependente residual fora desta fatia continua sendo prosa raiz↔template que não passa por sync mecânico; o release gate não resolve isso, só torna a mudança release-visível.

**Veredito**
`pronto para FASE 2` — com um ajuste de implementação que eu considero importante: manter o `release-gate` fora da superfície sincronizada (`bin/release-gate.sh` root-only) e usar manifest explícito em vez de reaproveitar `classify()`.
