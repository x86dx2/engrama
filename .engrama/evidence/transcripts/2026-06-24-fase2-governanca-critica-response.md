---
codex-session: 019efa4c-9b4a-7cd2-b164-7de21754ceaf
codex-session-source: stream
model: unknown
sandbox: read-only
label: fase2-governanca-critica
---

Vou abrir primeiro o gate obrigatório do Engrama na ordem prescrita e, em seguida, ler o ADR 0014, a nota do `CONTRIBUTING.md` e o catálogo em `.engrama/index.md`, cruzando tudo com o código e os testes citados.
Papel assumido: `Executor Crítico`. Alçada: leitura e crítica independente de governança em modo `read-only`, sem executar mutações nem editar nada. Estado factual no topo de `.engrama/log.md`: branch `feat/disciplina-de-release-0.2.0`, fatia 1 concluída e auditada; o plano registrado é commitar a fatia 1 e então seguir para a fatia 2 do `release-gate repo-central-only`. Próximo passo seguro: ler o ADR 0014, a nota de `CONTRIBUTING.md`, a linha de catálogo e confrontar isso com `release-gate`, workflow e testes. O que depende de aprovação da Autoridade: qualquer discordância material minha sobre a governança autorada agora.
Já li o núcleo. Agora vou fechar os pontos de honestidade e coerência lendo o restante do `release-gate.sh`, a seção exata do `CONTRIBUTING.md` e os ADRs 0006, 0011 e 0013 para checar sobreposição e claims.
Vou conferir os casos `D10`/`D11` do hasher e procurar qualquer vazamento do release-gate para o template, porque esses dois pontos são os mais fáceis de overclaimar na ADR.
Fechando as referências de linha para emitir a crítica com precisão. Vou numerar o ADR, a nota do `CONTRIBUTING`, o workflow e os testes que sustentam ou não cada claim.
Falta só a linha de catálogo e, se necessário, o arquivo de waivers para checar se a memória institucional está bem ancorada.
Quero fechar a nuance do ponto `D10`/`D11` com a implementação do hasher, para não criticar uma garantia que o código de fato preserva por construção.
**Leitura**

Li o gate obrigatório, assumi a alçada de `Executor Crítico` em `read-only`, e cruzei os documentos pedidos com o código real e os testes. Não executei mutação nenhuma.

**Crítica Técnica**

- `Ressalva 1: overclaim de enforcement vinculante.` O texto do [ADR 0014](/Users/x86/git-projects/engrama/.engrama/memory/decisions/0014-gate-de-release-repo-central.md:24), do [CONTRIBUTING](/Users/x86/git-projects/engrama/CONTRIBUTING.md:22) e do [índice](/Users/x86/git-projects/engrama/.engrama/index.md:29) fala em “CI vinculante / bloqueia o PR”. O que o código prova é mais estreito: o [workflow](/Users/x86/git-projects/engrama/.github/workflows/ci.yml:54) faz o `test` falhar em `pull_request` no `ubuntu-latest`. Isso só vira bloqueio de merge se o job continuar `required check` na branch protection, que é estado externo ao repo. O próprio [ADR 0006](/Users/x86/git-projects/engrama/.engrama/memory/decisions/0006-governanca-nao-se-autoaprova.md:44) trata essa nuance com honestidade; o 0014 deveria espelhar a mesma borda.

- `Ressalva 2: a trilha probatória do claim repo-central-only está incompleta no ADR.` O desenho em si está bom: o [manifest](/Users/x86/git-projects/engrama/.engrama/release-surface.manifest:6) não inclui `bin/release-gate.sh`, e os testes [RS1–RS4](/Users/x86/git-projects/engrama/tests/contract/release-surface.test.sh:74) sustentam que o gate e o manifest não vazam para o template/adotante. Mas o `source_refs` do [ADR 0014](/Users/x86/git-projects/engrama/.engrama/memory/decisions/0014-gate-de-release-repo-central.md:6) não cita `tests/contract/release-surface.test.sh`, que é justamente a prova versionada dessa promessa. Para memória institucional, eu registraria essa prova explícita.

- `Ressalva 3: falta registrar duas obrigações operacionais.` A primeira é “mudou a superfície distribuível, mantenha `.engrama/release-surface.manifest` em sincronia”; hoje isso existe de fato via [RS1](/Users/x86/git-projects/engrama/tests/contract/release-surface.test.sh:79), mas não está dito no ADR. A segunda é que a receita documental para recalcular hash ficou estreita demais: [CONTRIBUTING](/Users/x86/git-projects/engrama/CONTRIBUTING.md:22) e `.engrama/evidence/qa/release-waivers.md` fixam `origin/main`, enquanto a CI usa a base real do PR no [workflow](/Users/x86/git-projects/engrama/.github/workflows/ci.yml:48) e o script exige/reflete isso em [release-gate.sh](/Users/x86/git-projects/engrama/bin/release-gate.sh:273). Eu escreveria `origin/<base>`.

**O Que Confirmo**

- `reconcilia: ADD` no 0014 me parece correto. Ele adiciona um gate novo; não revisa a semântica do 0011, só reaproveita o helper.
- O claim de backward-compat do hasher está aceitável se lido com precisão: o caminho default volta ao legado por construção em [engrama-diff-hash.sh](/Users/x86/git-projects/engrama/.engrama/engine/scripts/engrama-diff-hash.sh:242), e `D10`/`D11` em [diffbind.test.sh](/Users/x86/git-projects/engrama/tests/gate/diffbind.test.sh:196) servem como guarda de regressão.
- O acoplamento `VERSION ⇄ CHANGELOG` está mesmo root-only no comportamento real: a checagem mora só em [bin/release-gate.sh](/Users/x86/git-projects/engrama/bin/release-gate.sh:305) e não foi empurrada para o tooling sincronizado do adotante.

**Veredito**

`ressalvas`

O desenho técnico do release-gate está coerente com 0006/0011/0013 e o comportamento real sustenta o núcleo da decisão. Eu não vejo gatilho para `discordo` material. Mas, antes do commit de governança, eu baixaria as claims de “CI vinculante / bloqueia o PR” para a formulação honesta “derruba o job `test`; bloqueia merge se `test` for required-check”, e completaria a memória com a prova RS1–RS4 + a obrigação de manter o manifest em sincronia.
