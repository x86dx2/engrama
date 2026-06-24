# ORDEM (CRÍTICA DE GOVERNANÇA — ADR 0006) — ADR 0014 + nota CONTRIBUTING do release-gate

**Sandbox READ-ONLY. NÃO execute, NÃO edite, NÃO mova nada.** Crítica independente exigida pelo ADR 0006 ANTES do commit da fatia 2. Veredito: `confirmo` / `ressalvas <quais>` / `discordo <por quê + gatilho>`.

## Contexto
Você implementou a fatia 2 (release-gate, codex-session `019efa34`, `ajuste-menor`) conforme o desenho que você fechou. O Orquestrador auditou (suíte verde: D10/D11 backward-compat bit-a-bit, release-gate 11/11, release-surface 4/4, sync 21; critique-gate exit 0; escopo sem VERSION/CHANGELOG). Agora autorou a GOVERNANÇA da fatia. Critique só os documentos.

## Arquivos a criticar (leia no repo)
1. `.engrama/memory/decisions/0014-gate-de-release-repo-central.md` (NOVO ADR).
2. Seção "Disciplina de release" nova em `CONTRIBUTING.md`.
3. Linha nova em `.engrama/index.md` (catálogo do 0014).
Cruze com o código real: `bin/release-gate.sh`, `.engrama/release-surface.manifest`, `.engrama/engine/scripts/engrama-diff-hash.sh`, `.github/workflows/ci.yml`, `tests/gate/release-gate.test.sh`, `tests/contract/release-surface.test.sh`.

## Pontos pra criticar com força
1. **Honestidade (princ. 12):** o ADR 0014 promete algo que o código NÃO entrega? Em especial: (a) "CI vinculante / bloqueia" — o step de fato bloqueia o required-check? (b) "backward-compat bit-a-bit do hasher" — D10/D11 provam isso de verdade? (c) "repo-central-only / não vaza ao adotante" — RS1–RS4 sustentam? (d) o acoplamento VERSION⇄CHANGELOG está mesmo root-only?
2. **Coerência:** 0014 contradiz/sobrepõe mal o 0011 (diff-binding), 0006 (gate), 0013 (bridge) ou o critique-gate? O `reconcilia: ADD` é correto, ou deveria ser `UPDATE 0011`?
3. **Completude:** alternativas rejeitadas e consequências estão justas? Falta registrar alguma (ex.: a obrigação de manter o manifest em sincronia quando a superfície distribuível mudar; o caso da própria branch que bloquearia em CI até a fatia 3)?
4. **CONTRIBUTING:** a nota está fiel ao comportamento real do gate (modos ci/warn, escape, recalcular hash)? Algum comando errado?
5. Qualquer coisa imprópria para a memória institucional versionada.

## Saída
Leitura + crítica técnica + **veredito**. Se `discordo` material, eu levo à Autoridade (sem overrule). NÃO execute.
