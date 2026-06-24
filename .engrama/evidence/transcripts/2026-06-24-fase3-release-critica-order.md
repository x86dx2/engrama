# ORDEM (CRÍTICA — ADR 0006/gate) — release 0.2.0 (VERSION + CHANGELOG)

**Sandbox READ-ONLY. NÃO execute, NÃO edite, NÃO mova nada.** Crítica independente exigida antes do commit da fatia 3 (`VERSION` é superfície `gate`). Veredito: `confirmo` / `ressalvas <quais>` / `discordo <por quê + gatilho>`.

## Contexto
Fatia 3 do plano de disciplina de release: bump da release 0.2.0. As fatias 1 (bridge-hardening, ADR 0013) e 2 (release-gate, ADR 0014) já estão committadas nesta branch. Esta fatia bumpa `VERSION` e escreve o CHANGELOG.

## O que foi feito (working tree, não-commitado)
1. `VERSION`: `0.1.0` → `0.2.0`.
2. `CHANGELOG.md`: nova entrada `## [0.2.0] - 2026-06-24` (Mudado/Adicionado/Corrigido) + nova `## [Não lançado]` vazia no topo.
3. `CHANGELOG.md`: **restauração do anacronismo** na entrada `## [0.1.0]` — o path-rewrite da reorg (#15) reescreveu paths históricos (`.engrama/scripts/` → `.engrama/engine/scripts/`, `bin/critique-gate-ci.sh` realocado, schema `specs/`/`qa/` → `memory/specs/`/`evidence/qa/`). Restaurei ao texto da tag `v0.1.0`.

## Pontos pra criticar com força
1. **Fidelidade da restauração 0.1.0:** a entrada `## [0.1.0]` no working tree bate **exatamente** com `git show v0.1.0:CHANGELOG.md`? Sobrou algum anacronismo (path pós-reorg) na seção 0.1.0? Confira com `git show v0.1.0:CHANGELOG.md`.
2. **Precisão da entrada 0.2.0:** ela documenta com honestidade o que mudou desde 0.1.0 (#14 consolidação + endurecimento do bridge; #15 reorg memory/engine/evidence; fatia 1 = ADR 0013 bridge version-drift; fatia 2 = ADR 0014 release-gate)? Falta algo material? Algum overclaim (princ. 12)?
3. **SemVer 0.x:** minor bump (0.1.0 → 0.2.0) é apropriado para esse conjunto (features novas + fixes, sem release estável)? Ou caberia outro?
4. **Dogfood do release-gate:** com `VERSION=0.2.0` + entrada `## [0.2.0] - 2026-06-24` como primeiro heading versionado após `## [Não lançado]`, o `bin/release-gate.sh --mode ci --base-ref main` (main...HEAD, após o commit) deve **aprovar** (payload mudou + bump + CHANGELOG válido)? Confira a lógica do gate contra o estado.
5. Qualquer coisa imprópria para a release.

## Saída
Leitura + crítica + **veredito**. Se `discordo` material, eu levo à Autoridade. NÃO execute.
