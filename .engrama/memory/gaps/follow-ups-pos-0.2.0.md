---
type: gap
status: active
critica_tecnica: confirmada
touches: [memory/decisions/0014-gate-de-release-repo-central, memory/decisions/0006-governanca-nao-se-autoaprova]
date: 2026-06-30
source_refs:
  - bin/release-gate.sh
  - tests/gate/release-gate.test.sh
  - engrama.values.example
  - docs/INSTANTIATE.md
  - VERSION
---

Ressalvas não-bloqueantes levantadas pela crítica do Executor sobre o diff agregado do PR #16 (release 0.2.0; codex-session `019f0995`, veredito `ressalvas`). Foram dispositadas como follow-up para **não reabrir o release 0.2.0** e ficaram abertas até a release `v0.3.0`.

## Fechamento desta fatia (2026-06-30)

As duas ressalvas foram fechadas na branch `fix/follow-ups-pos-0.2.0`:

1. **`bin/release-gate.sh` — parser de waiver sem heredoc/here-string/tempfile.** `has_valid_release_waiver` agora separa os campos `|` por expansão de shell, preservando a gramática `## [data] contexto | sem-release | sha256:<64hex> | motivo` sem depender de artefato temporário. `tests/gate/release-gate.test.sh` ganhou regressão estrutural para impedir retorno de heredoc/here-string/tempfile no parser, e os casos funcionais de waiver válido/stale seguem cobrindo o comportamento.
2. **`engrama.values.example` + `docs/INSTANTIATE.md` alinhados ao `VERSION` atual.** Os exemplos de `ENGRAMA_VERSION` agora apontam para `0.3.0`, e a documentação mantém explícito que o valor correto deve ser derivado de `VERSION` no pack-fonte.

## Ressalvas originais

1. **`bin/release-gate.sh` — parser de waiver usa heredoc/tempfile.** Em sandbox read-only sem `/tmp` gravável, o `--mode ci` emite `cannot create temp file for here document` (ainda sai `0`; a CI normal tem `/tmp`). Robustez: o parser de waiver deveria evitar heredoc/tempfile, ou pular a leitura de waiver quando `VERSION`+`CHANGELOG` já validam a release. Não-bloqueante.

2. **`engrama.values.example` + `docs/INSTANTIATE.md` mostram `ENGRAMA_VERSION=0.1.0`.** O `VERSION` da raiz é `0.2.0` e o caminho automático de instanciação lê o arquivo `VERSION` (correto — `docs/INSTALL.md` aponta `cat .../VERSION`). Mas copiar o `engrama.values.example` como override fixaria a versão velha. Atualizar os literais de exemplo para `0.2.0` (ou parametrizar). Ressalva documental, não-bloqueante.

## Estado

Crítica do Executor: **confirmada** (ambas reconhecidas como reais e não-bloqueantes na crítica do agregado). Estado atual: **fechado** nesta fatia pós-`v0.3.0`. Ver [[memory/decisions/0014-gate-de-release-repo-central]].
