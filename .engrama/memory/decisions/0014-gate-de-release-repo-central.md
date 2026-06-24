---
type: decision
status: active
touches: [memory/decisions/0011-diff-binding-atestacao-verificavel, memory/decisions/0006-governanca-nao-se-autoaprova, memory/decisions/0005-orquestrador-qa-reexecucao-e-metricas, memory/specs/licao-aprendida]
date: 2026-06-24
source_refs:
  - bin/release-gate.sh
  - .engrama/release-surface.manifest
  - .engrama/engine/scripts/engrama-diff-hash.sh
  - .github/workflows/ci.yml
  - tests/gate/release-gate.test.sh
  - tests/contract/release-surface.test.sh
reconcilia: ADD
---

**Toda mudança na superfície distribuível do pack tem de resultar em bump de `VERSION` + entrada de `CHANGELOG` correspondente, OU numa decisão consciente "sem release" vinculada ao diff por hash.** O freio é mecânico (a CI derruba o job `test`; vira bloqueio de merge se `test` for required-check), não memória — porque a disciplina por memória já falhou na prática.

## Contexto

Duas fatias estruturais (PR #14 consolidação, PR #15 reorg) subiram **sem bump de `VERSION` nem `CHANGELOG`**: o repo seguia em `0.1.0` com mudanças não-lançadas acumuladas. A disciplina de release dependia só de memória — não havia gate/lint/CI acoplando "mudou o que o adotante recebe" a "registrou a release". É o mesmo anti-padrão que o projeto existe para matar (modelo-operacional princ. 1 e 7; o próprio critique-gate nasceu de um lapso análogo — ver [[memory/specs/licao-aprendida]]). A correção definitiva é mecânica.

## Decisão

1. **`bin/release-gate.sh` root-only.** Fica em `bin/` (source-only, não distribuído além de `bootstrap.sh`/`install.sh`), **não** sob `.engrama/engine/scripts/` — esse diretório é pool sincronizado ao template por `sync-template.sh`, e o gate lá vazaria a política de release para o adotante. A fonte da superfície é um **manifest explícito** (`.engrama/release-surface.manifest`), **não** o `classify()` do critique-gate (que é amplo demais e tem outro propósito).
2. **CI que derruba o job `test`; local best-effort.** Um step no job `test` do `.github/workflows/ci.yml` (restrito a `pull_request` + `ubuntu-latest`) roda `release-gate.sh --mode ci --base-ref origin/<base>` e **falha o job** (exit 2 em violação). Isso **só bloqueia o merge se `test` for required-check** na branch protection — estado externo ao repo (a mesma borda honesta do [[memory/decisions/0006-governanca-nao-se-autoaprova]]); o pack não mexe em branch protection. Local = `--mode warn`, **não-bloqueante** (mid-trabalho a versão ainda não foi decidida).
3. **Referência do diff.** CI: `base-ref...HEAD`. Local `warn`: autodetecta `origin/HEAD` → `main`/`master` → tag mais recente → se nada, avisa e sai `0`. **Não** usa "última tag" como default agressivo (dispararia em toda branch nova por unreleased acumulado).
4. **Acoplamento `VERSION ⇄ CHANGELOG` root-only.** O gate exige, quando o payload muda, um heading `## [<VERSION>] - YYYY-MM-DD` no `CHANGELOG.md` como primeiro versionado após `## [Não lançado]`. Essa checagem **não** entra no `lint.sh` compartilhado (que é sincronizado ao template).
5. **Escape bound-by-hash.** A decisão consciente "sem release" mora em `.engrama/evidence/qa/release-waivers.md` (root-only), linha `## [data] <ctx> | sem-release | sha256:<hex> | <motivo>`. O hash cobre **só o payload** (exclui `VERSION`, `CHANGELOG.md`, o próprio waiver e o gate), e é calculado pelas flags **opt-in** do `engrama-diff-hash.sh` (`--manifest`/`--include`/`--exclude`). Não é um `sem-release` livre (que abençoaria PRs futuros — o mesmo furo que o [[memory/decisions/0011-diff-binding-atestacao-verificavel]] fechou).

## Alternativas consideradas

- **Acoplar no `lint.sh` compartilhado.** Rejeitada: empurraria a política de release do repo central para todo projeto adotante (o `lint.sh` é sincronizado ao template).
- **`sem-release` como linha livre no CHANGELOG.** Rejeitada: liberaria qualquer diff futuro da mesma branch até a próxima release — o anti-padrão que o diff-binding (0011) já matou.
- **Default local = última tag.** Rejeitada: `git describe` resolve para algo como `v0.1.0-N-g...-dirty`, disparando warning em toda branch nova mesmo sem tocar a superfície.
- **Hasher separado para release.** Rejeitada: criaria divergência invisível com o critique-gate. Em vez disso, o `engrama-diff-hash.sh` ganhou filtros **opt-in** — o caminho default permanece bit-a-bit idêntico para o critique-gate (provado por `D10`/`D11` em `tests/gate/diffbind.test.sh`).
- **Step no template/adotante.** Rejeitada nesta fatia: o adotante não deve herdar a política de release do pack por osmose (vira decisão separada — ver Consequências).

## Consequências

- Mudança distribuível não fecha sem **decisão consciente de versão** (bump + CHANGELOG, ou waiver vinculado por hash).
- O `engrama-diff-hash.sh` passa a ter filtro de superfície opt-in, **compartilhado** entre critique-gate (default, sem flags) e release-gate (filtrado). A **backward-compat do default é invariante permanente** (teste `D10`/`D11`).
- **Obrigação operacional:** quando a superfície distribuível mudar (novo arquivo sincronizado ao template, novo entrypoint), o `.engrama/release-surface.manifest` deve ser **mantido em sincronia** — `tests/contract/release-surface.test.sh` (RS1) falha se o manifest divergir do conjunto realmente sincronizado por `sync-template.sh`.
- **A própria branch `feat/disciplina-de-release-0.2.0`:** o payload mudou (fatias 1–2), então em CI o gate derrubaria o job `test` até o bump `0.2.0` — esperado; o bump é a fatia 3 (com data real, não retroativa).
- **Disciplina de release no template/adotante fica FORA** desta fatia (fatia 4 / decisão separada da Autoridade): ou vira contrato novo do pack, ou não entra.
- **Resíduo conhecido (fora de escopo):** o espelhamento de **prosa** raiz↔template não passa por sync mecânico; o release-gate torna mudanças de pack release-visíveis, mas não sincroniza prosa.

## Status

Ativo. `reconcilia: ADD` — introduz o gate de release; complementa o critique-gate/diff-binding ([[memory/decisions/0011-diff-binding-atestacao-verificavel]]) reusando o mesmo hasher, sem alterar o caminho default dele.
