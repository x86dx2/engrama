# ORDEM (FASE 2 — DESIGN FECHADO, READ-ONLY) — release-gate repo-central-only

**Sandbox READ-ONLY. NÃO execute, NÃO edite, NÃO mova nada.** Produza o **desenho fechado e acionável** da fatia 2 (o gate de release), em formato de **ordem operacional + matriz de casos de teste**, para a Autoridade revisar antes da execução. Cace furos residuais. Veredito ao final.

## Contexto
A FASE 1 (sua crítica, codex-session `019efa1a`/`019ef9f9`) deu `discordo` no plano original e a **Autoridade aceitou seu redesenho integral**. Esta fatia 2 implementa SÓ o **gate de release repo-central-only**. A fatia 1 (bridge-hardening) já foi committada (ADR 0013). Fatia 3 = release 0.2.0 (usa o gate); fatia 4 = disciplina-no-template (decisão separada da Autoridade) — **fora desta ordem**.

## Direção já aprovada (não reabrir, só fechar o "como")
1. **Gate repo-central-only:** um `release-gate.sh` próprio (ex.: `.engrama/engine/scripts/release-gate.sh`), chamado pela **CI do repo central**. **NÃO** acoplar a política de release ao `lint.sh` compartilhado (ele é sincronizado ao template e empurraria release para o adotante).
2. **CI vinculante; local best-effort:** CI **bloqueia** (step no `ci.yml` da raiz); local = **WARNING** não-bloqueante (a versão ainda não foi decidida mid-trabalho).
3. **Referência do diff:** local = **`merge-base` com a branch base** (tag como fallback quando não houver upstream); CI = **base-ref do PR** (como o critique-gate-ci). Nada de "última tag" como default local (dispara em toda branch nova por unreleased acumulado).
4. **Escape bound-by-hash:** decisão consciente "sem release" é **vinculada ao diff por `sha256`** sobre a **superfície de release** (excluindo os próprios metadados de release: VERSION/CHANGELOG/ledger), espelhando ADR 0011 e reusando/estendendo `engrama-diff-hash.sh`. **NÃO** um `sem-release:` livre que abençoa PRs futuros.
5. **Superfície distribuível (feche a lista exata):** inclui `template/**`, `VERSION`, `.engrama/engine/scripts/**`, `.engrama/CLAUDE.md` (schema), **`.engrama/engine/githooks/**`**, **`.claude/settings.json`**; e de `bin/` só **`bin/bootstrap.sh` + `bin/install.sh`** (exclui `bin/sync-template.sh` = tooling de mantenedor). Confirme/ajuste contra `classify()` e `sync-template.sh`.
6. **Data real no 0.2.0** (fatia 3): não retroagir para 2026-06-22.

## O que entregar (desenho fechado)
A. **Mecânica exata do `release-gate.sh`:** entradas (ref local vs CI), como detecta "superfície mudou", onde lê VERSION e o CHANGELOG, como valida o acoplamento **VERSION ⇄ entrada `## [<VERSION>]` no CHANGELOG** (decida: isso fica no `release-gate.sh` root-only, certo? confirme que NÃO vai pro lint.sh compartilhado), e como o escape `sha256` é conferido. Pseudocódigo/contrato de E/S, exit codes.
B. **Formato exato do escape** (onde mora, sintaxe, o que o hash cobre, como recalcular). Reuso do `engrama-diff-hash.sh` com filtro de superfície vs script novo — recomende.
C. **Pontos de integração:** `ci.yml` da raiz (step novo, vinculante); WARNING local (onde plugar — `lint.sh`? um wrapper? sem acoplar política ao lint compartilhado). Garantir que **bootstrap/instalação do adotante NÃO quebra** (lá o VERSION vem de placeholder).
D. **Matriz de testes** (`tests/`): superfície mudou sem bump → CI falha; bump+CHANGELOG → passa; escape `sha256` válido → passa; escape stale (hash não bate) → falha; VERSION sem entrada CHANGELOG → falha; release-only PR (só VERSION+CHANGELOG) → passa; delete/rename na superfície conta; fallback sem tag/upstream não quebra; **bootstrap do adotante não passa a falhar pelo gate**.
E. **ADR 0014** (gate de release: decisão + alternativas CI-block vs lint-only, escape bound-vs-livre, repo-central vs template) — esboço de pontos, eu autoro depois. **ADR 0015** (reorg retroativa do #15) fica para outra fatia, não aqui.
F. **Fatiamento fino da execução** da fatia 2 (sub-passos verificáveis) e o que cada um valida.

## Pontos pra criticar com força
1. O acoplamento VERSION⇄CHANGELOG: `release-gate.sh` root-only resolve sem vazar pro template? Há caso em que o lint compartilhado precisaria saber disso?
2. O `engrama-diff-hash.sh` hoje exclui o ledger; estendê-lo para excluir TAMBÉM VERSION/CHANGELOG só no modo "release" cria divergência perigosa com o uso do critique-gate? Melhor um flag/segundo entrypoint?
3. Falsos-positivos/negativos na detecção de superfície (globs, rename, paths novos).
4. Qualquer disciplina memória-dependente adicional que você veja (além de release e do espelhamento de prosa raiz↔template que você já citou na FASE 1).

## Saída
Desenho fechado (A–F) + **veredito** (`pronto para FASE 2` | `ressalvas <quais>` | `bloqueio <por quê>`). NÃO execute — só desenhe e critique.
