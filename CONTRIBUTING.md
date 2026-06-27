# Contributing

Fluxo de contribuição:

1. Abra uma branch para a fatia.
2. Envie a mudança via PR.
3. Prefira squash/1 commit por PR: o diff-binding ata o `sha256` do diff cumulativo do PR; multi-commit segue válido, mas o fingerprint cobre o conjunto, não cada commit.
4. Mantenha a CI verde antes do merge.
5. Faça o merge só depois da auditoria e do veredito do Orquestrador.

ADRs: os arquivos `0001-0011` que já vêm no pack documentam o framework de governança; os ADRs do seu projeto começam em `0012-...`.

Resumo de governança:

- O Executor Crítico critica a ordem antes de qualquer commit de código.
- O gate exige registro de crítica para superfícies sensíveis.
- O Orquestrador audita e reexecuta os gates antes de aceitar a mudança.

Disciplina de release (gate mecânico — ADR 0014):

- Mudou a **superfície distribuível** do pack (ver `.engrama/release-surface.manifest`)? Então o PR precisa **ou** bumpar `VERSION` + adicionar a entrada `## [<VERSION>] - YYYY-MM-DD` no `CHANGELOG.md`, **ou** registrar um waiver consciente em `.engrama/evidence/qa/release-waivers.md` (`sem-release` vinculado por `sha256` ao payload).
- A CI roda `bin/release-gate.sh --mode ci` e **derruba o job `test`** se a superfície mudou sem release nem waiver — o que **bloqueia o merge se `test` for required-check** na branch protection. Localmente, `bash ./bin/release-gate.sh --mode warn` só **avisa** (não bloqueia). Recalcular o hash do waiver: `bash ./bin/release-gate.sh --print-hash --base-ref origin/<base>` (ex.: `origin/main`).
- O gate é **repo-central-only**: o projeto adotante não herda essa política (não vai no template).

Validações locais:

- `bash tests/run.sh`
- `bash ./.engrama/engine/scripts/lint.sh`
- `bash ./bin/release-gate.sh --mode warn` (aviso de release pendente, não-bloqueante)
