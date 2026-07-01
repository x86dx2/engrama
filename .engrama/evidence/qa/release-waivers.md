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

## [2026-06-27] feat/workflow-fluxo-operacional — pagina workflow + governa namespace memory/workflows/ | sem-release | sha256:ececf77f10930a19f3dcb6aa6b9abc7e09cf2516268ec0e4febc4e28e22a630b | Mudanca de superficie distribuivel (classify/lint/schema runtime+template passam a governar memory/workflows/) que entra na main mas NAO cuta uma versao isolada — sera bundlada num release deliberado futuro. Decisao da Autoridade 2026-06-27; critica do Executor discordo material (019f0a31) incorporado -> confirmo (019f0a3e)
## [2026-06-30] chore/include-observatory-in-critique-gate-surface | sem-release | sha256:d90df5dd0934baf683dfd6f4deef0e0db09534fa83c585712ed8a85eed69abe9 | Mudanca pequena em superficie distribuivel do pack (`.engrama/engine/scripts/critique-gate.sh`) para tratar `tools/engrama-observatory/**` como `gate`. Entra na main sem corte de `VERSION` isolado e fica bundlada no proximo release deliberado
## [2026-06-30] feat/add-role-runtime-contracts | sem-release | sha256:a6de522698ea2294abbf93f9ab23537ee0375499443d71530b3e317ccfabc772 | Mudanca de superficie distribuivel em runtime, template e contratos normativos por papel. A fatia entra na main sem corte de versao isolado e fica bundlada no proximo release deliberado do pack
