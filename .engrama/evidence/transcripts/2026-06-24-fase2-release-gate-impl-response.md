---
codex-session: 019efa34-75d8-7eb0-9d0a-3272ebfd5cd8
codex-session-source: stream
model: unknown
sandbox: workspace-write
label: fase2-release-gate-impl
---

Vou abrir o gate obrigatório do repositório na ordem prescrita e extrair o estado factual antes de tocar no código. Depois disso, faço a crítica técnica da ordem e, se não houver objeção material, sigo para a implementação e validação completa.
Papel: Executor Crítico. Alçada: escrever código da fatia sob a ordem recebida, sem mexer em governança nem em git do repo real; objeção material escalaria à Autoridade via Orquestrador. Estado factual no topo do `log.md`: fatia 1 do bridge-hardening já concluída na branch `feat/disciplina-de-release-0.2.0`, e o próximo passo seguro aprovado é implementar a fatia 2 do `release-gate` repo-central-only; nada novo depende de aprovação da Autoridade nesta execução.

Agora vou ler a spec fechada da fatia 2 e abrir os pontos de impacto no código atual para validar se a generalização do hasher consegue preservar o caminho default bit a bit.
A ordem está coerente com a spec fechada e não vejo gatilho de discordância material. O ponto crítico continua sendo o hasher: vou estruturar a mudança em flags opt-in e validar contra a suíte inteira para garantir que o caminho atual do critique-gate permaneça intacto.
Encontrei um detalhe sem impacto na ordem: a suite de lint vive em `tests/contract/lint.test.sh`, não em `tests/gate`. Vou abrir as suites ligadas ao hasher/CI e a árvore do template para fechar o manifest sem depender de `classify()`.
A superfície distribuída real é maior do que o `rg --files template` mostrou, porque ele não lista dotfiles por padrão. Vou usar `find` agora para capturar o artefato completo instalado pelo template e fechar o contrato do manifest contra esse estado real.
O ponto mais delicado agora é o parser de `git diff --raw -z` para rename/delete. Vou validar o formato real num repo temporário antes de escrever a lógica do filtro, para não inventar parsing em cima de memória.
Vou entrar na fase de edição. Primeiro bloco: manifest root-only, waiver file e generalização opt-in do `engrama-diff-hash.sh`; depois encaixo `bin/release-gate.sh`, CI e a malha de testes/contratos.
O primeiro patch entrou, mas vou revisar o `engrama-diff-hash.sh` imediatamente: o parser de regras ficou sensível e eu quero corrigir qualquer aresta antes de plugar o gate novo em cima dele.
Vou aplicar o bloco principal agora: `bin/release-gate.sh`, a nova suíte de gate/contrato e os ajustes mínimos em CI/bootstrap/diffbind para provar a retrocompatibilidade do hasher e o boundary root-only.
Achei dois problemas de teste antes de validar: o contrato da superfície ainda precisa normalizar os paths extraídos do `sync-template.sh`, e o caso de waiver estava calculando o hash antes do payload existir em `HEAD`. Vou corrigir isso agora antes de rodar a suíte.
Os arquivos principais já estão no lugar. Vou passar primeiro por `bash -n` nos scripts tocados para pegar erro estrutural barato antes da suíte completa.
O contrato da superfície falhou por um detalhe de portabilidade do parser (`awk`), não pela regra em si. Vou trocar essa extração por shell/sed portável enquanto os outros testes terminam, porque isso não muda o desenho do gate.
A malha nova já está verde isoladamente. Vou rodar agora as validações de aceitação completas: suíte inteira, `shellcheck` e `lint`, para pegar qualquer regressão fora da trilha do release-gate.
Os três gates pesados estão rodando em paralelo agora. Se aparecer algo, a prioridade é corrigir primeiro `shellcheck` e `lint`, porque eles tendem a expor pequenos desvios mecânicos antes de qualquer ajuste maior.
O único ruído até aqui veio do `shellcheck`: um falso-positivo de regex literal no teste de superfície. Vou anotá-lo de forma explícita no próprio teste e reexecutar o lint mecânico.
A única regressão real da suíte completa é um drift mecânico já esperado: a cópia do `engrama-diff-hash.sh` no `template/` ficou para trás. Vou sincronizar o template com o `bin/sync-template.sh` e rerodar os gates finais.
O drift foi corrigido via `sync-template.sh`. Estou rerodando o trio final (`tests/run.sh`, `shellcheck`, `lint`) para fechar a evidência de que a mudança nova e o contrato antigo ficaram verdes juntos.
A suíte completa já fechou verde. Vou só gerar uma reprodução isolada do caso novo mais sensível (`waiver` stale) para deixar a evidência explícita além do runner agregado.
O runner agregado já provou o caso `waiver stale`, mas vou refazer essa reprodução em um repo temporário com um comando mais simples, sem heredoc, para não depender do shell interativo.
1. **Leitura da ordem**  
Implementei a fatia 2 do `release-gate` repo-central-only conforme a spec fechada em `.engrama/evidence/transcripts/2026-06-24-fase2-release-gate-design-response.md`: manifest explícito root-only, generalização opt-in do hasher, [bin/release-gate.sh](/Users/x86/git-projects/engrama/bin/release-gate.sh), step novo em [ci.yml](/Users/x86/git-projects/engrama/.github/workflows/ci.yml), testes não-vácuos e sem bump de `VERSION`/`CHANGELOG.md`.

