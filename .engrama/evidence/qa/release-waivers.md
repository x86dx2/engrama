---
type: workflow
status: active
touches: [bin/release-gate.sh]
date: 2026-06-24
source_refs:
  - bin/release-gate.sh
  - .engrama/release-surface.manifest
---

# Release waivers

Entradas append-only do escape `sem-release` do release-gate root-only.

Formato:

```
## [YYYY-MM-DD] <contexto> | sem-release | sha256:<64hex> | <motivo>
```

Recalcule o hash com:

```
bash ./bin/release-gate.sh --print-hash --base-ref origin/<base>   # ex.: origin/main
```

## [2026-06-30] docs/runtime-usage-gateways — gateways documentam runtime roteado + usage ledger | sem-release | sha256:e297a2d24ca2f1695d19b8f20bddd16c03cde16f226d6760e8cf02559a5547e8 | Mudanca documental no payload distribuivel do PR (inclui `.engrama/CLAUDE.md`) sem alteracao funcional e sem release isolada; sera bundlada em release deliberada futura. Decisao da Autoridade 2026-06-30; PR #23

## [2026-06-27] feat/workflow-fluxo-operacional — pagina workflow + governa namespace memory/workflows/ | sem-release | sha256:ececf77f10930a19f3dcb6aa6b9abc7e09cf2516268ec0e4febc4e28e22a630b | Mudanca de superficie distribuivel (classify/lint/schema runtime+template passam a governar memory/workflows/) que entra na main mas NAO cuta uma versao isolada — sera bundlada num release deliberado futuro. Decisao da Autoridade 2026-06-27; critica do Executor discordo material (019f0a31) incorporado -> confirmo (019f0a3e)
