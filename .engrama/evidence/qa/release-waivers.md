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