2. **Crítica técnica**  
O risco material real era quebrar o caminho atual do `critique-gate` ao mexer no [engrama-diff-hash.sh](/Users/x86/git-projects/engrama/.engrama/engine/scripts/engrama-diff-hash.sh). Tratei isso com flags opt-in (`--manifest`, `--include`, `--exclude`) e preservei o default legado intacto; a única correção de execução fora do miolo foi sincronizar a cópia do hasher no `template/` para manter o contrato pré-existente do `sync.test`.

3. **Veredito sobre a ordem**  
`ajuste-menor`

4. **Execução**  
Adicionei o manifest root-only [release-surface.manifest](/Users/x86/git-projects/engrama/.engrama/release-surface.manifest) e o ledger de escape [release-waivers.md](/Users/x86/git-projects/engrama/.engrama/evidence/qa/release-waivers.md). Generalizei [engrama-diff-hash.sh](/Users/x86/git-projects/engrama/.engrama/engine/scripts/engrama-diff-hash.sh) sem mudar o default, criei [bin/release-gate.sh](/Users/x86/git-projects/engrama/bin/release-gate.sh), pluguei o gate no job `test` da CI, sincronizei [template/.engrama/engine/scripts/engrama-diff-hash.sh](/Users/x86/git-projects/engrama/template/.engrama/engine/scripts/engrama-diff-hash.sh), criei [tests/gate/release-gate.test.sh](/Users/x86/git-projects/engrama/tests/gate/release-gate.test.sh) e [tests/contract/release-surface.test.sh](/Users/x86/git-projects/engrama/tests/contract/release-surface.test.sh), e estendi [diffbind.test.sh](/Users/x86/git-projects/engrama/tests/gate/diffbind.test.sh) e [bootstrap.test.sh](/Users/x86/git-projects/engrama/tests/contract/bootstrap.test.sh).

5. **Evidências**  
`bash tests/run.sh` verde por completo, incluindo `release-gate.test` 11/11, `release-surface.test` 4/4, `sync.test` 21/21 e os casos pré-existentes de `critique-gate` intactos. `shellcheck -S info bin/*.sh .engrama/engine/scripts/*.sh .engrama/engine/githooks/pre-commit tests/run.sh tests/gate/*.test.sh tests/contract/*.test.sh` limpo. `bash .engrama/engine/scripts/lint.sh` exit 0. A retrocompatibilidade bit a bit do hasher ficou provada nos casos `D10` e `D11` de [tests/gate/diffbind.test.sh](/Users/x86/git-projects/engrama/tests/gate/diffbind.test.sh): `--cached` e `--range` batem exatamente o pipeline legado do `critique-gate`. Reproduzi isoladamente o caso novo de waiver stale em repo temporário: `rc=2` com mensagem de policy e hash atual divergente.

6. **Pendências e bloqueios**  
Sem bloqueio técnico nesta fatia. Ficou fora de escopo, como pedido: ADR/governança, bump `0.2.0` e qualquer mudança de produto do adotante. Próximo passo seguro: auditoria do Orquestrador, ADR 0014/ledger e commit da fatia 2.
