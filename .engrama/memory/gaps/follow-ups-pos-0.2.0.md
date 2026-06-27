---
type: gap
status: proposed
critica_tecnica: confirmada
touches: [memory/decisions/0014-gate-de-release-repo-central, memory/decisions/0006-governanca-nao-se-autoaprova]
date: 2026-06-27
source_refs:
  - bin/release-gate.sh
  - engrama.values.example
  - docs/INSTANTIATE.md
  - VERSION
---

Ressalvas não-bloqueantes levantadas pela crítica do Executor sobre o diff agregado do PR #16 (release 0.2.0; codex-session `019f0995`, veredito `ressalvas`). Dispositadas como follow-up: **não reabrem o release 0.2.0** (corrigir reabriria o diff agregado e exigiria nova crítica+re-bind). Endereçar em fatia separada após a tag `v0.2.0`.

## Ressalvas

1. **`bin/release-gate.sh` — parser de waiver usa heredoc/tempfile.** Em sandbox read-only sem `/tmp` gravável, o `--mode ci` emite `cannot create temp file for here document` (ainda sai `0`; a CI normal tem `/tmp`). Robustez: o parser de waiver deveria evitar heredoc/tempfile, ou pular a leitura de waiver quando `VERSION`+`CHANGELOG` já validam a release. Não-bloqueante.

2. **`engrama.values.example` + `docs/INSTANTIATE.md` mostram `ENGRAMA_VERSION=0.1.0`.** O `VERSION` da raiz é `0.2.0` e o caminho automático de instanciação lê o arquivo `VERSION` (correto — `docs/INSTALL.md` aponta `cat .../VERSION`). Mas copiar o `engrama.values.example` como override fixaria a versão velha. Atualizar os literais de exemplo para `0.2.0` (ou parametrizar). Ressalva documental, não-bloqueante.

## Estado

Crítica do Executor: **confirmada** (ambas reconhecidas como reais e não-bloqueantes na crítica do agregado). Ação: deferida para pós-`v0.2.0`. Ver [[memory/decisions/0014-gate-de-release-repo-central]].
