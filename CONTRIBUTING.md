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

Validações locais:

- `bash tests/run.sh`
- `bash ./.engrama/engine/scripts/lint.sh`
